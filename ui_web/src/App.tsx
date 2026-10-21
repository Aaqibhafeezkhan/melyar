import { useEffect, useRef } from "react";
import { Sidebar } from "@/components/Sidebar";
import { Toolbar } from "@/components/Toolbar";
import { ContextMenu } from "@/components/ContextMenu";
import { SettingsPanel } from "@/components/SettingsPanel";
import { ImportOverlay } from "@/components/ImportOverlay";
import { QueuePanel } from "@/components/QueuePanel";
import { LyricsOverlay } from "@/components/LyricsOverlay";
import { ExpandedPlayer } from "@/components/ExpandedPlayer";
import { HomeView } from "@/components/views/HomeView";
import { SearchView } from "@/components/views/SearchView";
import {
  AlbumDetailView,
  AlbumsView,
  ArtistDetailView,
  ArtistsView,
  HistoryView,
  LikedView,
  SongsView,
} from "@/components/views/LibraryViews";
import { usePlayer } from "@/store";
import { useSettings } from "@/lib/settings";
import { cn } from "@/lib/cn";

function Stage() {
  const view = usePlayer((s) => s.view);
  switch (view.name) {
    case "home":
      return <HomeView />;
    case "search":
      return <SearchView />;
    case "songs":
      return <SongsView />;
    case "albums":
      return <AlbumsView />;
    case "artists":
      return <ArtistsView />;
    case "liked":
      return <LikedView />;
    case "history":
      return <HistoryView />;
    case "album":
      return <AlbumDetailView albumKey={view.key} />;
    case "artist":
      return <ArtistDetailView artistKey={view.key} />;
    default:
      return <HomeView />;
  }
}

function Toast() {
  const toast = usePlayer((s) => s.toast);
  if (!toast) return null;
  return <div className="toast">{toast}</div>;
}

// Overlay portal for proper stacking
function OverlayPortal({ children }: { children: React.ReactNode }) {
  return <div className="overlay-portal">{children}</div>;
}

export default function App() {
  const view = usePlayer((s) => s.view);
  const queueOpen = usePlayer((s) => s.queueOpen);
  const lyricsOpen = usePlayer((s) => s.lyricsOpen);
  const expandedPlayerOpen = usePlayer((s) => s.expandedPlayerOpen);

  // Global keyboard shortcuts
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable)) {
        if (e.key === "Escape") (target as HTMLInputElement).blur();
        return;
      }
      const st = usePlayer.getState();
      switch (e.key) {
        case " ":
          e.preventDefault();
          st.toggle();
          break;
        case "ArrowRight":
          if (e.ctrlKey || e.metaKey) st.next();
          else st.seekSec(st.position + 5);
          break;
        case "ArrowLeft":
          if (e.ctrlKey || e.metaKey) st.prev();
          else st.seekSec(st.position - 5);
          break;
        case "ArrowUp":
          e.preventDefault();
          st.setVolume(Math.min(1, st.volume + 0.05));
          break;
        case "ArrowDown":
          e.preventDefault();
          st.setVolume(Math.max(0, st.volume - 0.05));
          break;
        case "l":
        case "L":
          st.setLyricsOpen(!st.lyricsOpen);
          break;
        case "q":
        case "Q":
          st.setQueueOpen(!st.queueOpen);
          break;
        case "/":
          e.preventDefault();
          document.getElementById("melyar-search")?.focus();
          break;
        case "Escape":
          st.closeMenu();
          if (useSettings.getState().open) useSettings.getState().setOpen(false);
          else if (st.expandedPlayerOpen) st.setExpandedPlayerOpen(false);
          else if (st.lyricsOpen) st.setLyricsOpen(false);
          else if (st.queueOpen) st.setQueueOpen(false);
          break;
      }
    };
    const onPointer = () => {
      if (usePlayer.getState().menu) usePlayer.getState().closeMenu();
    };
    window.addEventListener("keydown", onKey);
    window.addEventListener("pointerdown", onPointer);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("pointerdown", onPointer);
    };
  }, []);

  const viewKey = view.name === "album" || view.name === "artist" ? `${view.name}:${view.key}` : view.name;
  const isNarrow = typeof window !== "undefined" && window.innerWidth < 1200;

  return (
    <div className={cn("app-root", queueOpen && "queue-open")}>
      <Sidebar />
      <div className="main-col">
        <Toolbar />
        <main className="content-scroll" key={viewKey}>
          <Stage />
        </main>
      </div>

      {/* Docked Queue Panel - part of layout */}
      <QueuePanel />

      {/* Overlay Portals - managed centrally */}
      <OverlayPortal>
        {expandedPlayerOpen && <ExpandedPlayer />}
        {lyricsOpen && <LyricsOverlay />}
        <ContextMenu />
        <SettingsPanel />
        <ImportOverlay />
        <Toast />
      </OverlayPortal>
    </div>
  );
}