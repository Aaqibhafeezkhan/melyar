import { useCallback, useEffect, useRef, useState } from "react";
import {
  Mic2,
  Pause,
  Play,
  Repeat,
  Repeat1,
  Shuffle,
  SkipBack,
  SkipForward,
  ListMusic,
  Volume1,
  Volume2,
  VolumeX,
} from "lucide-react";
import { cn } from "@/lib/cn";
import { formatTime } from "@/lib/lyrics";
import { usePlayer } from "@/store";
import { PlayPauseMorph, GlassSlider } from "@/components/GlassComponents";
import type { TrackMeta } from "@/lib/types";
import { t, useLocale } from "@/lib/i18n";

export function Artwork({ src, alt, className }: { src?: string; alt?: string; className?: string }) {
  return (
    <div className={cn("cover shrink-0", className)}>
      {src ? (
        <img src={src} alt={alt ?? ""} draggable={false} className="h-full w-full object-cover" loading="lazy" />
      ) : (
        <div className="cover-fallback">
          <svg viewBox="0 0 64 64" className="size-1/3 opacity-70">
            <path d="M20 44V20l14 8 14-8v24" fill="none" stroke="currentColor" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
      )}
    </div>
  );
}

function WaveBars() {
  const playing = usePlayer((s) => s.playing);
  if (!playing) return null;
  return (
    <div className="eq-bars flex items-end gap-1 h-4">
      {[1, 2, 3, 4].map((i) => (
        <i key={i} className="rounded-full bg-accent animate-[eqb_0.8s_ease-in-out_infinite_alternate]" style={{ height: `${30 + i * 15}%`, animationDelay: `${i * 0.15}s` }} />
      ))}
    </div>
  );
}

function MiniTimeline() {
  const position = usePlayer((s) => s.position);
  const duration = usePlayer((s) => s.duration);
  const seekRatio = usePlayer((s) => s.seekRatio);
  const drag = useRef(false);
  const barRef = useRef<HTMLDivElement>(null);

  const ratio = duration > 0 ? Math.min(1, position / duration) : 0;

  const pointRatio = (clientX: number) => {
    const rect = barRef.current?.getBoundingClientRect();
    if (!rect || rect.width === 0) return 0;
    return Math.min(1, Math.max(0, (clientX - rect.left) / rect.width));
  };

  const handlePointerDown = (e: React.PointerEvent) => {
    drag.current = true;
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    seekRatio(pointRatio(e.clientX));
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (drag.current) seekRatio(pointRatio(e.clientX));
  };

  const handlePointerUp = () => {
    drag.current = false;
  };

  return (
    <div
      ref={barRef}
      className="mini-timeline h-1 bg-white/10 rounded-full cursor-pointer overflow-hidden"
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerLeave={handlePointerUp}
      role="slider"
      aria-label="Oynatma Konumu"
      aria-valuemin={0}
      aria-valuemax={Math.floor(duration)}
      aria-valuenow={Math.floor(position)}
      tabIndex={0}
    >
      <div className="h-full bg-gradient-to-r from-accent to-[#d61d33] shadow-[0_0_8px_rgba(250,35,59,0.6)]"
        style={{ width: `${ratio * 100}%` }}
      />
    </div>
  );
}

function Transport() {
  useLocale();
  const playing = usePlayer((s) => s.playing);
  const shuffle = usePlayer((s) => s.shuffle);
  const repeat = usePlayer((s) => s.repeat);
  const toggle = usePlayer((s) => s.toggle);
  const next = usePlayer((s) => s.next);
  const prev = usePlayer((s) => s.prev);
  const toggleShuffle = usePlayer((s) => s.toggleShuffle);
  const cycleRepeat = usePlayer((s) => s.cycleRepeat);

  return (
    <div className="flex items-center gap-1">
      <button className="btn-glass transport-btn" data-active={shuffle} aria-label={t("toolbar.shuffle")} onClick={toggleShuffle}>
        <Shuffle className={cn("size-[17px]", shuffle && "text-accent-text")} />
      </button>
      <button className="btn-glass transport-btn" aria-label={t("toolbar.prev")} onClick={prev}>
        <SkipBack className="size-[19px] fill-current" />
      </button>
      <PlayPauseMorph
        size="main"
        playing={playing}
        onToggle={toggle}
      />
      <button className="btn-glass transport-btn" aria-label="Sonraki" onClick={next}>
        <SkipForward className="size-[19px] fill-current" />
      </button>
      <button className="btn-glass transport-btn" data-active={repeat !== 0} aria-label="Tekrar" onClick={cycleRepeat}>
        {repeat === 2 ? <Repeat1 className="size-[17px] text-accent-text" /> : <Repeat className={cn("size-[17px]", repeat === 1 && "text-accent-text")} />}
      </button>
    </div>
  );
}

function MiniTrackCapsule() {
  useLocale();
  const current = usePlayer((s) => s.current);
  const position = usePlayer((s) => s.position);
  const duration = usePlayer((s) => s.duration);
  const playing = usePlayer((s) => s.playing);
  const setExpandedPlayerOpen = usePlayer((s) => s.setExpandedPlayerOpen);
  const track: TrackMeta | null = current;

  const ratio = duration > 0 ? Math.min(1, position / duration) : 0;

  const handleCapsuleClick = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement;
    if (target.closest('.mini-timeline') || target.closest('button')) return;
    setExpandedPlayerOpen(true);
  };

  return (
    <div
      className="mini-track-capsule cursor-pointer group"
      onClick={handleCapsuleClick}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); setExpandedPlayerOpen(true); } }}
      aria-label={t("toolbar.expand")}
    >
      <Artwork src={track?.thumbnail} className="mini-track-artwork" />
      <div className="mini-track-info">
        <p className="mini-track-title">{track ? track.title : "Melyar"}</p>
        <p className="mini-track-artist">{track ? track.artist : t("toolbar.noTrack")}</p>
        <WaveBars />
      </div>
      <div className="flex items-center gap-2">
        <span className="mini-track-time">{formatTime(position)} / {formatTime(duration)}</span>
        <MiniTimeline />
      </div>
    </div>
  );
}

export function Toolbar() {
  useLocale();
  const volume = usePlayer((s) => s.volume);
  const muted = usePlayer((s) => s.muted);
  const setVolume = usePlayer((s) => s.setVolume);
  const toggleMute = usePlayer((s) => s.toggleMute);
  const queueOpen = usePlayer((s) => s.queueOpen);
  const setQueueOpen = usePlayer((s) => s.setQueueOpen);
  const setLyricsOpen = usePlayer((s) => s.setLyricsOpen);
  const lyricsOpen = usePlayer((s) => s.lyricsOpen);

  const VolIcon = muted || volume === 0 ? VolumeX : volume < 0.5 ? Volume1 : Volume2;

  return (
    <header className="toolbar glass-elevated backdrop-blur-lg border-b border-glass-border z-20">
      <Transport />

      <div className="mx-auto flex min-w-0 max-w-[640px] flex-1 justify-center px-4">
        <MiniTrackCapsule />
      </div>

      <div className="flex items-center gap-2">
        <button
          className="btn-glass icon-btn"
          data-active={lyricsOpen}
          aria-label={lyricsOpen ? t("toolbar.lyrics.close") : t("toolbar.lyrics.open")}
          onClick={() => setLyricsOpen(!lyricsOpen)}
        >
          <Mic2 className="size-5" />
        </button>
        <button
          className="btn-glass icon-btn"
          data-active={queueOpen}
          aria-label={t("toolbar.queue")}
          onClick={() => setQueueOpen(!queueOpen)}
        >
          <ListMusic className="size-5" />
        </button>
        <button className="btn-glass icon-btn hidden sm:grid" aria-label={muted ? t("toolbar.mute.off") : t("toolbar.mute.on")} onClick={toggleMute}>
          <VolIcon className="size-5" />
        </button>
        <GlassSlider
          className="hidden w-28 lg:block"
          value={muted ? 0 : volume}
          onChange={setVolume}
          min={0}
          max={1}
          step={0.01}
          showTooltip
          formatTooltip={(v) => `${Math.round(v * 100)}%`}
          aria-label={t("toolbar.volume")}
        />
      </div>
    </header>
  );
}

export { MiniTimeline };