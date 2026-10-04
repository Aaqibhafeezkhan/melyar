use anyhow::Result;
use serde_json::Value;
use crate::ffi::CxxTrackMetadata;

pub fn parse_search_results(json: &Value) -> Result<Vec<CxxTrackMetadata>> {
    let mut tracks = Vec::new();

    let sections = json
        .pointer("/contents/tabbedSearchResultsRenderer/tabs/0/tabRenderer/content/sectionListRenderer/contents")
        .or_else(|| json.pointer("/contents/sectionListRenderer/contents"));

    if let Some(sections_array) = sections.and_then(|v| v.as_array()) {
        for section in sections_array {
            if let Some(items) = section
                .pointer("/musicShelfRenderer/contents")
                .or_else(|| section.pointer("/musicCardShelfRenderer/contents"))
                .and_then(|v| v.as_array())
            {
                for item in items {
                    if let Some(track) = parse_list_item(item) {
                        tracks.push(track);
                    }
                }
            }
        }
    }

    if tracks.is_empty() {
        find_list_items(json, &mut tracks);
    }

    Ok(tracks)
}

fn parse_list_item(item: &Value) -> Option<CxxTrackMetadata> {
    let renderer = item.get("musicResponsiveListItemRenderer")?;

    let video_id = renderer
        .pointer("/playlistItemData/videoId")
        .or_else(|| renderer.pointer("/doubleTapCommand/watchEndpoint/videoId"))
        .or_else(|| renderer.pointer("/overlay/musicItemThumbnailOverlayRenderer/content/musicPlayButtonRenderer/playNavigationEndpoint/watchEndpoint/videoId"))
        .and_then(|v| v.as_str())?
        .to_string();

    let flex_columns = renderer.get("flexColumns")?.as_array()?;

    let title = flex_columns
        .get(0)?
        .pointer("/musicResponsiveListItemFlexColumnRenderer/text/runs/0/text")
        .and_then(|v| v.as_str())
        .unwrap_or("Unknown Title")
        .to_string();

    let mut artist = "Unknown Artist".to_string();
    let mut album = String::new();
    let mut duration_secs = 0.0;

    if let Some(runs) = flex_columns
        .get(1)
        .and_then(|col| col.pointer("/musicResponsiveListItemFlexColumnRenderer/text/runs"))
        .and_then(|v| v.as_array())
    {
        let mut text_parts = Vec::new();
        for r in runs {
            if let Some(t) = r.get("text").and_then(|v| v.as_str()) {
                let trimmed = t.trim();
                if trimmed != "•" && !trimmed.is_empty() {
                    text_parts.push(trimmed.to_string());
                }
            }
        }

        if !text_parts.is_empty() {
            artist = text_parts[0].clone();
        }
        if text_parts.len() > 1 {
            let last = &text_parts[text_parts.len() - 1];
            if last.contains(':') {
                duration_secs = parse_duration_str(last);
                if text_parts.len() > 2 {
                    album = text_parts[1].clone();
                }
            } else {
                album = text_parts[1].clone();
            }
        }
    }

    let thumbnail_url = renderer
        .pointer("/thumbnail/musicThumbnailRenderer/thumbnail/thumbnails")
        .and_then(|v| v.as_array())
        .and_then(|arr| arr.last())
        .and_then(|t| t.get("url"))
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();

    Some(CxxTrackMetadata {
        id: video_id,
        title,
        artist,
        album,
        duration_secs,
        thumbnail_url,
        lyrics: String::new(),
    })
}

fn find_list_items(val: &Value, tracks: &mut Vec<CxxTrackMetadata>) {
    if let Value::Object(map) = val {
        if map.contains_key("musicResponsiveListItemRenderer") {
            if let Some(track) = parse_list_item(val) {
                if !tracks.iter().any(|t| t.id == track.id) {
                    tracks.push(track);
                }
            }
        } else {
            for v in map.values() {
                find_list_items(v, tracks);
            }
        }
    } else if let Value::Array(arr) = val {
        for v in arr {
            find_list_items(v, tracks);
        }
    }
}

pub fn parse_duration_str(s: &str) -> f64 {
    let parts: Vec<&str> = s.split(':').collect();
    if parts.len() == 2 {
        let m: f64 = parts[0].parse().unwrap_or(0.0);
        let s: f64 = parts[1].parse().unwrap_or(0.0);
        m * 60.0 + s
    } else if parts.len() == 3 {
        let h: f64 = parts[0].parse().unwrap_or(0.0);
        let m: f64 = parts[1].parse().unwrap_or(0.0);
        let s: f64 = parts[2].parse().unwrap_or(0.0);
        h * 3600.0 + m * 60.0 + s
    } else {
        0.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_duration_str() {
        assert_eq!(parse_duration_str("0:45"), 45.0);
        assert_eq!(parse_duration_str("3:24"), 204.0);
        assert_eq!(parse_duration_str("1:02:15"), 3735.0);
        assert_eq!(parse_duration_str("invalid"), 0.0);
    }

    #[test]
    fn test_parse_search_results_empty() {
        let empty_json = serde_json::json!({});
        let res = parse_search_results(&empty_json).unwrap();
        assert!(res.is_empty());
    }

    #[test]
    fn test_parse_search_results_with_mock() {
        let mock_json = serde_json::json!({
            "contents": {
                "sectionListRenderer": {
                    "contents": [{
                        "musicShelfRenderer": {
                            "contents": [{
                                "musicResponsiveListItemRenderer": {
                                    "playlistItemData": { "videoId": "abc12345" },
                                    "flexColumns": [
                                        {
                                            "musicResponsiveListItemFlexColumnRenderer": {
                                                "text": { "runs": [{ "text": "Test Song" }] }
                                            }
                                        },
                                        {
                                            "musicResponsiveListItemFlexColumnRenderer": {
                                                "text": { "runs": [
                                                    { "text": "Test Artist" },
                                                    { "text": " • " },
                                                    { "text": "Test Album" },
                                                    { "text": " • " },
                                                    { "text": "3:30" }
                                                ] }
                                            }
                                        }
                                    ],
                                    "thumbnail": {
                                        "musicThumbnailRenderer": {
                                            "thumbnail": {
                                                "thumbnails": [{ "url": "https://example.com/thumb.jpg" }]
                                            }
                                        }
                                    }
                                }
                            }]
                        }
                    }]
                }
            }
        });

        let results = parse_search_results(&mock_json).unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].id, "abc12345");
        assert_eq!(results[0].title, "Test Song");
        assert_eq!(results[0].artist, "Test Artist");
        assert_eq!(results[0].album, "Test Album");
        assert_eq!(results[0].duration_secs, 210.0);
        assert_eq!(results[0].thumbnail_url, "https://example.com/thumb.jpg");
    }
}
