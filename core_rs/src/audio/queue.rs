use crate::ffi::CxxTrackMetadata;
use parking_lot::RwLock;

pub struct TrackQueue {
    tracks: RwLock<Vec<CxxTrackMetadata>>,
    current_index: RwLock<usize>,
    pub repeat: RwLock<bool>,
    pub shuffle: RwLock<bool>,
}

impl TrackQueue {
    pub fn new() -> Self {
        Self {
            tracks: RwLock::new(Vec::new()),
            current_index: RwLock::new(0),
            repeat: RwLock::new(false),
            shuffle: RwLock::new(false),
        }
    }

    pub fn set_queue(&self, tracks: Vec<CxxTrackMetadata>, start_index: usize) {
        let mut t = self.tracks.write();
        let mut idx = self.current_index.write();
        *t = tracks;
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
        if *idx + 1 < t.len() {
            *idx += 1;
            t.get(*idx).cloned()
        } else if *self.repeat.read() {
            *idx = 0;
            t.get(0).cloned()
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
        if idx + 1 < t.len() {
            t.get(idx + 1).cloned()
        } else if *self.repeat.read() {
            t.get(0).cloned()
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
            t.get(0).cloned()
        }
    }

    pub fn list(&self) -> Vec<CxxTrackMetadata> {
        self.tracks.read().clone()
    }
}
