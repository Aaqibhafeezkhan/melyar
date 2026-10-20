use anyhow::{anyhow, Context, Result};
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use reqwest::{header, Client};
use serde_json::{json, Value};
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

use super::cipher::CipherSolver;
use super::parser::parse_search_results;
use crate::ffi::CxxTrackMetadata;

const INNERTUBE_API_KEY: &str = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30";
const SEARCH_URL: &str = "https://music.youtube.com/youtubei/v1/search";
const PLAYER_URL: &str = "https://music.youtube.com/youtubei/v1/player";
const USER_AGENT: &str = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0";

/// Resolved video: metadata + direct audio stream url (single yt-dlp call).
#[derive(Clone, Debug, Default)]
pub struct ResolvedVideo {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration: f64,
    pub thumbnail: String,
    pub stream_url: String,
}

impl ResolvedVideo {
    pub fn to_meta(&self) -> CxxTrackMetadata {
        CxxTrackMetadata {
            id: self.id.clone(),
            title: self.title.clone(),
            artist: self.artist.clone(),
            album: self.album.clone(),
            duration_secs: self.duration,
            thumbnail_url: self.thumbnail.clone(),
            lyrics: String::new(),
        }
    }
}

static YTDLP_PATH: Lazy<Option<PathBuf>> = Lazy::new(|| {
    let names = ["yt-dlp", "yt-dlp_linux", "youtube-dl"];
    // 1. PATH
    for name in names {
        if let Ok(out) = Command::new("which").arg(name).output() {
            if out.status.success() {
                let p = String::from_utf8_lossy(&out.stdout).trim().to_string();
                if !p.is_empty() {
                    return Some(PathBuf::from(p));
                }
            }
        }
    }
    // 2. Common locations
    let home = std::env::var("HOME").unwrap_or_default();
    let mut candidates = vec![
        PathBuf::from("/usr/bin/yt-dlp"),
        PathBuf::from("/usr/local/bin/yt-dlp"),
        PathBuf::from("/opt/yt-dlp/yt-dlp"),
        PathBuf::from(home.clone()).join(".local/bin/yt-dlp"),
        PathBuf::from(home).join("bin/yt-dlp"),
    ];
    if let Ok(home) = std::env::var("HOME") {
        for py in ["3.14", "3.13", "3.12", "3.11", "3.10"] {
            candidates.push(
                PathBuf::from(&home)
                    .join(format!(".local/lib/python{}/site-packages/bin/yt-dlp", py)),
            );
        }
    }
    candidates.into_iter().find(|p| p.exists() && p.is_file())
});

fn yt_dlp_available() -> bool {
    YTDLP_PATH.is_some()
}

fn yt_dlp_command() -> Command {
    let mut cmd = Command::new(YTDLP_PATH.as_ref().unwrap());
    cmd.arg("--no-warnings")
        .arg("--no-playlist")
        .arg("--no-progress")
        .arg("--ignore-config");
    cmd
}

/// Run yt-dlp -J (single JSON) and parse metadata + best audio stream url.
fn yt_dlp_json_blocking(video_id: &str) -> Result<ResolvedVideo> {
    if !yt_dlp_available() {
        return Err(anyhow!("yt-dlp binary not found"));
    }
    let watch_url = format!("https://www.youtube.com/watch?v={}", video_id);
    let output = yt_dlp_command()
        .arg("-J")
        .arg(&watch_url)
        .output()
        .context("yt-dlp -J failed to spawn")?;

    if !output.status.success() {
        let err = String::from_utf8_lossy(&output.stderr);
        return Err(anyhow!(
            "yt-dlp -J failed for {}: {}",
            video_id,
            err.lines().next().unwrap_or("")
        ));
    }

    let data: Value = serde_json::from_slice(&output.stdout).context("yt-dlp -J invalid JSON")?;
    parse_ytdlp_json(&data, video_id)
}

fn parse_ytdlp_json(data: &Value, video_id: &str) -> Result<ResolvedVideo> {
    let title = data
        .get("title")
        .and_then(|v| v.as_str())
        .unwrap_or("Bilinmeyen Parça")
        .to_string();
    let artist = data
        .get("artist")
        .or_else(|| data.get("uploader"))
        .or_else(|| data.get("channel"))
        .and_then(|v| v.as_str())
        .unwrap_or("Bilinmeyen Sanatçı")
        .to_string();
    let album = data
        .get("album")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let duration = data.get("duration").and_then(|v| v.as_f64()).unwrap_or(0.0);
    let thumbnail = data
        .get("thumbnail")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| format!("https://i.ytimg.com/vi/{}/hqdefault.jpg", video_id));

    // Pick the best audio-only https stream (prefer mp4/aac itag 140, else highest abr)
    let mut best: Option<(i64, String)> = None;
    if let Some(formats) = data.get("formats").and_then(|v| v.as_array()) {
        for f in formats {
            let acodec = f.get("acodec").and_then(|v| v.as_str()).unwrap_or("none");
            let vcodec = f.get("vcodec").and_then(|v| v.as_str()).unwrap_or("none");
            if acodec == "none" || vcodec != "none" {
                continue;
            }
            let Some(url) = f.get("url").and_then(|v| v.as_str()) else {
                continue;
            };
            let protocol = f.get("protocol").and_then(|v| v.as_str()).unwrap_or("");
            if protocol.contains("m3u8") {
                // HLS works in mpv but prefer progressive https
                continue;
            }
            let abr = f.get("abr").and_then(|v| v.as_f64()).unwrap_or(0.0) as i64;
            let is_mp4a = acodec.starts_with("mp4a");
            let score = abr + if is_mp4a { 1000 } else { 0 };
            if best.as_ref().is_none_or(|(s, _)| score > *s) {
                best = Some((score, url.to_string()));
            }
        }
    }

    let stream_url = best.map(|(_, u)| u).or_else(|| {
        // Fallback: any format url (even manifests — mpv handles them)
        data.get("formats")
            .and_then(|v| v.as_array())
            .and_then(|formats| {
                formats
                    .iter()
                    .filter_map(|f| f.get("url").and_then(|u| u.as_str()))
                    .next()
                    .map(|s| s.to_string())
            })
    });

    match stream_url {
        Some(url) => Ok(ResolvedVideo {
            id: video_id.to_string(),
            title,
            artist,
            album,
            duration,
            thumbnail,
            stream_url: url,
        }),
        None => Err(anyhow!(
            "no usable audio stream in yt-dlp output for {}",
            video_id
        )),
    }
}

pub struct InnerTubeClient {
    http: Client,
    cipher: CipherSolver,
}

impl InnerTubeClient {
    pub fn new() -> Result<Self> {
        let mut headers = header::HeaderMap::new();
        headers.insert(
            header::USER_AGENT,
            header::HeaderValue::from_static(USER_AGENT),
        );
        headers.insert(
            header::ORIGIN,
            header::HeaderValue::from_static("https://music.youtube.com"),
        );
        headers.insert(
            header::REFERER,
            header::HeaderValue::from_static("https://music.youtube.com/"),
        );
        headers.insert(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json"),
        );

        let http = Client::builder()
            .default_headers(headers)
            .http2_prior_knowledge()
            .pool_idle_timeout(Duration::from_secs(90))
            .pool_max_idle_per_host(10)
            .timeout(Duration::from_secs(15))
            .gzip(true)
            .build()
            .context("Failed to build HTTP client")?;

        Ok(Self {
            http,
            cipher: CipherSolver::new(),
        })
    }

    /// Blocking metadata+url resolve for calls coming from Qt worker threads.
    pub fn resolve_video_blocking(&self, video_id: &str) -> Result<ResolvedVideo> {
        yt_dlp_json_blocking(video_id)
    }

    /// Search tracks on YouTube Music (WEB_REMIX client)
    pub async fn search_tracks(&self, query: &str) -> Result<Vec<CxxTrackMetadata>> {
        let url = format!("{SEARCH_URL}?key={INNERTUBE_API_KEY}");
        let payload = json!({
            "context": {
                "client": {
                    "clientName": "WEB_REMIX",
                    "clientVersion": "1.20240403.01.00",
                    "hl": "en",
                    "gl": "US"
                }
            },
            "query": query,
            "params": "Eg-KAQwIARAAGAAgACgAMABqChAKEAMQBBAKEAU%3D"
        });

        let resp = self.http.post(&url).json(&payload).send().await?;
        if !resp.status().is_success() {
            return Err(anyhow!(
                "Search request failed with status {}",
                resp.status()
            ));
        }

        let json_data: Value = resp.json().await?;
        parse_search_results(&json_data)
    }

    /// Resolve direct audio stream URL for a given track/video id.
    /// Primary: yt-dlp (handles PO tokens + deciphering).
    /// Fallback: innertube clients + public APIs.
    pub async fn get_stream_url(&self, video_id: &str) -> Result<String> {
        // 1. yt-dlp (metadata json gives us both url and meta in one shot)
        if yt_dlp_available() {
            let vid = video_id.to_string();
            let resolved = tokio::task::spawn_blocking(move || yt_dlp_json_blocking(&vid)).await;
            if let Ok(Ok(res)) = resolved {
                if !res.stream_url.is_empty() {
                    return Ok(res.stream_url);
                }
            }
        }

        // 2. YouTube Music WEB_REMIX player endpoint
        let url = format!("{PLAYER_URL}?key={INNERTUBE_API_KEY}");
        let payload = json!({
            "context": {
                "client": {
                    "clientName": "WEB_REMIX",
                    "clientVersion": "1.20240403.01.00",
                    "hl": "en",
                    "gl": "US"
                }
            },
            "videoId": video_id
        });

        if let Ok(resp) = self.http.post(&url).json(&payload).send().await {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<Value>().await {
                    if let Some(stream_url) = self.extract_best_audio_stream(&data).await {
                        return Ok(stream_url);
                    }
                }
            }
        }

        // 3. Android client player endpoint fallback
        let android_payload = json!({
            "context": {
                "client": {
                    "clientName": "ANDROID",
                    "clientVersion": "21.26.364",
                    "androidSdkVersion": 30,
                    "hl": "en",
                    "gl": "US"
                }
            },
            "videoId": video_id
        });

        let android_url =
            format!("https://www.youtube.com/youtubei/v1/player?key={INNERTUBE_API_KEY}");
        if let Ok(resp) = self
            .http
            .post(&android_url)
            .header(
                header::USER_AGENT,
                "com.google.android.youtube/21.26.364 (Linux; U; Android 11) gzip",
            )
            .json(&android_payload)
            .send()
            .await
        {
            if resp.status().is_success() {
                if let Ok(data) = resp.json::<Value>().await {
                    if let Some(stream_url) = self.extract_best_audio_stream(&data).await {
                        return Ok(stream_url);
                    }
                }
            }
        }

        // 4. Fallback: Piped / Invidious audio stream resolver
        let fallback_apis = [
            format!("https://pipedapi.kavin.rocks/streams/{video_id}"),
            format!("https://api.piped.privacydev.net/streams/{video_id}"),
            format!("https://invidious.asir.dev/api/v1/videos/{video_id}"),
        ];

        for fallback in fallback_apis {
            if let Ok(resp) = self
                .http
                .get(&fallback)
                .timeout(Duration::from_secs(5))
                .send()
                .await
            {
                if resp.status().is_success() {
                    if let Ok(data) = resp.json::<Value>().await {
                        if let Some(audio_streams) =
                            data.get("audioStreams").and_then(|v| v.as_array())
                        {
                            for s in audio_streams {
                                if let Some(stream_url) = s.get("url").and_then(|u| u.as_str()) {
                                    return Ok(stream_url.to_string());
                                }
                            }
                        }
                        if let Some(adaptive) =
                            data.get("adaptiveFormats").and_then(|v| v.as_array())
                        {
                            for f in adaptive {
                                if f.get("type")
                                    .and_then(|t| t.as_str())
                                    .is_some_and(|t| t.starts_with("audio"))
                                {
                                    if let Some(stream_url) = f.get("url").and_then(|u| u.as_str())
                                    {
                                        return Ok(stream_url.to_string());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Err(anyhow!(
            "Failed to extract audio stream for video {video_id}"
        ))
    }

    async fn extract_best_audio_stream(&self, player_json: &Value) -> Option<String> {
        let streaming_data = player_json.get("streamingData")?;

        // 1. Check adaptive formats first (Opus itag 251 / AAC audio streams)
        if let Some(formats) = streaming_data
            .get("adaptiveFormats")
            .and_then(|v| v.as_array())
        {
            let mut audio_formats: Vec<&Value> = formats
                .iter()
                .filter(|f| {
                    f.get("mimeType")
                        .and_then(|m| m.as_str())
                        .is_some_and(|m| m.starts_with("audio/"))
                })
                .collect();

            audio_formats.sort_by(|a, b| {
                let itag_a = a.get("itag").and_then(|v| v.as_i64()).unwrap_or(0);
                let itag_b = b.get("itag").and_then(|v| v.as_i64()).unwrap_or(0);

                if itag_a == 251 {
                    return std::cmp::Ordering::Less;
                }
                if itag_b == 251 {
                    return std::cmp::Ordering::Greater;
                }

                let br_a = a.get("bitrate").and_then(|v| v.as_i64()).unwrap_or(0);
                let br_b = b.get("bitrate").and_then(|v| v.as_i64()).unwrap_or(0);
                br_b.cmp(&br_a)
            });

            for fmt in audio_formats {
                if let Some(direct_url) = fmt.get("url").and_then(|v| v.as_str()) {
                    return Some(direct_url.to_string());
                }

                let cipher_field = fmt
                    .get("signatureCipher")
                    .or_else(|| fmt.get("cipher"))
                    .and_then(|v| v.as_str());

                if let Some(cipher_str) = cipher_field {
                    if let Ok(solved) = self.cipher.solve(cipher_str, None) {
                        return Some(solved);
                    }
                }
            }
        }

        // 2. Check progressive formats (contains audio+video, libmpv plays audio-only via vo=null)
        if let Some(formats) = streaming_data.get("formats").and_then(|v| v.as_array()) {
            for fmt in formats {
                if let Some(direct_url) = fmt.get("url").and_then(|v| v.as_str()) {
                    return Some(direct_url.to_string());
                }

                let cipher_field = fmt
                    .get("signatureCipher")
                    .or_else(|| fmt.get("cipher"))
                    .and_then(|v| v.as_str());

                if let Some(cipher_str) = cipher_field {
                    if let Ok(solved) = self.cipher.solve(cipher_str, None) {
                        return Some(solved);
                    }
                }
            }
        }

        None
    }
}

/// Serialize yt-dlp json calls behind a mutex to avoid hammering with parallel lookups.
static YTDLP_LOCK: Lazy<Mutex<()>> = Lazy::new(|| Mutex::new(()));

pub fn with_ytdlp_lock<T>(f: impl FnOnce() -> T) -> T {
    let _guard = YTDLP_LOCK.lock();
    f()
}
