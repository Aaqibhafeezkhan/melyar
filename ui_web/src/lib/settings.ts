import { create } from "zustand";
import { getBridge } from "@/lib/client";
import { getLocale, setLocale as applyLocale, type Locale } from "@/lib/i18n";

export type Theme = "dark" | "light";
export type StreamingQuality = "low" | "medium" | "high" | "lossless";

export type Settings = {
  // Appearance
  theme: Theme;
  accentColor: string;
  compactMode: boolean;
  showAlbumArt: boolean;
  animationsEnabled: boolean;
  // Playback
  crossfadeEnabled: boolean;
  crossfadeDuration: number;
  gaplessPlayback: boolean;
  normalizeVolume: boolean;
  equalizerEnabled: boolean;
  streamingQuality: StreamingQuality;
  autoPlayNext: boolean;
  showNotifications: boolean;
  showLyricsAutomatically: boolean;
  // Advanced
  cacheSize: number;
  // Interface
  language: Locale;
  // Playback preferences that follow the user between sessions
  volume: number;
  shuffle: boolean;
  repeat: number;
  /** The gains of the graphic equaliser, in decibels, one per band. */
  equalizerBands: number[];
};

/** The band centres of the equaliser, in hertz. Mirrors the Rust side. */
export const EQUALIZER_BAND_FREQUENCIES = [
  31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
];

export const DEFAULT_SETTINGS: Settings = {
  theme: "dark",
  accentColor: "#fa233b",
  compactMode: false,
  showAlbumArt: true,
  animationsEnabled: true,
  crossfadeEnabled: false,
  crossfadeDuration: 5,
  gaplessPlayback: true,
  normalizeVolume: false,
  equalizerEnabled: false,
  streamingQuality: "high",
  autoPlayNext: true,
  showNotifications: true,
  showLyricsAutomatically: false,
  cacheSize: 500,
  language: "en",
  volume: 0.8,
  shuffle: false,
  repeat: 0,
  equalizerBands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
};

/** Keys that are stored as numbers or booleans need their type restored. */
const NUMERIC_KEYS = new Set<keyof Settings>([
  "crossfadeDuration",
  "cacheSize",
  "volume",
  "repeat",
]);
const BOOLEAN_KEYS = new Set<keyof Settings>([
  "compactMode",
  "showAlbumArt",
  "animationsEnabled",
  "crossfadeEnabled",
  "gaplessPlayback",
  "normalizeVolume",
  "equalizerEnabled",
  "autoPlayNext",
  "showNotifications",
  "showLyricsAutomatically",
  "shuffle",
]);

const ARRAY_KEYS = new Set<keyof Settings>(["equalizerBands"]);

function coerceArray(raw: unknown, length: number): number[] {
  const values = Array.isArray(raw) ? raw : [];
  const bands: number[] = [];
  for (let i = 0; i < length; i += 1) {
    const value = Number(values[i]);
    bands.push(Number.isFinite(value) ? value : 0);
  }
  return bands;
}

function coerce(key: keyof Settings, raw: unknown): Settings[keyof Settings] {
  if (ARRAY_KEYS.has(key)) {
    const expected = (DEFAULT_SETTINGS[key] as number[]).length;
    return coerceArray(raw, expected) as Settings[keyof Settings];
  }
  if (NUMERIC_KEYS.has(key)) {
    const n = Number(raw);
    return (Number.isFinite(n) ? n : 0) as Settings[keyof Settings];
  }
  if (BOOLEAN_KEYS.has(key)) {
    if (typeof raw === "boolean") return raw as Settings[keyof Settings];
    const s = String(raw).toLowerCase();
    return (s === "true" || s === "1") as Settings[keyof Settings];
  }
  return raw as Settings[keyof Settings];
}

function persist(key: keyof Settings, value: Settings[keyof Settings]) {
  const b = getBridge();
  if (!b || typeof b.saveSetting !== "function") return;
  try {
    const stored = Array.isArray(value) ? JSON.stringify(value) : String(value);
    b.saveSetting(String(key), stored);
  } catch (e) {
    console.error("[Melyar] saveSetting failed", e);
  }
}

/**
 * Apply the equaliser to the audio engine. When it is off, an empty list
 * removes the filter chain.
 */
function applyEqualizer(settings: Settings) {
  const b = getBridge();
  if (!b || typeof b.setEqualizerBands !== "function") return;
  try {
    const bands = settings.equalizerEnabled ? settings.equalizerBands : [];
    b.setEqualizerBands(bands);
  } catch (e) {
    console.error("[Melyar] setEqualizerBands failed", e);
  }
}

/**
 * Apply the settings that are expressed in the DOM. Kept here so that the
 * store, the boot sequence and the settings panel all agree on the result.
 */
export function applySettingsToDocument(settings: Settings) {
  const root = document.documentElement;
  root.setAttribute("data-theme", settings.theme);
  root.setAttribute("data-accent", settings.accentColor);
  root.dataset.compact = settings.compactMode ? "true" : "false";
  root.dataset.animations = settings.animationsEnabled ? "true" : "false";

  // The accent colour drives a handful of custom properties.
  const accent = settings.accentColor;
  root.style.setProperty("--accent", accent);
  root.style.setProperty("--accent-soft", hexToRgba(accent, 0.16));
  root.style.setProperty("--on-accent", readableTextColor(accent));
}

function hexToRgba(hex: string, alpha: number): string {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex.trim());
  if (!m) return `rgba(250, 35, 59, ${alpha})`;
  const r = parseInt(m[1], 16);
  const g = parseInt(m[2], 16);
  const b = parseInt(m[3], 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function readableTextColor(hex: string): string {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex.trim());
  if (!m) return "#ffffff";
  const r = parseInt(m[1], 16);
  const g = parseInt(m[2], 16);
  const b = parseInt(m[3], 16);
  // Rec. 709 luma
  const luma = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
  return luma > 0.6 ? "#101014" : "#ffffff";
}

type SettingsState = {
  settings: Settings;
  loaded: boolean;
  open: boolean;
  load: () => Promise<void>;
  set: <K extends keyof Settings>(key: K, value: Settings[K]) => void;
  reset: () => void;
  setOpen: (open: boolean) => void;
};

export const useSettings = create<SettingsState>()((set, get) => ({
  settings: { ...DEFAULT_SETTINGS },
  loaded: false,
  open: false,

  load: () => {
    return (async () => {
      const b = getBridge();
      let merged: Settings = { ...DEFAULT_SETTINGS };

      if (b && typeof b.loadSettings === "function") {
        try {
          // QWebChannel invocations are asynchronous: the method returns a
          // promise that resolves with the actual return value.
          const raw = await b.loadSettings();
          const parsed = raw ? JSON.parse(raw) : {};
          if (parsed && typeof parsed === "object") {
            for (const key of Object.keys(DEFAULT_SETTINGS) as (keyof Settings)[]) {
              if (key in parsed) {
                (merged as Record<string, unknown>)[key] = coerce(key, parsed[key]);
              }
            }
          }
        } catch (e) {
          console.error("[Melyar] loadSettings failed", e);
        }
      }

      // The language lives in the i18n layer, which owns its own persistence.
      merged.language = getLocale();

      applySettingsToDocument(merged);
      applyEqualizer(merged);
      set({ settings: merged, loaded: true });
    })();
  },
  set: (key, value) => {
    const settings = { ...get().settings, [key]: value };
    applySettingsToDocument(settings);
    set({ settings });

    if (key === "language") {
      applyLocale(value as Locale);
    }
    if (key === "equalizerEnabled" || key === "equalizerBands") {
      applyEqualizer(settings);
    }
    persist(key, value);
  },

  reset: () => {
    const settings = { ...DEFAULT_SETTINGS, language: getLocale() };
    applySettingsToDocument(settings);
    applyEqualizer(settings);
    set({ settings });
    applyLocale(settings.language);
    for (const key of Object.keys(DEFAULT_SETTINGS) as (keyof Settings)[]) {
      persist(key, settings[key]);
    }
  },

  setOpen: (open) => set({ open }),
}));
