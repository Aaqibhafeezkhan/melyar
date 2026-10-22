export type TrackMeta = {
  id: string;
  title: string;
  artist: string;
  album: string;
  duration: number;
  thumbnail: string;
};

export type AlbumGroup = {
  key: string;
  name: string;
  artist: string;
  cover: string;
  tracks: TrackMeta[];
};

export type ArtistGroup = {
  key: string;
  name: string;
  cover: string;
  tracks: TrackMeta[];
};

export type View =
  | { name: "home" }
  | { name: "search" }
  | { name: "songs" }
  | { name: "albums" }
  | { name: "artists" }
  | { name: "liked" }
  | { name: "history" }
  // The detail views carry the name they were opened from, so the header can
  // show what you are looking at instead of the word "Albums".
  | { name: "album"; key: string; label?: string }
  | { name: "artist"; key: string; label?: string };

export type RepeatMode = 0 | 1 | 2; // off / all / one

declare global {
  interface Window {
    qt?: { webChannelTransport: unknown };
    QWebChannel?: (transport: unknown, callback: (channel: any) => void) => void;
    bridge?: any;
  }
}
