use anyhow::{anyhow, Result};
use reqwest::Client;
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct LrclibResponse {
    pub id: Option<i64>,
    pub name: Option<String>,
    pub track_name: Option<String>,
    pub artist_name: Option<String>,
    pub album_name: Option<String>,
    pub duration: Option<f64>,
    #[serde(rename = "plainLyrics")]
    pub plain_lyrics: Option<String>,
    #[serde(rename = "syncedLyrics")]
    pub synced_lyrics: Option<String>,
}

pub async fn fetch_lyrics(
    client: &Client,
    track_title: &str,
    artist: &str,
    duration_secs: Option<f64>,
) -> Result<String> {
    // 1. Try direct exact match with duration
    let mut get_url = format!(
        "https://lrclib.net/api/get?track_name={}&artist_name={}",
        urlencoding::encode(track_title),
        urlencoding::encode(artist)
    );
    if let Some(dur) = duration_secs {
        if dur > 0.0 {
            get_url.push_str(&format!("&duration={}", dur.round() as i64));
        }
    }

    if let Ok(resp) = client.get(&get_url).send().await {
        if resp.status().is_success() {
            if let Ok(data) = resp.json::<LrclibResponse>().await {
                if let Some(synced) = data.synced_lyrics {
                    if !synced.trim().is_empty() {
                        return Ok(synced);
                    }
                }
                if let Some(plain) = data.plain_lyrics {
                    if !plain.trim().is_empty() {
                        return Ok(plain);
                    }
                }
            }
        }
    }

    // 2. Fallback search endpoint
    let query = format!("{} {}", track_title, artist);
    let search_url = format!(
        "https://lrclib.net/api/search?q={}",
        urlencoding::encode(&query)
    );

    let resp = client.get(&search_url).send().await?;
    if resp.status().is_success() {
        let items: Vec<LrclibResponse> = resp.json().await.unwrap_or_default();
        for item in items {
            if let Some(synced) = item.synced_lyrics {
                if !synced.trim().is_empty() {
                    return Ok(synced);
                }
            }
            if let Some(plain) = item.plain_lyrics {
                if !plain.trim().is_empty() {
                    return Ok(plain);
                }
            }
        }
    }

    Err(anyhow!("No lyrics found for track"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_lrclib_live() {
        let client = reqwest::Client::new();
        let res = fetch_lyrics(&client, "Let It Happen", "Tame Impala", Some(468.0)).await;
        match res {
            Ok(lrc) => println!("LYRICS OK len={} preview={:?}", lrc.len(), &lrc[..lrc.len().min(80)]),
            Err(e) => println!("LYRICS ERR: {e:#}"),
        }
    }
}
