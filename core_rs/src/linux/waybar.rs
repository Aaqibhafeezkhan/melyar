use parking_lot::RwLock;
use serde::Serialize;
use std::fs;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{UnixListener, UnixStream};
use tokio::runtime::Runtime;

use crate::ffi::CxxTrackMetadata;

#[derive(Serialize, Clone, Debug)]
pub struct WaybarPayload {
    pub text: String,
    pub alt: String,
    pub tooltip: String,
    pub class: String,
    pub percentage: u32,
}

pub trait WaybarCommandHandler: Send + Sync + 'static {
    fn on_toggle(&self);
    fn on_next(&self);
    fn on_prev(&self);
    fn on_stop(&self);
}

pub struct WaybarIpc {
    current_track: Arc<RwLock<Option<CxxTrackMetadata>>>,
    is_playing: Arc<AtomicBool>,
    current_pos: Arc<RwLock<f64>>,
    handler: Arc<dyn WaybarCommandHandler>,
    socket_path: PathBuf,
}

impl WaybarIpc {
    pub fn new(handler: Arc<dyn WaybarCommandHandler>, runtime: Arc<Runtime>) -> Self {
        let socket_path = Self::get_socket_path();
        let _ = fs::remove_file(&socket_path);

        let current_track = Arc::new(RwLock::new(None));
        let is_playing = Arc::new(AtomicBool::new(false));
        let current_pos = Arc::new(RwLock::new(0.0));

        let ipc = Self {
            current_track,
            is_playing,
            current_pos,
            handler,
            socket_path: socket_path.clone(),
        };

        let track_ref = ipc.current_track.clone();
        let playing_ref = ipc.is_playing.clone();
        let pos_ref = ipc.current_pos.clone();
        let handler_ref = ipc.handler.clone();

        runtime.spawn(async move {
            if let Ok(listener) = UnixListener::bind(&socket_path) {
                loop {
                    if let Ok((stream, _)) = listener.accept().await {
                        let t = track_ref.clone();
                        let p = playing_ref.clone();
                        let pos = pos_ref.clone();
                        let h = handler_ref.clone();

                        tokio::spawn(async move {
                            Self::handle_client(stream, t, p, pos, h).await;
                        });
                    }
                }
            }
        });

        ipc
    }

    fn get_socket_path() -> PathBuf {
        if let Ok(runtime_dir) = std::env::var("XDG_RUNTIME_DIR") {
            PathBuf::from(runtime_dir).join("melyar.sock")
        } else {
            PathBuf::from("/tmp/melyar.sock")
        }
    }

    pub fn update_track(&self, track: Option<CxxTrackMetadata>) {
        *self.current_track.write() = track;
    }

    pub fn update_playback_state(&self, is_playing: bool) {
        self.is_playing.store(is_playing, Ordering::Relaxed);
    }

    pub fn update_position(&self, position_secs: f64) {
        *self.current_pos.write() = position_secs;
    }

    async fn handle_client(
        mut stream: UnixStream,
        track_ref: Arc<RwLock<Option<CxxTrackMetadata>>>,
        playing_ref: Arc<AtomicBool>,
        pos_ref: Arc<RwLock<f64>>,
        handler: Arc<dyn WaybarCommandHandler>,
    ) {
        let mut buf = [0u8; 128];
        let bytes_read = stream.read(&mut buf).await.unwrap_or(0);

        if bytes_read > 0 {
            let cmd = String::from_utf8_lossy(&buf[..bytes_read]);
            let trimmed = cmd.trim().to_lowercase();
            match trimmed.as_str() {
                "toggle" | "play_pause" => handler.on_toggle(),
                "next" => handler.on_next(),
                "prev" | "previous" => handler.on_prev(),
                "stop" => handler.on_stop(),
                _ => {}
            }
        }

        // Snapshot state without holding RwLock guard across await
        let is_playing = playing_ref.load(Ordering::Relaxed);
        let maybe_track = track_ref.read().clone();
        let pos = *pos_ref.read();

        let payload = if let Some(ref track) = maybe_track {
            let percentage = if track.duration_secs > 0.0 {
                ((pos / track.duration_secs) * 100.0).clamp(0.0, 100.0) as u32
            } else {
                0
            };

            let dur_min = (track.duration_secs / 60.0).floor() as u32;
            let dur_sec = (track.duration_secs % 60.0).floor() as u32;
            let cur_min = (pos / 60.0).floor() as u32;
            let cur_sec = (pos % 60.0).floor() as u32;

            WaybarPayload {
                text: format!("{} - {}", track.artist, track.title),
                alt: if is_playing {
                    "Playing".into()
                } else {
                    "Paused".into()
                },
                tooltip: format!(
                    "<b>{}</b>\n{}\nAlbum: {}\n[{:02}:{:02} / {:02}:{:02}]",
                    track.title, track.artist, track.album, cur_min, cur_sec, dur_min, dur_sec
                ),
                class: if is_playing {
                    "playing".into()
                } else {
                    "paused".into()
                },
                percentage,
            }
        } else {
            WaybarPayload {
                text: "Melyar (Idle)".into(),
                alt: "Stopped".into(),
                tooltip: "No track loaded".into(),
                class: "stopped".into(),
                percentage: 0,
            }
        };

        if let Ok(json_str) = serde_json::to_string(&payload) {
            let mut out = json_str;
            out.push('\n');
            let _ = stream.write_all(out.as_bytes()).await;
        }
    }
}

impl Drop for WaybarIpc {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.socket_path);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::AtomicUsize;

    struct TestHandler {
        toggle_count: AtomicUsize,
    }

    impl WaybarCommandHandler for TestHandler {
        fn on_toggle(&self) {
            self.toggle_count.fetch_add(1, Ordering::Relaxed);
        }
        fn on_next(&self) {}
        fn on_prev(&self) {}
        fn on_stop(&self) {}
    }

    #[test]
    fn test_waybar_ipc_socket() {
        let rt = Arc::new(tokio::runtime::Runtime::new().unwrap());
        let handler = Arc::new(TestHandler {
            toggle_count: AtomicUsize::new(0),
        });

        let ipc = WaybarIpc::new(handler.clone(), rt.clone());
        ipc.update_track(Some(CxxTrackMetadata {
            id: "test_id".to_string(),
            title: "Test Title".to_string(),
            artist: "Test Artist".to_string(),
            album: "Test Album".to_string(),
            duration_secs: 200.0,
            thumbnail_url: "".to_string(),
            lyrics: "".to_string(),
        }));
        ipc.update_playback_state(true);
        ipc.update_position(50.0);

        rt.block_on(async {
            tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;

            let socket_path = WaybarIpc::get_socket_path();
            if let Ok(mut stream) = UnixStream::connect(&socket_path).await {
                stream.write_all(b"toggle\n").await.unwrap();

                let mut resp = Vec::new();
                stream.read_to_end(&mut resp).await.unwrap();
                let json_str = String::from_utf8_lossy(&resp);

                let payload: serde_json::Value = serde_json::from_str(json_str.trim()).unwrap();
                assert_eq!(payload["text"], "Test Artist - Test Title");
                assert_eq!(payload["class"], "playing");
                assert_eq!(payload["percentage"], 25);
                assert_eq!(handler.toggle_count.load(Ordering::Relaxed), 1);
            }
        });
    }
}
