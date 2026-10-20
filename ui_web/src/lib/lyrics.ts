export type LyricLine = { time: number; text: string };

export type ParsedLyrics = {
  synced: boolean;
  lines: LyricLine[];
  plain: string[];
};

export function parseLyrics(raw: string | null | undefined): ParsedLyrics {
  if (!raw || !raw.trim()) return { synced: false, lines: [], plain: [] };
  const lrcRe = /^\[(\d{1,2}):(\d{1,2})(?:[.:](\d{1,3}))?\](.*)$/;
  const lines: LyricLine[] = [];
  const plain: string[] = [];
  let synced = false;

  for (const rawLine of raw.split(/\r?\n/)) {
    const m = rawLine.match(lrcRe);
    if (m) {
      synced = true;
      const min = parseInt(m[1]!, 10);
      const sec = parseInt(m[2]!, 10);
      const frac = m[3] ? parseInt(m[3]!.padEnd(3, '0').slice(0, 3), 10) / 1000 : 0;
      const time = min * 60 + sec + frac;
      const text = (m[4] || '').trim();
      if (text) lines.push({ time, text });
      else plain.push('');
    } else {
      const text = rawLine.trim();
      if (text) plain.push(text);
    }
  }

  if (synced && lines.length > 0) {
    lines.sort((a, b) => a.time - b.time);
    return { synced: true, lines, plain: [] };
  }
  return { synced: false, lines: [], plain: plain.filter((l) => l.length > 0) };
}

export function activeLineIndex(lines: LyricLine[], position: number): number {
  if (lines.length === 0) return -1;
  let lo = 0;
  let hi = lines.length - 1;
  let ans = -1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (lines[mid]!.time <= position) {
      ans = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return ans;
}

export function formatTime(sec: number): string {
  if (!Number.isFinite(sec) || sec < 0) sec = 0;
  const s = Math.floor(sec);
  const m = Math.floor(s / 60);
  return `${m}:${(s % 60).toString().padStart(2, "0")}`;
}
