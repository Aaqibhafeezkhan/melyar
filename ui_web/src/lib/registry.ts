import type { AlbumGroup, ArtistGroup, TrackMeta } from "./types";

const trackMap = new Map<string, TrackMeta>();

export function register(item: Partial<TrackMeta> & { id: string }): TrackMeta {
  const existing = trackMap.get(item.id);
  const merged: TrackMeta = {
    id: item.id,
    title: item.title?.trim() || existing?.title || "Bilinmeyen Parça",
    artist: item.artist?.trim() || existing?.artist || "Bilinmeyen Sanatçı",
    album: item.album?.trim() || existing?.album || "",
    duration: Number(item.duration) > 0 ? Number(item.duration) : existing?.duration || 0,
    thumbnail:
      item.thumbnail?.trim() || existing?.thumbnail || `https://i.ytimg.com/vi/${item.id}/hqdefault.jpg`,
  };
  trackMap.set(item.id, merged);
  return merged;
}

export function getTrack(id: string): TrackMeta | undefined {
  return trackMap.get(id);
}

function albumKey(t: TrackMeta) {
  return `${(t.album || t.title).toLowerCase()}|${t.artist.toLowerCase()}`;
}

function artistKey(t: TrackMeta) {
  return t.artist.toLowerCase();
}

export function groupAlbums(tracks: TrackMeta[]): AlbumGroup[] {
  const map = new Map<string, AlbumGroup>();
  for (const t of tracks) {
    const key = albumKey(t);
    let g = map.get(key);
    if (!g) {
      g = { key, name: t.album || t.title, artist: t.artist, cover: t.thumbnail, tracks: [] };
      map.set(key, g);
    }
    g.tracks.push(t);
  }
  return [...map.values()];
}

export function groupArtists(tracks: TrackMeta[]): ArtistGroup[] {
  const map = new Map<string, ArtistGroup>();
  for (const t of tracks) {
    const key = artistKey(t);
    let g = map.get(key);
    if (!g) {
      g = { key, name: t.artist, cover: t.thumbnail, tracks: [] };
      map.set(key, g);
    }
    g.tracks.push(t);
  }
  return [...map.values()];
}

export function findAlbum(list: TrackMeta[], key: string): AlbumGroup | null {
  return groupAlbums(list).find((a) => a.key === key) ?? null;
}

export function findArtist(list: TrackMeta[], key: string): ArtistGroup | null {
  return groupArtists(list).find((a) => a.key === key) ?? null;
}

export function libraryTracks(liked: TrackMeta[], history: TrackMeta[]): TrackMeta[] {
  const seen = new Set<string>();
  const out: TrackMeta[] = [];
  for (const t of [...liked, ...history]) {
    if (seen.has(t.id)) continue;
    seen.add(t.id);
    out.push(t);
  }
  return out;
}

/// Every track the UI has ever seen (search results, liked, history, queue).
export function allKnown(): TrackMeta[] {
  return [...trackMap.values()];
}
