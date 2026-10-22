use crate::ffi::CxxTrackMetadata;
use parking_lot::RwLock;
use rand::seq::SliceRandom;
use rand::thread_rng;

/// Everything the queue owns, behind one lock.
///
/// This used to be five separate locks. `set_queue` took them in one order and
/// `set_shuffle` in another, so the two racing — the interface pushing a queue
/// while MPRIS or a status bar toggled shuffle — inverted the order and
/// deadlocked every caller: interface, media keys and FFI all frozen for good.
/// One lock cannot be taken in two orders, and the queue is touched a handful
/// of times a second, so there was never anything to gain from the finer grain.
struct QueueState {
    tracks: Vec<CxxTrackMetadata>,
    original_tracks: Vec<CxxTrackMetadata>,
    current_index: usize,
    repeat_mode: i32, // 0=off, 1=all, 2=one
    shuffle: bool,
}

pub struct TrackQueue {
    state: RwLock<QueueState>,
}

impl TrackQueue {
    pub fn new() -> Self {
        Self {
            state: RwLock::new(QueueState {
                tracks: Vec::new(),
                original_tracks: Vec::new(),
                current_index: 0,
                repeat_mode: 0,
                shuffle: false,
            }),
        }
    }

    pub fn set_queue(&self, mut tracks: Vec<CxxTrackMetadata>, start_index: usize) {
        let mut s = self.state.write();

        // Resolve the requested row against the order the caller sees. With shuffle
        // on, the played list is a permutation of that order, and indexing the
        // shuffled vector with the original position started some other track.
        let wanted = tracks.get(start_index).map(|t| t.id.clone());

        s.original_tracks = tracks.clone();
        if s.shuffle {
            tracks.shuffle(&mut thread_rng());
        }
        s.tracks = tracks;

        s.current_index = wanted
            .as_ref()
            .and_then(|id| s.tracks.iter().position(|t| &t.id == id))
            .unwrap_or(0);
    }

    pub fn current_track(&self) -> Option<CxxTrackMetadata> {
        let s = self.state.read();
        s.tracks.get(s.current_index).cloned()
    }

    pub fn next_track(&self) -> Option<CxxTrackMetadata> {
        let mut s = self.state.write();
        if s.tracks.is_empty() {
            return None;
        }
        let repeat = s.repeat_mode;
        if repeat == 2 {
            // Repeat one - stay on current track
            s.tracks.get(s.current_index).cloned()
        } else if s.current_index + 1 < s.tracks.len() {
            s.current_index += 1;
            s.tracks.get(s.current_index).cloned()
        } else if repeat == 1 {
            // Repeat all - go to first
            s.current_index = 0;
            s.tracks.first().cloned()
        } else {
            None
        }
    }

    pub fn peek_next_track(&self) -> Option<CxxTrackMetadata> {
        let s = self.state.read();
        if s.tracks.is_empty() {
            return None;
        }
        if s.repeat_mode == 2 {
            s.tracks.get(s.current_index).cloned()
        } else if s.current_index + 1 < s.tracks.len() {
            s.tracks.get(s.current_index + 1).cloned()
        } else if s.repeat_mode == 1 {
            s.tracks.first().cloned()
        } else {
            None
        }
    }

    pub fn previous_track(&self) -> Option<CxxTrackMetadata> {
        let mut s = self.state.write();
        if s.tracks.is_empty() {
            return None;
        }
        if s.current_index > 0 {
            s.current_index -= 1;
        } else {
            // At the head, stay put: the previous key is not a request to wrap into
            // the middle of the queue.
            s.current_index = 0;
        }
        s.tracks.get(s.current_index).cloned()
    }

    pub fn list(&self) -> Vec<CxxTrackMetadata> {
        self.state.read().tracks.clone()
    }

    pub fn set_shuffle(&self, enabled: bool) {
        let mut s = self.state.write();
        s.shuffle = enabled;

        let current = s.tracks.get(s.current_index).cloned();
        // Rebuild the played list from the untouched original order, whichever way
        // the toggle goes, so shuffling twice does not shuffle a shuffle.
        let restored = s.original_tracks.clone();
        s.tracks = restored;

        if enabled {
            s.tracks.shuffle(&mut thread_rng());
        }

        // The track that is playing keeps its position in both directions, so
        // toggling shuffle never jumps to another song mid-playback.
        if let Some(current) = current {
            if let Some(pos) = s.tracks.iter().position(|t| t.id == current.id) {
                let limit = s.tracks.len().saturating_sub(1);
                s.current_index = pos.min(limit);
            }
        }

        // Never leave the cursor past the end of the list.
        if s.current_index >= s.tracks.len() {
            s.current_index = 0;
        }
    }

    pub fn set_repeat_mode(&self, mode: i32) {
        self.state.write().repeat_mode = mode.clamp(0, 2);
    }

    /// Whether the queue is shuffled, as the desktop needs to show it.
    pub fn shuffle(&self) -> bool {
        self.state.read().shuffle
    }

    /// 0 = off, 1 = repeat the queue, 2 = repeat one track.
    pub fn repeat_mode(&self) -> i32 {
        self.state.read().repeat_mode
    }
}

impl Default for TrackQueue {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn track(id: &str) -> CxxTrackMetadata {
        CxxTrackMetadata {
            id: id.to_string(),
            title: id.to_string(),
            ..Default::default()
        }
    }

    fn ids(tracks: &[CxxTrackMetadata]) -> Vec<String> {
        tracks.iter().map(|t| t.id.clone()).collect()
    }

    /// Five tracks named t0..t4, queued in order, cursor on t0.
    fn queue_of_five() -> TrackQueue {
        let q = TrackQueue::new();
        q.set_queue(
            vec![
                track("t0"),
                track("t1"),
                track("t2"),
                track("t3"),
                track("t4"),
            ],
            0,
        );
        q
    }

    #[test]
    fn empty_queue_never_yields_a_track() {
        let q = TrackQueue::new();
        assert!(q.current_track().is_none());
        assert!(q.next_track().is_none());
        assert!(q.previous_track().is_none());
        assert!(q.peek_next_track().is_none());
    }

    #[test]
    fn walks_forward_and_stops_at_the_end() {
        let q = queue_of_five();
        assert_eq!(q.next_track().map(|t| t.id), Some("t1".into()));
        assert_eq!(q.next_track().map(|t| t.id), Some("t2".into()));
        for _ in 0..10 {
            q.next_track();
        }
        // Repeat is off, so the cursor must stop at the last track rather than
        // wrap into the middle of the queue.
        assert_eq!(q.current_track().map(|t| t.id), Some("t4".into()));
        assert!(q.next_track().is_none());
        assert_eq!(q.current_track().map(|t| t.id), Some("t4".into()));
    }

    #[test]
    fn previous_stays_at_the_head() {
        let q = queue_of_five();
        assert_eq!(q.previous_track().map(|t| t.id), Some("t0".into()));
        assert_eq!(q.current_track().map(|t| t.id), Some("t0".into()));
    }

    #[test]
    fn repeat_all_wraps_to_the_first_track() {
        let q = queue_of_five();
        q.set_repeat_mode(1);
        for _ in 0..4 {
            q.next_track();
        }
        assert_eq!(q.current_track().map(|t| t.id), Some("t4".into()));
        assert_eq!(q.next_track().map(|t| t.id), Some("t0".into()));
    }

    #[test]
    fn repeat_one_never_leaves_the_track() {
        let q = queue_of_five();
        q.set_repeat_mode(2);
        for _ in 0..5 {
            assert_eq!(q.next_track().map(|t| t.id), Some("t0".into()));
        }
        assert_eq!(q.peek_next_track().map(|t| t.id), Some("t0".into()));
    }

    #[test]
    fn repeat_mode_is_clamped() {
        let q = queue_of_five();
        q.set_repeat_mode(9);
        assert_eq!(q.repeat_mode(), 2);
        q.set_repeat_mode(-3);
        assert_eq!(q.repeat_mode(), 0);
    }

    #[test]
    fn start_index_picks_the_requested_row_when_shuffle_is_off() {
        let q = TrackQueue::new();
        q.set_queue(
            vec![
                track("t0"),
                track("t1"),
                track("t2"),
                track("t3"),
                track("t4"),
            ],
            3,
        );
        assert_eq!(q.current_track().map(|t| t.id), Some("t3".into()));
    }

    #[test]
    fn start_index_still_picks_the_requested_row_when_shuffle_is_on() {
        // The interface hands over the row's position in the original order while
        // the played list is a permutation of it. Indexing the shuffled vector with
        // that position used to start an unrelated track.
        let q = TrackQueue::new();
        q.set_shuffle(true);
        q.set_queue(
            vec![
                track("t0"),
                track("t1"),
                track("t2"),
                track("t3"),
                track("t4"),
            ],
            3,
        );
        assert_eq!(q.current_track().map(|t| t.id), Some("t3".into()));
        // ...and the queue really is a permutation of the same five tracks.
        let mut seen = ids(&q.list());
        seen.sort();
        assert_eq!(seen, vec!["t0", "t1", "t2", "t3", "t4"]);
    }

    #[test]
    fn out_of_range_start_index_falls_back_to_the_first_row() {
        let q = TrackQueue::new();
        q.set_queue(vec![track("t0"), track("t1")], 99);
        assert_eq!(q.current_track().map(|t| t.id), Some("t0".into()));
        q.set_queue(vec![track("t0"), track("t1")], 1);
        assert_eq!(q.current_track().map(|t| t.id), Some("t1".into()));
    }

    #[test]
    fn toggling_shuffle_keeps_the_playing_track() {
        let q = queue_of_five();
        for _ in 0..3 {
            q.next_track();
        }
        assert_eq!(q.current_track().map(|t| t.id), Some("t3".into()));

        q.set_shuffle(true);
        assert_eq!(q.current_track().map(|t| t.id), Some("t3".into()));
        assert_eq!(q.list().len(), 5);
        assert!(q.shuffle());

        q.set_shuffle(false);
        assert_eq!(q.current_track().map(|t| t.id), Some("t3".into()));
        assert_eq!(
            ids(&q.list()),
            ids(&[
                track("t0"),
                track("t1"),
                track("t2"),
                track("t3"),
                track("t4")
            ])
        );
        assert!(!q.shuffle());
    }

    #[test]
    fn shuffle_round_trip_on_an_empty_queue_is_harmless() {
        let q = TrackQueue::new();
        q.set_shuffle(true);
        q.set_shuffle(false);
        assert!(q.list().is_empty());
        assert!(q.current_track().is_none());
        assert!(q.next_track().is_none());
    }
}
