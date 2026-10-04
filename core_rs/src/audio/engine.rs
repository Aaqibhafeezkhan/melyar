use anyhow::{anyhow, Result};
use libmpv_sys as mpv_sys;
use std::ffi::{CStr, CString};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;

/// MPV Handle Wrapper with proper cleanup
pub struct MpvHandleWrapper {
    raw: *mut mpv_sys::mpv_handle,
}

unsafe impl Send for MpvHandleWrapper {}
unsafe impl Sync for MpvHandleWrapper {}

impl Drop for MpvHandleWrapper {
    fn drop(&mut self) {
        if !self.raw.is_null() {
            unsafe {
                mpv_sys::mpv_terminate_destroy(self.raw);
            }
        }
    }
}

/// Audio Event Handler trait for callbacks
pub trait AudioEventHandler: Send + Sync + 'static {
    fn on_progress(&self, current_secs: f64, total_secs: f64);
    fn on_state_changed(&self, is_playing: bool);
    fn on_track_ended(&self);
    fn on_gapless_prefetch_needed(&self);
}

/// MPV Audio Engine - Low-level MPV wrapper
pub struct MelyarAudioEngine {
    mpv: Arc<MpvHandleWrapper>,
    is_playing: Arc<AtomicBool>,
    prefetched_next: Arc<AtomicBool>,
}

impl MelyarAudioEngine {
    pub fn new<H: AudioEventHandler>(handler: Arc<H>) -> Result<Self> {
        let handle = unsafe { mpv_sys::mpv_create() };
        if handle.is_null() {
            return Err(anyhow!("Failed to create MPV handle"));
        }

        // Configure MPV for zero video and high performance audio streaming
        unsafe {
            let set_opt = |name: &str, val: &str| {
                let c_name = CString::new(name).unwrap();
                let c_val = CString::new(val).unwrap();
                mpv_sys::mpv_set_option_string(handle, c_name.as_ptr(), c_val.as_ptr());
            };

            // Audio-only configuration
            set_opt("vo", "null");
            set_opt("audio-buffer", "4");
            set_opt("gapless-audio", "yes");
            set_opt("replaygain", "track");
            set_opt("volume", "100");
            set_opt("idle", "yes");
            set_opt("keep-open", "always");

            let res = mpv_sys::mpv_initialize(handle);
            if res < 0 {
                mpv_sys::mpv_terminate_destroy(handle);
                return Err(anyhow!("Failed to initialize MPV, code {}", res));
            }

            // Observe properties
            let time_pos = CString::new("time-pos").unwrap();
            let duration = CString::new("duration").unwrap();
            let pause = CString::new("pause").unwrap();
            let eof_reached = CString::new("eof-reached").unwrap();

            mpv_sys::mpv_observe_property(handle, 1, time_pos.as_ptr(), mpv_sys::mpv_format_MPV_FORMAT_DOUBLE);
            mpv_sys::mpv_observe_property(handle, 2, duration.as_ptr(), mpv_sys::mpv_format_MPV_FORMAT_DOUBLE);
            mpv_sys::mpv_observe_property(handle, 3, pause.as_ptr(), mpv_sys::mpv_format_MPV_FORMAT_FLAG);
            mpv_sys::mpv_observe_property(handle, 4, eof_reached.as_ptr(), mpv_sys::mpv_format_MPV_FORMAT_FLAG);
        }

        let mpv_wrapper = Arc::new(MpvHandleWrapper { raw: handle });
        let is_playing = Arc::new(AtomicBool::new(false));
        let prefetched_next = Arc::new(AtomicBool::new(false));

        // Start event processing thread
        let mpv_clone = mpv_wrapper.clone();
        let is_playing_clone = is_playing.clone();
        let prefetched_clone = prefetched_next.clone();

        thread::Builder::new()
            .name("melyar-mpv-events".into())
            .spawn(move || {
                let mut current_pos = 0.0f64;
                let mut current_dur = 0.0f64;

                loop {
                    let event_ptr = unsafe { mpv_sys::mpv_wait_event(mpv_clone.raw, 0.05) };
                    if event_ptr.is_null() {
                        continue;
                    }
                    let event = unsafe { &*event_ptr };
                    if event.event_id == mpv_sys::mpv_event_id_MPV_EVENT_SHUTDOWN {
                        break;
                    }

                    if event.event_id == mpv_sys::mpv_event_id_MPV_EVENT_PROPERTY_CHANGE {
                        if !event.data.is_null() {
                            let prop = unsafe { &*(event.data as *const mpv_sys::mpv_event_property) };
                            if !prop.name.is_null() {
                                let name = unsafe { CStr::from_ptr(prop.name) }.to_string_lossy();
                                match name.as_ref() {
                                    "time-pos" => {
                                        if prop.format == mpv_sys::mpv_format_MPV_FORMAT_DOUBLE && !prop.data.is_null() {
                                            current_pos = unsafe { *(prop.data as *const f64) };
                                            handler.on_progress(current_pos, current_dur);

                                            // Gapless prefetch trigger: 5 seconds before end
                                            if current_dur > 10.0 && (current_dur - current_pos) <= 5.0 {
                                                if !prefetched_clone.load(Ordering::Relaxed) {
                                                    prefetched_clone.store(true, Ordering::Relaxed);
                                                    handler.on_gapless_prefetch_needed();
                                                }
                                            }
                                        }
                                    }
                                    "duration" => {
                                        if prop.format == mpv_sys::mpv_format_MPV_FORMAT_DOUBLE && !prop.data.is_null() {
                                            current_dur = unsafe { *(prop.data as *const f64) };
                                            handler.on_progress(current_pos, current_dur);
                                        }
                                    }
                                    "pause" => {
                                        if prop.format == mpv_sys::mpv_format_MPV_FORMAT_FLAG && !prop.data.is_null() {
                                            let paused = unsafe { *(prop.data as *const i32) } != 0;
                                            is_playing_clone.store(!paused, Ordering::Relaxed);
                                            handler.on_state_changed(!paused);
                                        }
                                    }
                                    _ => {}
                                }
                            }
                        }
                    } else if event.event_id == mpv_sys::mpv_event_id_MPV_EVENT_END_FILE {
                        handler.on_track_ended();
                    }
                }
            })
            .expect("Failed to spawn mpv event thread");

        Ok(Self {
            mpv: mpv_wrapper,
            is_playing,
            prefetched_next,
        })
    }

    pub fn play_url(&self, url: &str) -> Result<()> {
        self.prefetched_next.store(false, Ordering::Relaxed);
        let cmd = format!("loadfile \"{}\" replace\n", url);
        self.command_string(&cmd)?;
        self.is_playing.store(true, Ordering::Relaxed);
        Ok(())
    }

    pub fn queue_next_url(&self, url: &str) -> Result<()> {
        let cmd = format!("loadfile \"{}\" append-play\n", url);
        self.command_string(&cmd)
    }

    pub fn toggle_play(&self) -> Result<bool> {
        let cmd = "cycle pause\n";
        self.command_string(cmd)?;
        let playing = !self.is_playing.load(Ordering::Relaxed);
        self.is_playing.store(playing, Ordering::Relaxed);
        Ok(playing)
    }

    pub fn seek(&self, seconds: f64) -> Result<()> {
        let cmd = format!("seek {} absolute\n", seconds);
        self.command_string(&cmd)
    }

    pub fn set_volume(&self, volume: f64) -> Result<()> {
        let clamped = volume.clamp(0.0, 100.0);
        let cmd = format!("set volume {}\n", clamped);
        self.command_string(&cmd)
    }

    pub fn stop(&self) -> Result<()> {
        self.command_string("stop\n")?;
        self.is_playing.store(false, Ordering::Relaxed);
        Ok(())
    }

    pub fn is_playing(&self) -> bool {
        self.is_playing.load(Ordering::Relaxed)
    }

    fn command_string(&self, cmd: &str) -> Result<()> {
        let c_cmd = CString::new(cmd)?;
        let res = unsafe { mpv_sys::mpv_command_string(self.mpv.raw, c_cmd.as_ptr()) };
        if res < 0 {
            Err(anyhow!("MPV command failed: {} (code {})", cmd.trim(), res))
        } else {
            Ok(())
        }
    }
}
