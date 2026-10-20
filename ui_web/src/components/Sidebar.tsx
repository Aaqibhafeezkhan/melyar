import { useEffect, useRef, useState } from "react";
import { Heart, Home, Library, ListMusic, SearchIcon, Clock3 } from "lucide-react";
import { usePlayer } from "@/store";
import { GlassMorphIndicator } from "@/components/GlassComponents";
import { cn } from "@/lib/cn";
import type { View } from "@/lib/types";

function SideItem({
  icon: Icon,
  label,
  view,
  ref,
}: {
  icon: typeof Home;
  label: string;
  view: View;
  ref?: React.Ref<HTMLButtonElement>;
}) {
  const current = usePlayer((s) => s.view);
  const navigate = usePlayer((s) => s.navigate);
  const keyOf = (v: View) => (v.name === "album" || v.name === "artist" ? `${v.name}:${v.key}` : v.name);
  const active = keyOf(current) === keyOf(view);
  return (
    <button
      ref={ref}
      className="text-btn relative z-10"
      data-active={active}
      onClick={() => navigate(view)}
    >
      <Icon className="size-[17px]" strokeWidth={active ? 2.4 : 2} />
      <span className="truncate">{label}</span>
    </button>
  );
}

export function Sidebar() {
  const query = usePlayer((s) => s.query);
  const setQuery = usePlayer((s) => s.setQuery);
  const navigate = usePlayer((s) => s.navigate);
  const setQueueOpen = usePlayer((s) => s.setQueueOpen);
  const queueOpen = usePlayer((s) => s.queueOpen);
  const current = usePlayer((s) => s.view);

  const listenNavRef = useRef<HTMLDivElement>(null);
  const libraryNavRef = useRef<HTMLDivElement>(null);
  const itemRefs = useRef<Map<string, HTMLButtonElement>>(new Map());
  const activeRef = useRef<HTMLButtonElement | null>(null);

  const keyOf = (v: View) => (v.name === "album" || v.name === "artist" ? `${v.name}:${v.key}` : v.name);
  const activeKey = keyOf(current);

  // Track whether the active item lives in the "DİNLE" or "KİTAPLIK" group.
  const listenKeys = ["home", "search"];
  const isListenGroup = listenKeys.includes(activeKey);

  // Create stable ref callbacks per key.
  const createRef = (key: string) => (el: HTMLButtonElement | null) => {
    if (el) {
      itemRefs.current.set(key, el);
      if (key === activeKey) activeRef.current = el;
    } else {
      itemRefs.current.delete(key);
      if (activeRef.current === el) activeRef.current = null;
    }
  };

  // When active view changes, point the shared indicator at the new item.
  useEffect(() => {
    activeRef.current = itemRefs.current.get(activeKey) ?? null;
  }, [activeKey]);

  // The indicator belongs to whichever nav group holds the active item.
  const activeNavRef = isListenGroup ? listenNavRef : libraryNavRef;

  return (
    <aside className="sidebar">
      <div className="flex items-center gap-2.5 px-4 pb-2 pt-4 border-b border-glass-border">
        <div className="grid size-8 place-items-center rounded-lg bg-accent shadow-lg glass-interactive">
          <svg viewBox="0 0 64 64" className="size-5">
            <path d="M20 44V20l14 8 14-8v24" fill="none" stroke="#fff" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        <span className="text-[15px] font-bold tracking-tight">Melyar</span>
      </div>

      <div className="px-3 pb-1">
        <label className="search-bar glass-input px-4 py-2">
          <SearchIcon className="size-4 text-text-tertiary" />
          <input
            id="melyar-search"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              navigate({ name: "search" });
            }}
            placeholder="Sanatçı, şarkı, albüm ara"
            className="w-full bg-transparent text-[13.5px] outline-none placeholder:text-text-tertiary"
            spellCheck={false}
          />
        </label>
      </div>

      <div className="scroll-thin min-h-0 flex-1 overflow-y-auto px-3 pb-4">
        <p className="side-section">DİNLE</p>
        <nav ref={listenNavRef} className="flex flex-col gap-0.5 relative" role="navigation" aria-label="Ana navigasyon">
          <GlassMorphIndicator
            targetRef={activeRef}
            containerRef={listenNavRef}
            variant="accent"
            radius="md"
            targetKey={activeKey}
            isVisible={isListenGroup && activeRef.current !== null}
          />
          <SideItem ref={createRef("home")} icon={Home} label="Ana Sayfa" view={{ name: "home" }} />
          <SideItem ref={createRef("search")} icon={SearchIcon} label="Ara" view={{ name: "search" }} />
        </nav>

        <p className="side-section">KİTAPLIK</p>
        <nav ref={libraryNavRef} className="flex flex-col gap-0.5 relative" role="navigation" aria-label="Kitaplık navigasyonu">
          <GlassMorphIndicator
            targetRef={activeRef}
            containerRef={libraryNavRef}
            variant="accent"
            radius="md"
            targetKey={activeKey}
            isVisible={!isListenGroup && activeRef.current !== null}
          />
          <SideItem ref={createRef("songs")} icon={Library} label="Şarkılar" view={{ name: "songs" }} />
          <SideItem ref={createRef("liked")} icon={Heart} label="Beğenilenler" view={{ name: "liked" }} />
          <SideItem ref={createRef("history")} icon={Clock3} label="Son Çalınanlar" view={{ name: "history" }} />
          <SideItem ref={createRef("albums")} icon={ListMusic} label="Albümler" view={{ name: "albums" }} />
          <button
            ref={createRef("queue")}
            className="text-btn relative z-10"
            data-active={queueOpen}
            onClick={() => setQueueOpen(!queueOpen)}
          >
            <ListMusic className="size-[17px]" />
            <span className="truncate">Çalma Sırası</span>
          </button>
        </nav>
      </div>
    </aside>
  );
}