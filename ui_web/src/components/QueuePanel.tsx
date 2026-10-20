import { useCallback, useEffect, useRef } from "react";
import { X, MoreHorizontal, ChevronUp, ListMusic } from "lucide-react";
import type { TrackMeta } from "@/lib/types";
import { cn } from "@/lib/cn";
import { formatTime } from "@/lib/lyrics";
import { usePlayer } from "@/store";
import { Artwork } from "@/components/Toolbar";

export function QueuePanel() {
  const open = usePlayer((s) => s.queueOpen);
  const setOpen = usePlayer((s) => s.setQueueOpen);
  const queue = usePlayer((s) => s.queue);
  const current = usePlayer((s) => s.current);
  const playQueueIndex = usePlayer((s) => s.playQueueIndex);
  const clearQueue = usePlayer((s) => s.clearQueue);
  const openMenu = usePlayer((s) => s.openMenu);

  const panelRef = useRef<HTMLDivElement>(null);
  const isNarrow = typeof window !== "undefined" && window.innerWidth < 1200;

  const handleEscape = useCallback((e: KeyboardEvent) => {
    if (e.key === "Escape") setOpen(false);
  }, [setOpen]);

  useEffect(() => {
    if (!open || !isNarrow) return;
    window.addEventListener("keydown", handleEscape);
    return () => window.removeEventListener("keydown", handleEscape);
  }, [open, isNarrow, handleEscape]);

  useEffect(() => {
    if (open && panelRef.current) {
      const focusable = panelRef.current.querySelector<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      focusable?.focus();
    }
  }, [open]);

  if (!open) return null;

  const handleRowClick = (trackId: string, e: React.MouseEvent) => {
    const btn = e.currentTarget as HTMLButtonElement;
    const menuBtn = btn.querySelector('[data-menu-btn="true"]');
    if (menuBtn && menuBtn.contains(e.target as Node)) return;
    const idx = queue.findIndex((t) => t.id === trackId);
    if (idx >= 0) playQueueIndex(idx);
  };

  const handleMenuClick = (track: TrackMeta, rect: DOMRect, e: React.MouseEvent) => {
    e.stopPropagation();
    openMenu({ track, x: rect.left, y: rect.bottom + 6 });
  };

  return (
    <aside
      ref={panelRef}
      className={cn(
        "queue-panel glass-intense backdrop-blur-lg border-l border-glass-border shadow-2xl",
        isNarrow && "floating",
        open && "open",
      )}
      aria-hidden={!open}
      aria-label="Çalma sırası"
      role="region"
    >
      <div className="flex items-center justify-between px-5 pt-5 pb-3 border-b border-glass-border shrink-0">
        <div className="flex items-center gap-3">
          <div className="size-8 rounded-lg bg-white/10 flex items-center justify-center">
            <ListMusic className="size-5 text-accent" />
          </div>
          <div>
            <h2 className="text-[15px] font-bold tracking-tight text-white">Çalma Sırası</h2>
            <p className="text-[11px] text-white/50">{queue.length} parça</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {queue.length > 0 ? (
            <button
              className="btn-glass chip text-xs"
              onClick={(e) => { e.stopPropagation(); clearQueue(); }}
              aria-label="Sırayı temizle"
            >
              Temizle
            </button>
          ) : null}
          <button
            className="btn-glass icon-btn text-white/80 hover:bg-white/10 hover:text-white"
            aria-label="Kuyruğu kapat"
            onClick={(e) => { e.stopPropagation(); setOpen(false); }}
          >
            <X className="size-4" />
          </button>
        </div>
      </div>

      <div className="scroll-thin flex-1 min-h-0 overflow-y-auto pr-2 pb-4">
        {queue.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <ListMusic className="size-12 text-white/10 mb-3" />
            <p className="text-sm text-white/50">Sıra boş. Bir parça çaldığında burada listelenir.</p>
          </div>
        ) : (
          queue.map((track, i) => {
            const active = current?.id === track.id;
            return (
              <div key={`${track.id}-${i}`} className="relative group">
                <button
                  className={cn(
                    "track-row flex items-center gap-3 rounded-xl px-4 py-3 text-left transition-all duration-200",
                    active && "bg-accent/10 border border-accent/30",
                    !active && "hover:bg-white/5",
                  )}
                  onClick={(e) => handleRowClick(track.id, e)}
                  title={`${track.title} — ${track.artist}`}
                >
                  <div className="relative flex-shrink-0">
                    <Artwork src={track.thumbnail} className="size-12 rounded-lg" />
                    {active && (
                      <div className="absolute inset-0 rounded-lg flex items-center justify-center text-white/90">
                        <ListMusic className="size-5" />
                      </div>
                    )}
                    <span className="absolute -right-1 -top-1 z-10 flex size-5 items-center justify-center rounded-full bg-accent text-black font-bold text-[10px]">
                      {i + 1}
                    </span>
                  </div>
                  <div className="min-w-0 flex-1">
                    <span className={cn("block truncate text-[14px] font-medium", active && "text-accent")}>
                      {track.title}
                    </span>
                    <span className="block truncate text-[12px] text-white/60">{track.artist}</span>
                  </div>
                  <span className="text-[11px] tabular-nums text-white/40 whitespace-nowrap">
                    {formatTime(track.duration)}
                  </span>
                </button>
                <button
                  data-menu-btn="true"
                  className="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity duration-200 icon-btn text-white/50 hover:text-white"
                  aria-label="Daha fazla"
                  onClick={(e) => handleMenuClick(track, (e.currentTarget as HTMLElement).getBoundingClientRect(), e)}
                >
                  <MoreHorizontal className="size-4" />
                </button>
              </div>
            );
          })
        )}
      </div>
    </aside>
  );
}