use crate::ffi::CxxTrackMetadata;
use parking_lot::RwLock;
use rand::seq::SliceRandom;
use rand::thread_rng;

pub struct TrackQueue {
    tracks: RwLock<Vec<CxxTrackMetadata>>,
    original_tracks: RwLock<Vec<CxxTrackMetadata>>,
    current_index: RwLock<usize>,
    repeat_mode: RwLock<i32>, // 0=off, 1=all, 2=one
    shuffle: RwLock<bool>,
}

impl TrackQueue {
    pub fn new() -> Self {
        Self {
            tracks: RwLock::new(Vec::new()),
            original_tracks: RwLock::new(Vec::new()),
            current_index: RwLock::new(0),
            repeat_mode: RwLock::new(0),
            shuffle: RwLock::new(false),
        }
    }

    pub fn set_queue(&self, tracks: Vec<CxxTrackMetadata>, start_index: usize) {
        let mut t = self.tracks.write();
        let mut orig = self.original_tracks.write();
        let mut idx = self.current_index.write();

        *orig = tracks.clone();

        if *self.shuffle.read() {
            let mut shuffled = tracks.clone();
            shuffled.shuffle(&mut thread_rng());
            *t = shuffled;
        } else {
            *t = tracks;
        }

        *idx = if !t.is_empty() && start_index < t.len() {
            start_index
        } else {
            0
        };
    }

    pub fn current_track(&self) -> Option<CxxTrackMetadata> {
        let t = self.tracks.read();
        let idx = *self.current_index.read();
        t.get(idx).cloned()
    }

    pub fn next_track(&self) -> Option<CxxTrackMetadata> {
        let t = self.tracks.read();
        if t.is_empty() {
            return None;
        }
        let mut idx = self.current_index.write();
        let repeat = *self.repeat_mode.read();

        if repeat == 2 {
            // Repeat one - stay on current track
            t.get(*idx).cloned()
        } else if *idx + 1 < t.len() {
            *idx += 1;
            t.get(*idx).cloned()
        } else if repeat == 1 {
            // Repeat all - go to first
            *idx = 0;
            t.first().cloned()
        } else {
            None
        }
    }

    pub fn peek_next_track(&self) -> Option<CxxTrackMetadata> {
        let t = self.tracks.read();
        if t.is_empty() {
            return None;
        }
        let idx = *self.current_index.read();
        let repeat = *self.repeat_mode.read();

        if repeat == 2 {
            t.get(idx).cloned()
        } else if idx + 1 < t.len() {
            t.get(idx + 1).cloned()
        } else if repeat == 1 {
            t.first().cloned()
        } else {
            None
        }
    }

    pub fn previous_track(&self) -> Option<CxxTrackMetadata> {
        let t = self.tracks.read();
        if t.is_empty() {
            return None;
        }
        let mut idx = self.current_index.write();
        if *idx > 0 {
            *idx -= 1;
            t.get(*idx).cloned()
        } else {
            t.first().cloned()
        }
    }

    pub fn list(&self) -> Vec<CxxTrackMetadata> {
        self.tracks.read().clone()
    }

    pub fn set_shuffle(&self, enabled: bool) {
        let mut shuffle = self.shuffle.write();
        *shuffle = enabled;

        if enabled {
            // Shuffle the current queue
            let mut t = self.tracks.write();
            let current_idx = *self.current_index.read();
            let current_track = t.get(current_idx).cloned();

            let mut orig = self.original_tracks.read().clone();
            orig.shuffle(&mut thread_rng());

            // Keep current track at current position
            if let Some(current) = current_track {
                if let Some(pos) = orig.iter().position(|t| t.id == current.id) {
                    if pos != current_idx {
                        orig.swap(pos, current_idx);
                    }
                }
            }

            *t = orig;
        } else {
            // Restore original order
            let mut t = self.tracks.write();
            let orig = self.original_tracks.read().clone();
            let current_idx = *self.current_index.read();
            let current_track = t.get(current_idx).cloned();

            *t = orig;

            // Find current track in original order
            if let Some(current) = current_track {
                if let Some(pos) = t.iter().position(|t| t.id == current.id) {
                    let mut idx = self.current_index.write();
                    *idx = pos;
                }
            }
        }
    }

    pub fn set_repeat_mode(&self, mode: i32) {
        let mut repeat = self.repeat_mode.write();
        *repeat = mode.clamp(0, 2);
    }

    /// Whether the queue is shuffled, as the desktop needs to show it.
    pub fn shuffle(&self) -> bool {
        *self.shuffle.read()
    }

    /// 0 = off, 1 = repeat the queue, 2 = repeat one track.
    pub fn repeat_mode(&self) -> i32 {
        *self.repeat_mode.read()
    }
}

impl Default for TrackQueue {
    fn default() -> Self {
        Self::new()
    }
}
