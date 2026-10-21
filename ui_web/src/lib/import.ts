import { create } from "zustand";
import { getBridge } from "@/lib/client";
import { usePlayer } from "@/store";
import { t, tCount } from "@/lib/i18n";

export type ImportProgress = {
  current: number;
  total: number;
  matched: number;
  skipped: number;
  done: boolean;
};

const EMPTY: ImportProgress = { current: 0, total: 0, matched: 0, skipped: 0, done: false };

type ImportState = {
  progress: ImportProgress;
  running: boolean;
  /** Ask the user for an export file and start the import. */
  start: () => Promise<void>;
  cancel: () => void;
  reset: () => void;
};

export const useLibraryImport = create<ImportState>()((set, get) => ({
  progress: EMPTY,
  running: false,

  start: async () => {
    const b = getBridge();
    if (!b) return;

    // The native file dialog is opened by the QML side, because the web
    // layer cannot reach the file system. The bridge asks for it and
    // answers with the picked path.
    if (typeof b.requestFilePick !== "function") return;

    const path = await new Promise<string>((resolve) => {
      const timer = setTimeout(() => resolve(""), 5 * 60 * 1000);
      b.filePicked?.connect((picked: string) => {
        clearTimeout(timer);
        resolve(String(picked || ""));
      });
      b.requestFilePick();
    });

    if (!path) return;
    if (typeof b.importLibrary !== "function") return;

    b.importLibrary(path);
    set({ running: true, progress: { ...EMPTY } });
  },

  cancel: () => {
    const b = getBridge();
    if (b && typeof b.cancelImport === "function") b.cancelImport();
    set({ running: false });
  },

  reset: () => set({ progress: EMPTY, running: false }),
}));

/**
 * Wire the bridge's progress signal to the store. Called once, after the
 * bridge connects.
 */
export function bindImportProgress() {
  const b = getBridge();
  if (!b) return;

  b.importProgressChanged?.connect(() => {
    const raw = b.importProgress || {};
    const progress: ImportProgress = {
      current: Number(raw.current) || 0,
      total: Number(raw.total) || 0,
      matched: Number(raw.matched) || 0,
      skipped: Number(raw.skipped) || 0,
      done: Boolean(raw.done),
    };

    useLibraryImport.setState({ progress, running: !progress.done });

    if (progress.done) {
      // The core holds the imported tracks, so the library has to be reloaded.
      if (typeof b.loadFavorites === "function") b.loadFavorites();

      const st = usePlayer.getState();
      st.toastNote(
        tCount("import.finished", progress.matched, { skipped: progress.skipped }),
      );
    }
  });
}
