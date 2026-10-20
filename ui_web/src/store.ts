import { create } from "zustand";
import { register } from "@/lib/registry";
import { useSettings } from "@/lib/settings";
import type { RepeatMode, TrackMeta, View } from "@/lib/types";
import { t } from "@/lib/i18n";

type Menu = { track: TrackMeta; x: number; y: number } | null;

type State = {
  view: View;
  query: string;
  results: TrackMeta[];
  searching: boolean;
  liked: TrackMeta[];
  history: TrackMeta[];
  queue: TrackMeta[];
  current: TrackMeta | null;
  playing: boolean;
  position: number;
  duration: number;
  volume: number;
  muted: boolean;
  shuffle: boolean;
  repeat: RepeatMode;
  lyricsRaw: string | null;
  lyricsOpen: boolean;
  lyricsAutoFollow: boolean;
  lyricsUserScrolling: boolean;
  lyricsRequestId: number | null;
  queueOpen: boolean;
  expandedPlayerOpen: boolean;
  menu: Menu;
  toast: string | null;
  booted: boolean;
  bridgeError: string | null;
};

type Actions = {
  navigate: (view: View) => void;
  setQuery: (q: string) => void;
  playTrack: (track: TrackMeta, context?: TrackMeta[]) => void;
  toggle: () => void;
  next: () => void;
  prev: () => void;
  seekRatio: (ratio: number) => void;
  seekSec: (sec: number) => void;
  setVolume: (v: number) => void;
  toggleMute: () => void;
  toggleShuffle: () => void;
  cycleRepeat: () => void;
  toggleLike: (track: TrackMeta) => void;
  playNextInQueue: (track: TrackMeta) => void;
  addToQueue: (track: TrackMeta) => void;
  playQueueIndex: (index: number) => void;
  clearQueue: () => void;
  openMenu: (menu: Menu) => void;
  closeMenu: () => void;
  setLyricsOpen: (open: boolean) => void;
  setLyricsAutoFollow: (v: boolean) => void;
  setLyricsUserScrolling: (v: boolean) => void;
  setLyricsRequestId: (id: number | null) => void;
  setQueueOpen: (open: boolean) => void;
  setExpandedPlayerOpen: (open: boolean) => void;
  toastNote: (text: string) => void;
  patch: (partial: Partial<State>) => void;
};

let toastTimer: ReturnType<typeof setTimeout> | undefined;
let lastVolume = 0.8;

function bridge(): any | null {
  return (typeof window !== "undefined" && window.bridge) || null;
}

export const usePlayer = create<State & Actions>()((set, get) => ({
  view: { name: "home" },
  query: "",
  results: [],
  searching: false,
  liked: [],
  history: [],
  queue: [],
  current: null,
  playing: false,
  position: 0,
  duration: 0,
  volume: 0.8,
  muted: false,
  shuffle: false,
  repeat: 0,
  lyricsRaw: null,
  lyricsOpen: false,
  lyricsAutoFollow: true,
  lyricsUserScrolling: false,
  lyricsRequestId: null,
  queueOpen: false,
  expandedPlayerOpen: false,
  menu: null,
  toast: null,
  booted: false,
  bridgeError: null,

  patch: (partial) => set(partial),

  navigate: (view) => set({ view, menu: null }),

  setQuery: (query) => set({ query }),

  playTrack: (track, context) => {
    const b = bridge();
    if (!b) return;
    const metas = context && context.length > 0 ? context : [track];
    const index = Math.max(0, metas.findIndex((t) => t.id === track.id));
    try {
      b.replaceQueue(
        metas.map((t) => ({
          id: t.id,
          title: t.title,
          artist: t.artist,
          album: t.album,
          duration: t.duration,
          thumbnail: t.thumbnail,
        })),
        index,
      );
    } catch (e) {
      console.error("replaceQueue failed", e);
    }
    b.playTrack(track.id);
    set({
      current: register(track),
      playing: true,
      position: 0,
      duration: track.duration || 0,
      menu: null,
    });
  },

  toggle: () => {
    const b = bridge();
    if (!b) return;
    b.togglePlay();
    if (!get().current) return;
  },

  next: () => bridge()?.nextTrack(),
  prev: () => bridge()?.previousTrack(),

  seekRatio: (ratio) => {
    const b = bridge();
    if (!b) return;
    const dur = get().duration || 0;
    const sec = Math.max(0, Math.min(1, ratio)) * dur;
    b.seek(sec);
    set({ position: sec });
  },

  seekSec: (sec) => {
    const b = bridge();
    if (!b) return;
    b.seek(Math.max(0, sec));
    set({ position: Math.max(0, sec) });
  },

  setVolume: (v) => {
    const b = bridge();
    const volume = Math.max(0, Math.min(1, v));
    if (!b) return set({ volume });
    if (volume > 0) lastVolume = volume;
    b.setVolume(volume * 100);
    set({ volume, muted: volume === 0 });
    useSettings.getState().set("volume", volume);
  },

  toggleMute: () => {
    const b = bridge();
    if (!b) return;
    const { muted, volume } = get();
    if (muted || volume === 0) {
      const restore = lastVolume > 0.01 ? lastVolume : 0.5;
      b.setVolume(restore * 100);
      set({ volume: restore, muted: false });
    } else {
      lastVolume = volume;
      b.setVolume(0);
      set({ muted: true });
    }
  },

  toggleShuffle: () => {
    // Compute the next value before calling the bridge: the QWebChannel
    // signal arrives asynchronously, so reading it back right after the call
    // would still return the old mode.
    const next = !get().shuffle;
    bridge()?.toggleShuffle();
    useSettings.getState().set("shuffle", next);
  },

  cycleRepeat: () => {
    const next = (get().repeat + 1) % 3;
    bridge()?.cycleRepeat();
    useSettings.getState().set("repeat", next);
  },

  toggleLike: (track) => {
    const b = bridge();
    if (!b) return;
    const liked = get().liked;
    const isLiked = liked.some((t) => t.id === track.id);
    try {
      b.toggleFavorite(track.id, track.title, track.artist, track.album, track.duration, track.thumbnail);
    } catch (e) {
      console.error("toggleFavorite failed", e);
    }
    set({
      liked: isLiked ? liked.filter((t) => t.id !== track.id) : [track, ...liked],
      toast: isLiked ? t("toast.unliked") : t("toast.liked"),
      menu: null,
    });
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => set({ toast: null }), 1700);
  },

  playNextInQueue: (track) => {
    const b = bridge();
    if (!b) return;
    b.addToQueue(track.id);
    set({ menu: null, toast: t("toast.playNext") });
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => set({ toast: null }), 1700);
  },

  addToQueue: (track) => {
    const b = bridge();
    if (!b) return;
    b.addToQueue(track.id);
    set({ menu: null, toast: t("toast.queued") });
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => set({ toast: null }), 1700);
  },

  playQueueIndex: (index) => {
    const b = bridge();
    if (!b) return;
    const track = get().queue[index];
    if (track) {
      set({ current: track, playing: true, position: 0, queueOpen: false });
    } else {
      set({ queueOpen: false });
    }
    b.playFromQueue(index);
  },

  clearQueue: () => {
    bridge()?.clearQueue();
  },

  openMenu: (menu) => set({ menu }),
  closeMenu: () => set({ menu: null }),
  setLyricsOpen: (lyricsOpen) => set({ lyricsOpen, menu: null }),
  setLyricsAutoFollow: (v) => set({ lyricsAutoFollow: Boolean(v), lyricsUserScrolling: false }),
  setLyricsUserScrolling: (v) => set({ lyricsUserScrolling: Boolean(v) }),
  setLyricsRequestId: (id) => set({ lyricsRequestId: id }),
  setQueueOpen: (queueOpen) => set({ queueOpen }),
  setExpandedPlayerOpen: (expandedPlayerOpen) => set({ expandedPlayerOpen }),

  toastNote: (text) => {
    set({ toast: text });
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => set({ toast: null }), 1700);
  },
}));