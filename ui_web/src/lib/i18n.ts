import { useSyncExternalStore } from "react";
import { en } from "@/locales/en";
import { tr } from "@/locales/tr";

export type Locale = "en" | "tr";

export const LOCALES: { code: Locale; label: string }[] = [
  { code: "en", label: "English" },
  { code: "tr", label: "Türkçe" },
];

const MESSAGES: Record<Locale, Record<string, string>> = { en, tr };

const STORAGE_KEY = "melyar.locale";
const FALLBACK: Locale = "en";

function isLocale(value: unknown): value is Locale {
  return value === "en" || value === "tr";
}

function detect(): Locale {
  // An explicit ?lang= wins, so a launcher can force a language.
  try {
    const forced = new URLSearchParams(window.location.search).get("lang");
    if (isLocale(forced)) return forced;
  } catch {
    // No window (tests, SSR) - fall through.
  }

  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (isLocale(stored)) return stored;
  } catch {
    // Private mode or a locked-down profile - fall through to the navigator.
  }

  const nav = typeof navigator !== "undefined" ? navigator.language : "";
  if (nav.toLowerCase().startsWith("tr")) return "tr";
  return FALLBACK;
}

let current: Locale = detect();
const listeners = new Set<() => void>();

function emit() {
  for (const listener of listeners) listener();
}

export function getLocale(): Locale {
  return current;
}

export function setLocale(locale: Locale) {
  if (!isLocale(locale) || locale === current) return;
  current = locale;
  try {
    localStorage.setItem(STORAGE_KEY, locale);
  } catch {
    // Persisting is best effort; the session still switches language.
  }
  document.documentElement.lang = locale;
  emit();
}

/**
 * Translate a key. Unknown keys fall back to the key itself so a missing
 * entry is visible rather than silently blank.
 *
 * Placeholders use {name} and are replaced from `params`.
 */
export function t(key: string, params?: Record<string, string | number>): string {
  const template = MESSAGES[current]?.[key] ?? MESSAGES[FALLBACK]?.[key] ?? key;
  if (!params) return template;
  return template.replace(/\{(\w+)\}/g, (match, name: string) =>
    name in params ? String(params[name]) : match,
  );
}

/** Subscribe to locale changes. Re-renders the component when it happens. */
export function useLocale(): Locale {
  return useSyncExternalStore(
    (listener) => {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    getLocale,
    getLocale,
  );
}
