use anyhow::{anyhow, Context, Result};
use reqwest::{header, Client};
use serde_json::{json, Value};
use std::time::Duration;

use super::cipher::CipherSolver;
use super::parser::parse_search_results;
use crate::ffi::CxxTrackMetadata;

const INNERTUBE_API_KEY: &str = "AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30";
const SEARCH_URL: &str = "https://music.youtube.com/youtubei/v1/search";
const PLAYER_URL: &str = "https://music.youtube.com/youtubei/v1/player";
const USER_AGENT: &str = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0";

pub struct InnerTubeClient {
    http: Client,
    cipher: CipherSolver,
}

impl InnerTubeClient {
    pub fn new() -> Result<Self> {
        let mut headers = header::HeaderMap::new();
        headers.insert(header::USER_AGENT, header::HeaderValue::from_static(USER_AGENT));
        headers.insert(header::ORIGIN, header::HeaderValue::from_static("https://music.youtube.com"));
        headers.insert(header::REFERER, header::HeaderValue::from_static("https://music.youtube.com/"));
        headers.insert(header::CONTENT_TYPE, header::HeaderValue::from_static("application/json"));

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

    /// Search tracks on YouTube Music (WEB_REMIX client)
    pub async fn search_tracks(&self, query: &str) -> Result<Vec<CxxTrackMetadata>> {
        let url = format!("{SEARCH_URL}?key={INNERTUBE_API_KEY}");
        let payload = json!({
            "context": {
                "client": {
                    "clientName": "WEB_REMIX",
                    "clientVersion": "1.20240101.01.00",
                    "hl": "en",
                    "gl": "US"
                }
            },
            "query": query,
            "params": "Eg-KAQwIARAAGAAgACgAMABqChAKEAMQBBAKEAU%3D"
        });

        let resp = self.http.post(&url).json(&payload).send().await?;
        if !resp.status().is_success() {
            return Err(anyhow!("Search request failed with status {}", resp.status()));
        }

        let json_data: Value = resp.json().await?;
        parse_search_results(&json_data)
    }

    /// Resolve direct Opus/WebM audio stream URL for a given track/video ID
    pub async fn get_stream_url(&self, video_id: &str) -> Result<String> {
        // 1. YouTube Music WEB_REMIX player endpoint
        let url = format!("{PLAYER_URL}?key={INNERTUBE_API_KEY}");
        let payload = json!({
            "context": {
                "client": {
                    "clientName": "WEB_REMIX",
                    "clientVersion": "1.20240101.01.00",
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

        // 2. Android client player endpoint fallback
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

        let android_url = format!("https://www.youtube.com/youtubei/v1/player?key={INNERTUBE_API_KEY}");
        if let Ok(resp) = self.http.post(&android_url)
            .header(header::USER_AGENT, "com.google.android.youtube/21.26.364 (Linux; U; Android 11) gzip")
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

        // 3. Fallback: Invidious / Piped audio stream resolver
        let fallback_apis = [
            format!("https://pipedapi.kavin.rocks/streams/{video_id}"),
            format!("https://api.piped.privacydev.net/streams/{video_id}"),
            format!("https://invidious.asir.dev/api/v1/videos/{video_id}"),
        ];

        for fallback in fallback_apis {
            if let Ok(resp) = self.http.get(&fallback).timeout(Duration::from_secs(5)).send().await {
                if resp.status().is_success() {
                    if let Ok(data) = resp.json::<Value>().await {
                        if let Some(audio_streams) = data.get("audioStreams").and_then(|v| v.as_array()) {
                            for s in audio_streams {
                                if let Some(stream_url) = s.get("url").and_then(|u| u.as_str()) {
                                    return Ok(stream_url.to_string());
                                }
                            }
                        }
                        if let Some(adaptive) = data.get("adaptiveFormats").and_then(|v| v.as_array()) {
                            for f in adaptive {
                                if f.get("type").and_then(|t| t.as_str()).map_or(false, |t| t.starts_with("audio")) {
                                    if let Some(stream_url) = f.get("url").and_then(|u| u.as_str()) {
                                        return Ok(stream_url.to_string());
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Err(anyhow!("Failed to extract audio stream for video {video_id}"))
    }

    async fn extract_best_audio_stream(&self, player_json: &Value) -> Option<String> {
        let streaming_data = player_json.get("streamingData")?;

        // 1. Check adaptive formats first (Opus itag 251 / AAC audio streams)
        if let Some(formats) = streaming_data.get("adaptiveFormats").and_then(|v| v.as_array()) {
            let mut audio_formats: Vec<&Value> = formats
                .iter()
                .filter(|f| {
                    f.get("mimeType")
                        .and_then(|m| m.as_str())
                        .map_or(false, |m| m.starts_with("audio/"))
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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_search_live() {
        let client = InnerTubeClient::new().unwrap();
        let res = client.search_tracks("daft punk").await;
        println!("Search result: {:?}", res.as_ref().map(|v| v.len()));
        if let Ok(tracks) = res {
            println!("Tracks found: {}", tracks.len());
            for t in tracks.iter().take(3) {
                println!(" - {} by {} (id: {})", t.title, t.artist, t.id);
            }
            assert!(!tracks.is_empty());
        }
    }

    #[tokio::test]
    async fn test_stream_url_live() {
        let client = InnerTubeClient::new().unwrap();
        let stream_url = client.get_stream_url("khnokW3Mw24").await;
        println!("Stream URL result: {:?}", stream_url);
        assert!(stream_url.is_ok());
        let url = stream_url.unwrap();
        assert!(url.starts_with("http"));
        println!("Stream URL: {}", &url[..std::cmp::min(60, url.len())]);
    }
}
