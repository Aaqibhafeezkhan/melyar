import { usePlayer } from "@/store";
import { register } from "@/lib/registry";
import type { RepeatMode, TrackMeta } from "@/lib/types";

let bridgeInstance: any = null;

function clamp01(v: number) {
  return Math.max(0, Math.min(1, Number.isFinite(v) ? v : 0));
}

function toTracks(raw: unknown): TrackMeta[] {
  if (!Array.isArray(raw)) return [];
  const out: TrackMeta[] = [];
  for (const item of raw) {
    if (!item || typeof item.id !== "string" || !item.id) continue;
    out.push(
      register({
        id: item.id,
        title: typeof item.title === "string" ? item.title : "",
        artist: typeof item.artist === "string" ? item.artist : "",
        album: typeof item.album === "string" ? item.album : "",
        duration: typeof item.duration === "number" ? item.duration : 0,
        thumbnail: typeof item.thumbnail === "string" ? item.thumbnail : "",
      }),
    );
  }
  return out;
}

export function getBridge() {
  return bridgeInstance;
}

export function initBridge() {
  if (typeof window === "undefined") return;
  const start = () => {
    const transport = (window.qt as any)?.webChannelTransport;
    if (!transport || typeof window.QWebChannel !== "function") {
      console.error("[Melyar] webChannelTransport or QWebChannel missing (browser mode?)");
      usePlayer.getState().patch({ bridgeError: "native" });
      return;
    }
    new window.QWebChannel(transport, (channel: any) => {
      const b = channel?.objects?.bridge;
      if (!b) {
        console.error("[Melyar] channel.objects.bridge not found");
        usePlayer.getState().patch({ bridgeError: "bridge" });
        return;
      }
      bridgeInstance = b;
      window.bridge = b;
      console.log("[Melyar] Native bridge connected");

      const s = usePlayer.getState();
      s.patch({
        volume: clamp01((b.volume ?? 80) / 100),
        shuffle: Boolean(b.shuffleMode),
        repeat: (Math.max(0, Math.min(2, Number(b.repeatMode) || 0)) as RepeatMode),
        booted: true,
      });

      // ---- signals: connected exactly once; handlers never re-connect ----
      b.progressUpdated.connect((current: number, total: number) => {
        const st = usePlayer.getState();
        // Ignore position updates from a different track (race between
        // playTrack setting current and currentTrackChanged firing).
        if (st.current && st.current.id !== b.currentTrackId) return;
        usePlayer.setState({
          position: Number(current) || 0,
          duration: Number(total) > 0 ? Number(total) : st.duration,
        });
        if (st.lyricsOpen) void 0; // lyric index derives from position reactively
      });

      b.playbackStateChanged.connect((playing: boolean) => {
        usePlayer.setState({ playing: Boolean(playing) });
      });

      b.currentTrackChanged.connect(() => {
        console.log('[Melyar] currentTrackChanged fired, id=', b.currentTrackId);
        const id: string = b.currentTrackId || "";
        if (!id) return;
        const meta = register({
          id,
          title: b.currentTitle || "",
          artist: b.currentArtist || "",
          album: b.currentAlbum || "",
          duration: Number(b.currentDuration) || 0,
          thumbnail: b.currentThumbnail || "",
        });
        // New request id guards against stale polls overwriting a newer track's lyrics.
        const requestId = Date.now();
        usePlayer.setState({
          current: meta,
          playing: Boolean(b.isPlaying),
          duration: Number(b.currentDuration) || 0,
          position: 0,
          lyricsRaw: null,
          lyricsRequestId: requestId,
          lyricsAutoFollow: true, // fresh track => re-center on the playing line
        });
        if (typeof b.fetchLyrics === "function") {
          b.fetchLyrics(id);
          let polls = 0;
          const poll = () => {
            // Ignore this poll if a newer track has already requested lyrics.
            if (usePlayer.getState().lyricsRequestId !== requestId) return;
            const lrc = b.currentLyrics;
            if (lrc && lrc.trim()) {
              usePlayer.getState().patch({ lyricsRaw: lrc });
            } else if (polls < 30) {
              polls++;
              setTimeout(poll, 500);
            }
          };
          setTimeout(poll, 500);
        } else {
          console.log('[Melyar] fetchLyrics NOT a function');
        }
      });

      b.searchResultsChanged.connect(() => {
        usePlayer.setState({ results: toTracks(b.searchResults), searching: false });
      });

      b.favoritesChanged.connect(() => {
        usePlayer.setState({ liked: toTracks(b.favorites) });
      });

      b.historyChanged.connect(() => {
        usePlayer.setState({ history: toTracks(b.history) });
      });

      b.queueChanged.connect(() => {
        usePlayer.setState({ queue: toTracks(b.queue) });
      });

      b.volumeChanged.connect(() => {
        usePlayer.setState({ volume: clamp01((b.volume ?? 80) / 100) });
      });

      b.lyricsChanged.connect(() => {
        // Guard against stale lyrics from a previous track overwriting the
        // current track's lyrics (race with currentTrackChanged + polling).
        const st = usePlayer.getState();
        if (st.lyricsRequestId !== null && st.lyricsRequestId !== Date.now()) return;
        usePlayer.setState({ lyricsRaw: (b.currentLyrics || "") || null });
      });

      b.shuffleModeChanged.connect(() => {
        usePlayer.setState({ shuffle: Boolean(b.shuffleMode) });
      });

      b.repeatModeChanged.connect(() => {
        usePlayer.setState({ repeat: Math.max(0, Math.min(2, Number(b.repeatMode) || 0)) as RepeatMode });
      });

      // ---- initial data pulls (signals already connected: nothing is lost) ----
      if (typeof b.loadFavorites === "function") b.loadFavorites();
      if (typeof b.loadHistory === "function") b.loadHistory();

      // Restore current track if the core already has one
      if (b.currentTrackId) {
        const meta = register({
          id: b.currentTrackId,
          title: b.currentTitle || "",
          artist: b.currentArtist || "",
          album: b.currentAlbum || "",
          duration: Number(b.currentDuration) || 0,
          thumbnail: b.currentThumbnail || "",
        });
        usePlayer.setState({
          current: meta,
          playing: Boolean(b.isPlaying),
          duration: Number(b.currentDuration) || 0,
        });
        if (typeof b.fetchLyrics === "function") b.fetchLyrics(b.currentTrackId);
      }

      // ---- automation hooks (used by end-to-end tests) ----
      const w = window as any;
      w.__testSearch = (q: string) => {
        usePlayer.getState().setQuery(q);
        runSearch(q);
      };
      w.__testPlay = (i: number) => {
        const st = usePlayer.getState();
        const t = st.results[i];
        if (t) st.playTrack(t, st.results);
      };
      w.__testLike = (i: number) => {
        const st = usePlayer.getState();
        const t = st.results[i] ?? st.current;
        if (t) st.toggleLike(t);
      };
      w.__testToggle = () => usePlayer.getState().toggle();
      w.__testState = () => {
        const s = usePlayer.getState();
        return {
          results: s.results,
          liked: s.liked,
          queue: s.queue,
          playing: s.playing,
          position: s.position,
          duration: s.duration,
          current: s.current,
          lyricsRaw: s.lyricsRaw,
        };
      };
    });
  };

  if (document.readyState === "loading") {
    window.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }
}

export function runSearch(query: string) {
  const b = bridgeInstance;
  if (!b) return;
  usePlayer.setState({ searching: true });
  b.search(query);
}
