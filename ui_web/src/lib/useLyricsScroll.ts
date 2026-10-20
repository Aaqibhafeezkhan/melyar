import { useCallback, useEffect, useRef } from "react";
import { usePlayer } from "@/store";

/**
 * Auto-centers the active lyric line while the user is not manually scrolling.
 * - Pauses auto-scroll during manual scroll; resumes after a quiet period (3s).
 * - Only scrolls when auto-follow is enabled, the scroller is measured, and a
 *   valid active line exists. Never scrolls the whole window — only the lyrics
 *   container.
 * - Exposes `scrollToActive` (used by the "Çalan satıra dön" button) which
 *   recenters the active line and re-enables auto-follow.
 * Returns a ref to attach to the lyrics scroller element plus `scrollToActive`.
 */
const QUIET_MS = 3000;

export function useLyricsScroll(enabled: boolean, active: number) {
  const autoFollow = usePlayer((s) => s.lyricsAutoFollow);
  const setAutoFollow = usePlayer((s) => s.setLyricsAutoFollow);
  const setUserScrolling = usePlayer((s) => s.setLyricsUserScrolling);

  const scrollerRef = useRef<HTMLDivElement>(null);
  const userScrollingRef = useRef(false);
  let resetTimer: ReturnType<typeof setTimeout> | null = null;

  const scrollToActive = useCallback(() => {
    if (active < 0) return;
    const el = scrollerRef.current;
    if (!el) return;
    const lineEl = el.querySelector<HTMLElement>('[data-active="true"]');
    if (lineEl) {
      lineEl.scrollIntoView({ block: "center", behavior: "smooth" });
    }
    setUserScrolling(false);
    setAutoFollow(true);
  }, [active, setAutoFollow, setUserScrolling]);

  // Pause auto-scroll while the user is manually scrolling; resume after a quiet period.
  useEffect(() => {
    const el = scrollerRef.current;
    if (!el) return undefined;
    const onScroll = () => {
      userScrollingRef.current = true;
      setUserScrolling(true);
      if (resetTimer) clearTimeout(resetTimer);
      resetTimer = setTimeout(() => {
        userScrollingRef.current = false;
        setUserScrolling(false);
      }, QUIET_MS);
    };
    el.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      el.removeEventListener("scroll", onScroll);
      if (resetTimer) clearTimeout(resetTimer);
    };
  }, [setUserScrolling]);

  // Scroll the active line into view when playback advances (or a line is tapped).
  useEffect(() => {
    if (!enabled || !autoFollow || active < 0 || userScrollingRef.current) return;
    const el = scrollerRef.current;
    if (!el || el.clientHeight === 0) return;
    const lineEl = el.querySelector<HTMLElement>('[data-active="true"]');
    if (lineEl) {
      lineEl.scrollIntoView({ block: "center", behavior: "smooth" });
    }
  }, [enabled, autoFollow, active]);

  return { ref: scrollerRef, scrollToActive };
}
