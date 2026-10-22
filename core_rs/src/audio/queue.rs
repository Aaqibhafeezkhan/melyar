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

    /// Add a track to the end of both the played list and the original order.
    ///
    /// The interface's "add to queue" used to touch only its own mirror of the
    /// queue, so the tracks a user queued were drawn and never played: the end
    /// of the song, the media keys and MPRIS all read this list instead.
    pub fn append(&self, track: CxxTrackMetadata) {
        let mut s = self.state.write();
        s.original_tracks.push(track.clone());
        s.tracks.push(track);
    }

    /// Insert a track immediately after the one playing, which is what
    /// "Play next" promises. Appending would put it behind everything that is
    /// already queued, and the toast would be lying.
    pub fn insert_next(&self, track: CxxTrackMetadata) {
        let mut s = self.state.write();
        let at = (s.current_index + 1).min(s.tracks.len());
        s.tracks.insert(at, track.clone());
        // The original order carries no cursor, so this end is the only place
        // that keeps the track no matter which way the next shuffle goes.
        s.original_tracks.push(track);
    }

    /// Remove by position in the played list, keeping the original order in
    /// step so a later shuffle round trip cannot bring the track back.
    pub fn remove(&self, index: usize) -> bool {
        let mut s = self.state.write();
        if index >= s.tracks.len() {
            return false;
        }
        let removed = s.tracks.remove(index);
        if let Some(pos) = s.original_tracks.iter().position(|t| t.id == removed.id) {
            s.original_tracks.remove(pos);
        }
        if index < s.current_index {
            // Everything before the cursor shifted one place left.
            s.current_index -= 1;
        }
        if s.current_index >= s.tracks.len() {
            s.current_index = s.tracks.len().saturating_sub(1);
        }
        true
    }

    pub fn clear(&self) {
        let mut s = self.state.write();
        s.tracks.clear();
        s.original_tracks.clear();
        s.current_index = 0;
    }

    /// Point the cursor at the track the interface just started from the queue.
    /// Without this the end of a clicked track advanced from wherever the core
    /// last happened to be, so picking row five skipped to row six of some
    /// other place in the list.
    pub fn set_current_index(&self, index: usize) -> bool {
        let mut s = self.state.write();
        if index >= s.tracks.len() {
            return false;
        }
        s.current_index = index;
        true
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

    #[test]
    fn appended_tracks_are_played_by_auto_advance() {
        // The interface queues a track while an album is playing. The end of the
        // album has to reach it, which only happens if the queue the core reads
        // was told about it.
        let q = TrackQueue::new();
        q.set_queue(vec![track("a"), track("b")], 0);
        q.append(track("c"));
        assert_eq!(ids(&q.list()), vec!["a", "b", "c"]);
        assert_eq!(q.next_track().map(|t| t.id), Some("b".into()));
        assert_eq!(q.next_track().map(|t| t.id), Some("c".into()));
    }

    #[test]
    fn insert_next_lands_after_the_playing_track() {
        let q = TrackQueue::new();
        q.set_queue(vec![track("a"), track("b"), track("c")], 1); // playing b
        q.insert_next(track("x"));
        assert_eq!(ids(&q.list()), vec!["a", "b", "x", "c"]);
        assert_eq!(q.current_track().map(|t| t.id), Some("b".into()));
        assert_eq!(q.next_track().map(|t| t.id), Some("x".into()));
    }

    #[test]
    fn insert_next_on_an_empty_queue_starts_it() {
        let q = TrackQueue::new();
        q.insert_next(track("a"));
        assert_eq!(ids(&q.list()), vec!["a"]);
        assert_eq!(q.current_track().map(|t| t.id), Some("a".into()));
    }

    #[test]
    fn removing_a_track_keeps_the_cursor_on_the_same_song() {
        let q = TrackQueue::new();
        q.set_queue(vec![track("a"), track("b"), track("c"), track("d")], 2); // playing c
        assert!(q.remove(0));
        // "a" went, so the cursor must move left or it would sit on "d".
        assert_eq!(q.current_track().map(|t| t.id), Some("c".into()));
        assert_eq!(ids(&q.list()), vec!["b", "c", "d"]);
    }

    #[test]
    fn removing_the_playing_track_advances_to_the_next_one() {
        let q = TrackQueue::new();
        q.set_queue(vec![track("a"), track("b")], 0);
        assert!(q.remove(0));
        assert_eq!(q.current_track().map(|t| t.id), Some("b".into()));
    }

    #[test]
    fn removed_tracks_do_not_return_after_a_shuffle_round_trip() {
        let q = TrackQueue::new();
        q.set_queue(vec![track("a"), track("b"), track("c")], 0);
        q.append(track("d"));
        assert!(q.remove(2));
        q.set_shuffle(true);
        q.set_shuffle(false);
        let mut seen = ids(&q.list());
        seen.sort();
        assert_eq!(seen, vec!["a", "b", "d"]);
    }

    #[test]
    fn clearing_empties_both_orders_and_the_cursor() {
        let q = queue_of_five();
        for _ in 0..3 {
            q.next_track();
        }
        q.clear();
        assert!(q.list().is_empty());
        assert!(q.current_track().is_none());
        assert!(q.next_track().is_none());
        // A cleared queue is a usable queue, not a stranded cursor.
        q.set_queue(vec![track("fresh")], 0);
        assert_eq!(q.current_track().map(|t| t.id), Some("fresh".into()));
    }

    #[test]
    fn removing_past_the_end_is_refused() {
        let q = queue_of_five();
        assert!(!q.remove(5));
        assert!(!q.remove(99));
        assert_eq!(q.list().len(), 5);
        let empty = TrackQueue::new();
        assert!(!empty.remove(0));
    }
}
