pub mod audio;
pub mod db;
pub mod innertube;
pub mod linux;

use once_cell::sync::OnceCell;
use parking_lot::Mutex;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::audio::engine::{AudioEventHandler, MelyarAudioEngine};
use crate::audio::queue::TrackQueue;
use crate::db::storage::DbStorage;
use crate::innertube::client::InnerTubeClient;
use crate::linux::mpris::{MprisCommandHandler, MprisManager};
use crate::linux::waybar::{WaybarCommandHandler, WaybarIpc};

#[cxx::bridge(namespace = "melyar")]
pub mod ffi {
    #[derive(Clone, Debug, Default)]
    pub struct CxxTrackMetadata {
        pub id: String,
        pub title: String,
        pub artist: String,
        pub album: String,
        pub duration_secs: f64,
        pub thumbnail_url: String,
        pub lyrics: String,
    }

    #[derive(Clone, Debug, Default)]
    pub struct CxxLibraryAlbum {
        pub id: String,
        pub title: String,
        pub artist: String,
        pub thumbnail_url: String,
        pub year: String,
        pub track_count: i32,
        pub duration_secs: f64,
    }

    #[derive(Clone, Debug, Default)]
    pub struct CxxLibraryArtist {
        pub id: String,
        pub name: String,
        pub thumbnail_url: String,
        pub follower_count: i64,
    }

    #[derive(Clone, Debug, Default)]
    pub struct CxxLibraryPlaylist {
        pub id: String,
        pub name: String,
        pub thumbnail_url: String,
        pub track_count: i32,
        pub is_owner: bool,
    }

    unsafe extern "C++" {
        include!("bridge.hpp");

        fn on_progress_update(current: f64, total: f64);
        fn on_track_changed(track: CxxTrackMetadata);
        fn on_state_changed(is_playing: bool);
        fn on_lyrics_loaded(track_id: String, lyrics_lrc: String);
        fn on_search_results(results: Vec<CxxTrackMetadata>);
    }

    extern "Rust" {
        fn init_melyar_core() -> bool;
        fn search(query: String) -> Vec<CxxTrackMetadata>;
        fn play_track(track_id: String) -> bool;
        fn toggle_play() -> bool;
        fn seek(seconds: f64) -> bool;
        fn set_volume(volume: f64) -> bool;
        fn next_track() -> bool;
        fn previous_track() -> bool;
        fn fetch_lyrics(track_id: String) -> String;
        fn fetch_lyrics_live(
            track_id: String,
            title: String,
            artist: String,
            duration: f64,
        ) -> String;
        fn toggle_favorite(
            track_id: String,
            title: String,
            artist: String,
            album: String,
            duration: f64,
            thumb: String,
        ) -> bool;
        fn is_favorite(track_id: String) -> bool;
        fn get_favorites() -> Vec<CxxTrackMetadata>;
        fn get_history() -> Vec<CxxTrackMetadata>;
        fn set_shuffle(enabled: bool) -> bool;
        fn set_repeat_mode(mode: i32) -> bool;
        fn replace_queue(tracks: Vec<CxxTrackMetadata>, start_index: i32) -> bool;
        fn get_queue() -> Vec<CxxTrackMetadata>;
        fn get_track_metadata(track_id: String) -> CxxTrackMetadata;
        fn get_library_albums() -> Vec<CxxLibraryAlbum>;
        fn get_library_artists() -> Vec<CxxLibraryArtist>;
        fn get_library_playlists() -> Vec<CxxLibraryPlaylist>;
        fn clear_search_history() -> bool;
        fn remove_from_search_history(query: String) -> bool;
    }
}

pub struct MelyarCore {
    innertube: Arc<InnerTubeClient>,
    queue: Arc<TrackQueue>,
    storage: Arc<DbStorage>,
    audio: Mutex<Option<Arc<MelyarAudioEngine>>>,
    _mpris: Mutex<Option<Arc<MprisManager>>>,
    _waybar: Mutex<Option<Arc<WaybarIpc>>>,
    runtime: Arc<Runtime>,
}

struct EngineEvents {
    queue: Arc<TrackQueue>,
    innertube: Arc<InnerTubeClient>,
    audio_holder: Mutex<Option<Arc<MelyarAudioEngine>>>,
    mpris_holder: Mutex<Option<Arc<MprisManager>>>,
    waybar_holder: Mutex<Option<Arc<WaybarIpc>>>,
    storage: Arc<DbStorage>,
    runtime: Arc<Runtime>,
}

impl AudioEventHandler for EngineEvents {
    fn on_progress(&self, current_secs: f64, total_secs: f64) {
        if let Some(ref mpris) = *self.mpris_holder.lock() {
            mpris.update_position(current_secs);
        }
        if let Some(ref waybar) = *self.waybar_holder.lock() {
            waybar.update_position(current_secs);
        }
        ffi::on_progress_update(current_secs, total_secs);
    }

    fn on_state_changed(&self, is_playing: bool) {
        if let Some(ref mpris) = *self.mpris_holder.lock() {
            mpris.update_playback_state(is_playing);
        }
        if let Some(ref waybar) = *self.waybar_holder.lock() {
            waybar.update_playback_state(is_playing);
        }
        ffi::on_state_changed(is_playing);
    }

    fn on_track_ended(&self) {
        if let Some(next) = self.queue.next_track() {
            let innertube = self.innertube.clone();
            let audio_opt = self.audio_holder.lock().clone();
            let storage = self.storage.clone();
            let mpris_opt = self.mpris_holder.lock().clone();
            let waybar_opt = self.waybar_holder.lock().clone();
            let rt = self.runtime.clone();

            rt.spawn(async move {
                if let Ok(url) = innertube.get_stream_url(&next.id).await {
                    if let Some(audio) = audio_opt {
                        let _ = audio.play_url(&url);
                        let _ = storage.add_history(&next);
                        if let Some(ref mpris) = mpris_opt {
                            mpris.update_track(Some(next.clone()));
                        }
                        if let Some(ref waybar) = waybar_opt {
                            waybar.update_track(Some(next.clone()));
                        }
                        ffi::on_track_changed(next.clone());

                        // Fetch lyrics
                        if let Ok(lrc) = innertube::lyrics::fetch_lyrics(
                            &reqwest::Client::new(),
                            &next.title,
                            &next.artist,
                            Some(next.duration_secs),
                        )
                        .await
                        {
                            let _ = storage.cache_lyrics(&next.id, &lrc);
                            ffi::on_lyrics_loaded(next.id.clone(), lrc);
                        }
                    }
                }
            });
        } else {
            ffi::on_state_changed(false);
        }
    }

    fn on_gapless_prefetch_needed(&self) {
        if let Some(next) = self.queue.peek_next_track() {
            let innertube = self.innertube.clone();
            let audio_opt = self.audio_holder.lock().clone();
            let rt = self.runtime.clone();

            rt.spawn(async move {
                if let Ok(url) = innertube.get_stream_url(&next.id).await {
                    if let Some(audio) = audio_opt {
                        let _ = audio.queue_next_url(&url);
                    }
                }
            });
        }
    }
}

#[allow(dead_code)]
struct MprisHandlerImpl {
    queue: Arc<TrackQueue>,
    innertube: Arc<InnerTubeClient>,
    audio_holder: Arc<Mutex<Option<Arc<MelyarAudioEngine>>>>,
    storage: Arc<DbStorage>,
    runtime: Arc<Runtime>,
}

impl MprisCommandHandler for MprisHandlerImpl {
    fn on_play_pause(&self) {
        let _ = toggle_play();
    }
    fn on_play(&self) {
        if let Some(ref audio) = *self.audio_holder.lock() {
            if !audio.is_playing() {
                let _ = audio.toggle_play();
            }
        }
    }
    fn on_pause(&self) {
        if let Some(ref audio) = *self.audio_holder.lock() {
            if audio.is_playing() {
                let _ = audio.toggle_play();
            }
        }
    }
    fn on_stop(&self) {
        if let Some(ref audio) = *self.audio_holder.lock() {
            let _ = audio.stop();
        }
    }
    fn on_next(&self) {
        let _ = next_track();
    }
    fn on_previous(&self) {
        let _ = previous_track();
    }
    fn on_seek(&self, offset_micros: i64) {
        let secs = (offset_micros as f64) / 1_000_000.0;
        let _ = seek(secs);
    }
    fn on_set_volume(&self, volume: f64) {
        let _ = set_volume(volume * 100.0);
    }
}

impl WaybarCommandHandler for MprisHandlerImpl {
    fn on_toggle(&self) {
        let _ = toggle_play();
    }
    fn on_next(&self) {
        let _ = next_track();
    }
    fn on_prev(&self) {
        let _ = previous_track();
    }
    fn on_stop(&self) {
        if let Some(ref audio) = *self.audio_holder.lock() {
            let _ = audio.stop();
        }
    }
}

static CORE: OnceCell<Arc<MelyarCore>> = OnceCell::new();

fn get_core() -> &'static Arc<MelyarCore> {
    CORE.get_or_init(|| {
        let runtime = Arc::new(Runtime::new().expect("Failed to create tokio runtime"));
        let innertube =
            Arc::new(InnerTubeClient::new().expect("Failed to initialize InnerTube client"));
        let queue = Arc::new(TrackQueue::new());
        let storage = Arc::new(DbStorage::new().expect("Failed to initialize SQLite storage"));

        let events = Arc::new(EngineEvents {
            queue: queue.clone(),
            innertube: innertube.clone(),
            audio_holder: Mutex::new(None),
            mpris_holder: Mutex::new(None),
            waybar_holder: Mutex::new(None),
            storage: storage.clone(),
            runtime: runtime.clone(),
        });

        let audio = match MelyarAudioEngine::new(events.clone()) {
            Ok(eng) => {
                let arc_eng = Arc::new(eng);
                *events.audio_holder.lock() = Some(arc_eng.clone());
                Some(arc_eng)
            }
            Err(e) => {
                eprintln!("Failed to initialize audio engine: {}", e);
                None
            }
        };

        let audio_holder_for_mpris = Arc::new(Mutex::new(audio.clone()));
        let mpris_handler = Arc::new(MprisHandlerImpl {
            queue: queue.clone(),
            innertube: innertube.clone(),
            audio_holder: audio_holder_for_mpris,
            storage: storage.clone(),
            runtime: runtime.clone(),
        });

        let mpris = Arc::new(MprisManager::new(mpris_handler.clone(), runtime.clone()));
        *events.mpris_holder.lock() = Some(mpris.clone());

        let waybar = Arc::new(WaybarIpc::new(mpris_handler, runtime.clone()));
        *events.waybar_holder.lock() = Some(waybar.clone());

        Arc::new(MelyarCore {
            innertube,
            queue,
            storage,
            audio: Mutex::new(audio),
            _mpris: Mutex::new(Some(mpris)),
            _waybar: Mutex::new(Some(waybar)),
            runtime,
        })
    })
}

pub fn init_melyar_core() -> bool {
    let _ = get_core();
    true
}

pub fn search(query: String) -> Vec<ffi::CxxTrackMetadata> {
    let core = get_core();
    let client = core.innertube.clone();
    let q_clone = query.clone();

    let res = core
        .runtime
        .block_on(async move { client.search_tracks(&q_clone).await });

    match res {
        Ok(tracks) => {
            core.queue.set_queue(tracks.clone(), 0);
            ffi::on_search_results(tracks.clone());
            tracks
        }
        Err(e) => {
            eprintln!("Search error for '{}': {}", query, e);
            Vec::new()
        }
    }
}

pub fn play_track(track_id: String) -> bool {
    let core = get_core();
    let innertube = core.innertube.clone();
    let audio_opt = core.audio.lock().clone();
    let storage = core.storage.clone();
    let mpris_opt = core._mpris.lock().clone();
    let waybar_opt = core._waybar.lock().clone();
    let queue = core.queue.clone();
    let rt = core.runtime.clone();

    let current_meta = queue.list().into_iter().find(|t| t.id == track_id);
    let track_id_clone = track_id.clone();

    rt.spawn(async move {
        // Metadata: queue lookup first; otherwise resolve once via yt-dlp.
        let meta = match current_meta {
            Some(m) => m,
            None => {
                let innertube_meta = innertube.clone();
                let tid = track_id_clone.clone();
                match tokio::task::spawn_blocking(move || {
                    innertube::client::with_ytdlp_lock(|| {
                        innertube_meta.resolve_video_blocking(&tid)
                    })
                })
                .await
                {
                    Ok(Ok(resolved)) => resolved.to_meta(),
                    Ok(Err(e)) => {
                        eprintln!("Metadata resolve failed for {}: {}", track_id_clone, e);
                        innertube::client::ResolvedVideo::default().to_meta()
                    }
                    Err(e) => {
                        eprintln!("Metadata resolve task failed for {}: {}", track_id_clone, e);
                        innertube::client::ResolvedVideo::default().to_meta()
                    }
                }
            }
        };

        match innertube.get_stream_url(&track_id_clone).await {
            Ok(url) => {
                if let Some(audio) = audio_opt {
                    if let Err(e) = audio.play_url(&url) {
                        eprintln!("Error playing stream URL: {}", e);
                    } else {
                        let _ = storage.add_history(&meta);
                        if let Some(ref mpris) = mpris_opt {
                            mpris.update_track(Some(meta.clone()));
                        }
                        if let Some(ref waybar) = waybar_opt {
                            waybar.update_track(Some(meta.clone()));
                        }
                        ffi::on_track_changed(meta.clone());

                        let title = meta.title.clone();
                        let artist = meta.artist.clone();
                        let dur = meta.duration_secs;
                        let tid = meta.id.clone();
                        let st = storage.clone();

                        tokio::spawn(async move {
                            if let Ok(Some(cached)) = st.get_cached_lyrics(&tid) {
                                ffi::on_lyrics_loaded(tid, cached);
                            } else if let Ok(lrc) = innertube::lyrics::fetch_lyrics(
                                &reqwest::Client::new(),
                                &title,
                                &artist,
                                Some(dur),
                            )
                            .await
                            {
                                let _ = st.cache_lyrics(&tid, &lrc);
                                ffi::on_lyrics_loaded(tid, lrc);
                            }
                        });
                    }
                }
            }
            Err(e) => {
                eprintln!("Failed to get stream url for {}: {}", track_id_clone, e);
            }
        }
    });

    true
}

pub fn toggle_play() -> bool {
    let core = get_core();
    if let Some(ref audio) = *core.audio.lock() {
        audio.toggle_play().unwrap_or(false)
    } else {
        false
    }
}

pub fn seek(seconds: f64) -> bool {
    let core = get_core();
    if let Some(ref audio) = *core.audio.lock() {
        audio.seek(seconds).is_ok()
    } else {
        false
    }
}

pub fn set_volume(volume: f64) -> bool {
    let core = get_core();
    if let Some(ref audio) = *core.audio.lock() {
        audio.set_volume(volume).is_ok()
    } else {
        false
    }
}

pub fn next_track() -> bool {
    let core = get_core();
    if let Some(next) = core.queue.next_track() {
        play_track(next.id)
    } else {
        false
    }
}

pub fn previous_track() -> bool {
    let core = get_core();
    if let Some(prev) = core.queue.previous_track() {
        play_track(prev.id)
    } else {
        false
    }
}

pub fn fetch_lyrics(track_id: String) -> String {
    let core = get_core();
    if let Ok(Some(cached)) = core.storage.get_cached_lyrics(&track_id) {
        return cached;
    }
    String::new()
}

/// Cache-first, then live lrclib fetch. Called from a Qt worker thread.
pub fn fetch_lyrics_live(track_id: String, title: String, artist: String, duration: f64) -> String {
    let core = get_core();
    if let Ok(Some(cached)) = core.storage.get_cached_lyrics(&track_id) {
        if !cached.trim().is_empty() {
            return cached;
        }
    }
    if title.trim().is_empty() {
        return String::new();
    }
    let res = core.runtime.block_on(async {
        innertube::lyrics::fetch_lyrics(&reqwest::Client::new(), &title, &artist, Some(duration))
            .await
    });
    match res {
        Ok(lrc) => {
            if !lrc.trim().is_empty() {
                let _ = core.storage.cache_lyrics(&track_id, &lrc);
            }
            lrc
        }
        Err(_) => String::new(),
    }
}

pub fn toggle_favorite(
    track_id: String,
    title: String,
    artist: String,
    album: String,
    duration: f64,
    thumb: String,
) -> bool {
    let core = get_core();
    let track = ffi::CxxTrackMetadata {
        id: track_id,
        title,
        artist,
        album,
        duration_secs: duration,
        thumbnail_url: thumb,
        lyrics: String::new(),
    };
    core.storage.toggle_favorite(&track).unwrap_or(false)
}

pub fn is_favorite(track_id: String) -> bool {
    let core = get_core();
    core.storage.is_favorite(&track_id).unwrap_or(false)
}

pub fn get_favorites() -> Vec<ffi::CxxTrackMetadata> {
    let core = get_core();
    core.storage.get_favorites().unwrap_or_default()
}

pub fn get_history() -> Vec<ffi::CxxTrackMetadata> {
    let core = get_core();
    core.storage.get_history(100).unwrap_or_default()
}

pub fn set_shuffle(enabled: bool) -> bool {
    let core = get_core();
    core.queue.set_shuffle(enabled);
    true
}

pub fn set_repeat_mode(mode: i32) -> bool {
    let core = get_core();
    core.queue.set_repeat_mode(mode);
    true
}

/// Web UI sends its playback context (a list/album/search page) so that
/// media keys, MPRIS and auto-advance all follow the same queue.
pub fn replace_queue(tracks: Vec<ffi::CxxTrackMetadata>, start_index: i32) -> bool {
    let core = get_core();
    core.queue.set_queue(tracks, start_index.max(0) as usize);
    true
}

pub fn get_queue() -> Vec<ffi::CxxTrackMetadata> {
    let core = get_core();
    core.queue.list()
}

pub fn get_track_metadata(track_id: String) -> ffi::CxxTrackMetadata {
    let core = get_core();
    let queue = core.queue.list();
    if let Some(m) = queue.into_iter().find(|t| t.id == track_id) {
        return m;
    }
    // Fallback: resolve metadata via yt-dlp (blocking; caller runs on a worker thread).
    match innertube::client::with_ytdlp_lock(|| core.innertube.resolve_video_blocking(&track_id)) {
        Ok(resolved) => resolved.to_meta(),
        Err(_) => ffi::CxxTrackMetadata::default(),
    }
}

pub fn get_library_albums() -> Vec<ffi::CxxLibraryAlbum> {
    let core = get_core();
    core.storage.get_library_albums().unwrap_or_default()
}

pub fn get_library_artists() -> Vec<ffi::CxxLibraryArtist> {
    let core = get_core();
    core.storage.get_library_artists().unwrap_or_default()
}

pub fn get_library_playlists() -> Vec<ffi::CxxLibraryPlaylist> {
    let core = get_core();
    core.storage.get_library_playlists().unwrap_or_default()
}

pub fn clear_search_history() -> bool {
    let core = get_core();
    core.storage.clear_search_history().unwrap_or(false)
}

pub fn remove_from_search_history(query: String) -> bool {
    let core = get_core();
    core.storage
        .remove_from_search_history(&query)
        .unwrap_or(false)
}
