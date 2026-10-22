//! MPRIS: how a Linux desktop finds out what a player is playing.
//!
//! The tray applet, the media keys, the lock screen widget, the volume OSD
//! and the keyboard's play button all speak this and nothing else. A player
//! that does not answer them is a window the desktop cannot name.
//!
//! The one thing that matters here is that nothing polls. A desktop reads
//! the player once when it appears and then waits to be told what changed,
//! so a player that updates its own state and says nothing is indistinguishable
//! from one that is idle — which is how a player ends up playing a song its
//! own tray cannot name.

use crate::ffi::CxxTrackMetadata;
use parking_lot::RwLock;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::runtime::Runtime;
use zbus::zvariant::{ObjectPath, Value};
use zbus::{connection::Builder, interface, Connection, SignalContext};

/// Where the desktop looks for the player.
const OBJECT_PATH: &str = "/org/mpris/MediaPlayer2";
const PLAYER_INTERFACE: &str = "org.mpris.MediaPlayer2.Player";
const PROPERTIES_INTERFACE: &str = "org.freedesktop.DBus.Properties";

pub trait MprisCommandHandler: Send + Sync + 'static {
    fn on_play_pause(&self);
    fn on_play(&self);
    fn on_pause(&self);
    fn on_stop(&self);
    fn on_next(&self);
    fn on_previous(&self);
    /// Move the playhead to an absolute position, in seconds.
    ///
    /// MPRIS asks for relative moves; the audio engine only seeks to a
    /// destination. The offset is turned into one here, because handing it
    /// straight through sends "skip forward ten seconds" to the tenth second
    /// of the track instead.
    fn on_seek_absolute(&self, seconds: f64);
    fn on_set_volume(&self, volume: f64);
    /// Whether the queue is shuffled, so the desktop can show the switch.
    fn shuffle(&self) -> bool;
    /// 0 = off, 1 = repeat the queue, 2 = repeat one track.
    fn repeat_mode(&self) -> i32;
}

pub struct MprisState {
    pub handler: Arc<dyn MprisCommandHandler>,
    pub current_track: RwLock<Option<CxxTrackMetadata>>,
    pub is_playing: AtomicBool,
    pub current_position_secs: RwLock<f64>,
    pub volume: RwLock<f64>,
    runtime: Arc<Runtime>,
    conn: RwLock<Option<Connection>>,
}

/// A track id becomes an object path.
///
/// Object paths accept `[A-Za-z0-9_/]` and nothing else, and YouTube video
/// ids contain hyphens. A single invalid character is enough for the whole
/// Metadata reply to be rejected, so the id is transliterated rather than
/// trusted.
fn track_object_path(id: &str) -> String {
    let safe: String = id
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '_' {
                c
            } else {
                '_'
            }
        })
        .collect();
    format!("{OBJECT_PATH}/track/{safe}")
}

fn loop_status(repeat_mode: i32) -> &'static str {
    match repeat_mode {
        1 => "Playlist",
        2 => "Track",
        _ => "None",
    }
}

fn build_metadata(track: &CxxTrackMetadata) -> HashMap<String, Value<'static>> {
    let mut map = HashMap::new();
    // `mpris:trackid` has to be a real object path, not a string that looks
    // like one: a desktop that cannot parse the track id drops the track.
    if let Ok(path) = ObjectPath::try_from(track_object_path(&track.id)) {
        map.insert("mpris:trackid".to_string(), Value::ObjectPath(path));
    }
    map.insert("xesam:title".to_string(), Value::from(track.title.clone()));
    if !track.artist.is_empty() {
        map.insert(
            "xesam:artist".to_string(),
            Value::from(vec![track.artist.clone()]),
        );
    }
    if !track.album.is_empty() {
        map.insert("xesam:album".to_string(), Value::from(track.album.clone()));
    }
    map.insert(
        "mpris:length".to_string(),
        Value::from((track.duration_secs * 1_000_000.0) as i64),
    );
    if !track.thumbnail_url.is_empty() {
        map.insert(
            "mpris:artUrl".to_string(),
            Value::from(track.thumbnail_url.clone()),
        );
    }
    map
}

impl MprisState {
    /// Announce that properties have changed, and what they changed to.
    ///
    /// Sent without a destination so every desktop listening picks it up.
    fn emit_properties_changed(
        &self,
        interface: &'static str,
        changed: HashMap<String, Value<'static>>,
        invalidated: Vec<&'static str>,
    ) {
        let Some(conn) = self.conn.read().clone() else {
            return;
        };
        self.runtime.spawn(async move {
            let _ = conn
                .emit_signal(
                    None::<&str>,
                    OBJECT_PATH,
                    PROPERTIES_INTERFACE,
                    "PropertiesChanged",
                    &(interface, changed, invalidated),
                )
                .await;
        });
    }

    fn emit_seeked(&self, position_micros: i64) {
        let Some(conn) = self.conn.read().clone() else {
            return;
        };
        self.runtime.spawn(async move {
            let _ = conn
                .emit_signal(
                    None::<&str>,
                    OBJECT_PATH,
                    PLAYER_INTERFACE,
                    "Seeked",
                    &(position_micros,),
                )
                .await;
        });
    }
}

/// The root interface only says who the player is, and none of that depends
/// on what is playing, so it holds no state of its own.
pub struct MediaPlayer2 {}

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
    fn has_track_list(&self) -> bool {
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

    /// Move the playhead by an offset, in microseconds, as asked.
    async fn seek(&self, offset_microseconds: i64) {
        let target = (*self.state.current_position_secs.read()
            + (offset_microseconds as f64) / 1_000_000.0)
            .max(0.0);
        self.state.handler.on_seek_absolute(target);
        self.state.emit_seeked((target * 1_000_000.0) as i64);
    }

    /// Move the playhead to an absolute position, in microseconds.
    ///
    /// The track id is checked first: a seek aimed at a track that has
    /// already been replaced by the next one must not move the new one.
    async fn set_position(&self, track_id: ObjectPath<'_>, position_microseconds: i64) {
        let expected = self
            .state
            .current_track
            .read()
            .as_ref()
            .map(|track| track_object_path(&track.id));
        if expected.as_deref() != Some(track_id.as_str()) {
            return;
        }
        let seconds = (position_microseconds as f64 / 1_000_000.0).max(0.0);
        self.state.handler.on_seek_absolute(seconds);
        self.state.emit_seeked(position_microseconds);
    }

    #[zbus(signal)]
    async fn seeked(ctxt: &SignalContext<'_>, position: i64) -> zbus::Result<()>;

    #[zbus(property)]
    fn playback_status(&self) -> &str {
        if self.state.is_playing.load(Ordering::Relaxed) {
            "Playing"
        } else {
            "Paused"
        }
    }

    #[zbus(property)]
    fn metadata(&self) -> HashMap<String, Value<'static>> {
        match self.state.current_track.read().as_ref() {
            Some(track) => build_metadata(track),
            None => HashMap::new(),
        }
    }

    #[zbus(property)]
    fn volume(&self) -> f64 {
        *self.state.volume.read()
    }

    #[zbus(property)]
    fn position(&self) -> i64 {
        (*self.state.current_position_secs.read() * 1_000_000.0) as i64
    }

    #[zbus(property)]
    fn rate(&self) -> f64 {
        1.0
    }

    #[zbus(property)]
    fn minimum_rate(&self) -> f64 {
        1.0
    }

    #[zbus(property)]
    fn maximum_rate(&self) -> f64 {
        1.0
    }

    #[zbus(property)]
    fn shuffle(&self) -> bool {
        self.state.handler.shuffle()
    }

    #[zbus(property)]
    fn loop_status(&self) -> &str {
        loop_status(self.state.handler.repeat_mode())
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
    pub fn new(handler: Arc<dyn MprisCommandHandler>, runtime: Arc<Runtime>) -> Self {
        let state = Arc::new(MprisState {
            handler,
            current_track: RwLock::new(None),
            is_playing: AtomicBool::new(false),
            current_position_secs: RwLock::new(0.0),
            volume: RwLock::new(1.0),
            runtime: runtime.clone(),
            conn: RwLock::new(None),
        });

        let player_state = state.clone();
        let state_for_conn = state.clone();

        runtime.spawn(async move {
            let res = async {
                let conn = Builder::session()?
                    .name("org.mpris.MediaPlayer2.melyar")?
                    .serve_at(OBJECT_PATH, MediaPlayer2 {})?
                    .serve_at(
                        OBJECT_PATH,
                        MediaPlayer2Player {
                            state: player_state,
                        },
                    )?
                    .build()
                    .await?;
                // Held here rather than dropped, and published to the state
                // so the property changes can be sent when something moves.
                *state_for_conn.conn.write() = Some(conn);
                std::future::pending::<()>().await;
                Ok::<(), zbus::Error>(())
            };
            let _ = res.await;
        });

        Self { state }
    }

    pub fn update_track(&self, track: Option<CxxTrackMetadata>) {
        *self.state.current_track.write() = track;
        // Both are sent together: a track that arrives already paused still
        // has to appear in the tray with its name and its cover.
        let metadata = match self.state.current_track.read().as_ref() {
            Some(track) => build_metadata(track),
            None => HashMap::new(),
        };
        let status = if self.state.is_playing.load(Ordering::Relaxed) {
            "Playing"
        } else {
            "Paused"
        };
        let mut changed = HashMap::new();
        changed.insert("Metadata".to_string(), Value::from(metadata));
        changed.insert("PlaybackStatus".to_string(), Value::from(status));
        self.state
            .emit_properties_changed(PLAYER_INTERFACE, changed, Vec::new());
    }

    pub fn update_playback_state(&self, is_playing: bool) {
        self.state.is_playing.store(is_playing, Ordering::Relaxed);
        let status = if is_playing { "Playing" } else { "Paused" };
        let mut changed = HashMap::new();
        changed.insert("PlaybackStatus".to_string(), Value::from(status));
        self.state
            .emit_properties_changed(PLAYER_INTERFACE, changed, Vec::new());
    }

    pub fn update_position(&self, position_secs: f64) {
        *self.state.current_position_secs.write() = position_secs;
        // Deliberately silent. Position moves several times a second, every
        // desktop already polls it, and announcing it would be a storm of
        // signals for a value nobody waits on.
    }

    pub fn update_volume(&self, volume: f64) {
        *self.state.volume.write() = volume.clamp(0.0, 1.0);
        let mut changed = HashMap::new();
        changed.insert("Volume".to_string(), Value::from(*self.state.volume.read()));
        self.state
            .emit_properties_changed(PLAYER_INTERFACE, changed, Vec::new());
    }

    /// Tell the desktop that the repeat and shuffle switches have moved.
    ///
    /// The values are read from the queue rather than passed in, so there is
    /// no second copy of the state that can disagree with what plays.
    pub fn update_queue_modes(&self) {
        let mut changed = HashMap::new();
        changed.insert(
            "LoopStatus".to_string(),
            Value::from(loop_status(self.state.handler.repeat_mode())),
        );
        changed.insert(
            "Shuffle".to_string(),
            Value::from(self.state.handler.shuffle()),
        );
        self.state
            .emit_properties_changed(PLAYER_INTERFACE, changed, Vec::new());
    }
}
