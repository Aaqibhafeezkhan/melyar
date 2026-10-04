use std::collections::HashMap;
use std::sync::Arc;
use zbus::{connection::Builder, interface};
use zbus::zvariant::Value;
use crate::ffi::CxxTrackMetadata;

pub trait MprisCommandHandler: Send + Sync + 'static {
    fn on_play_pause(&self);
    fn on_play(&self);
    fn on_pause(&self);
    fn on_stop(&self);
    fn on_next(&self);
    fn on_previous(&self);
    fn on_seek(&self, offset_micros: i64);
    fn on_set_volume(&self, volume: f64);
}

pub struct MprisState {
    pub handler: Arc<dyn MprisCommandHandler>,
    pub current_track: parking_lot::RwLock<Option<CxxTrackMetadata>>,
    pub is_playing: std::sync::atomic::AtomicBool,
    pub current_position_secs: parking_lot::RwLock<f64>,
}

#[allow(dead_code)]
pub struct MediaPlayer2 {
    state: Arc<MprisState>,
}

#[interface(name = "org.mpris.MediaPlayer2")]
impl MediaPlayer2 {
    async fn raise(&self) {}
    async fn quit(&self) {}

    #[zbus(property)]
    fn can_quit(&self) -> bool {
        false
    }

    #[zbus(property)]
    fn can_raise(&self) -> bool {
        false
    }

    #[zbus(property)]
    fn identity(&self) -> &str {
        "Melyar"
    }

    #[zbus(property)]
    fn desktop_entry(&self) -> &str {
        "melyar"
    }

    #[zbus(property)]
    fn supported_uri_schemes(&self) -> Vec<&str> {
        vec!["http", "https"]
    }

    #[zbus(property)]
    fn supported_mime_types(&self) -> Vec<&str> {
        vec!["audio/webm", "audio/opus", "audio/mp4"]
    }
}

pub struct MediaPlayer2Player {
    state: Arc<MprisState>,
}

#[interface(name = "org.mpris.MediaPlayer2.Player")]
impl MediaPlayer2Player {
    async fn next(&self) {
        self.state.handler.on_next();
    }

    async fn previous(&self) {
        self.state.handler.on_previous();
    }

    async fn pause(&self) {
        self.state.handler.on_pause();
    }

    async fn play_pause(&self) {
        self.state.handler.on_play_pause();
    }

    async fn stop(&self) {
        self.state.handler.on_stop();
    }

    async fn play(&self) {
        self.state.handler.on_play();
    }

    async fn seek(&self, offset_micros: i64) {
        self.state.handler.on_seek(offset_micros);
    }

    #[zbus(property)]
    fn playback_status(&self) -> &str {
        if self.state.is_playing.load(std::sync::atomic::Ordering::Relaxed) {
            "Playing"
        } else {
            "Paused"
        }
    }

    #[zbus(property)]
    fn volume(&self) -> f64 {
        1.0
    }

    #[zbus(property)]
    fn position(&self) -> i64 {
        (*self.state.current_position_secs.read() * 1_000_000.0) as i64
    }

    #[zbus(property)]
    fn metadata(&self) -> HashMap<String, Value<'static>> {
        let mut map = HashMap::new();
        if let Some(ref track) = *self.state.current_track.read() {
            map.insert("mpris:trackid".to_string(), Value::from(format!("/org/mpris/MediaPlayer2/track/{}", track.id)));
            map.insert("xesam:title".to_string(), Value::from(track.title.clone()));
            map.insert("xesam:artist".to_string(), Value::from(vec![track.artist.clone()]));
            map.insert("xesam:album".to_string(), Value::from(track.album.clone()));
            map.insert("mpris:length".to_string(), Value::from((track.duration_secs * 1_000_000.0) as i64));
            if !track.thumbnail_url.is_empty() {
                map.insert("mpris:artUrl".to_string(), Value::from(track.thumbnail_url.clone()));
            }
        }
        map
    }

    #[zbus(property)]
    fn can_go_next(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn can_go_previous(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn can_play(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn can_pause(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn can_seek(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn can_control(&self) -> bool {
        true
    }
}

pub struct MprisManager {
    state: Arc<MprisState>,
}

impl MprisManager {
    pub fn new(handler: Arc<dyn MprisCommandHandler>, runtime: Arc<tokio::runtime::Runtime>) -> Self {
        let state = Arc::new(MprisState {
            handler,
            current_track: parking_lot::RwLock::new(None),
            is_playing: std::sync::atomic::AtomicBool::new(false),
            current_position_secs: parking_lot::RwLock::new(0.0),
        });

        let s1 = state.clone();
        let s2 = state.clone();

        runtime.spawn(async move {
            let res = async {
                let builder = Builder::session()?
                    .name("org.mpris.MediaPlayer2.melyar")?
                    .serve_at("/org/mpris/MediaPlayer2", MediaPlayer2 { state: s1 })?
                    .serve_at("/org/mpris/MediaPlayer2", MediaPlayer2Player { state: s2 })?;
                let _conn = builder.build().await?;
                std::future::pending::<()>().await;
                Ok::<(), zbus::Error>(())
            };
            let _ = res.await;
        });

        Self { state }
    }

    pub fn update_track(&self, track: Option<CxxTrackMetadata>) {
        *self.state.current_track.write() = track;
    }

    pub fn update_playback_state(&self, is_playing: bool) {
        self.state.is_playing.store(is_playing, std::sync::atomic::Ordering::Relaxed);
    }

    pub fn update_position(&self, position_secs: f64) {
        *self.state.current_position_secs.write() = position_secs;
    }
}