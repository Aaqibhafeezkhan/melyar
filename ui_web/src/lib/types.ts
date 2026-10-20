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
  | { name: "album"; key: string }
  | { name: "artist"; key: string };

export type RepeatMode = 0 | 1 | 2; // off / all / one

declare global {
  interface Window {
    qt?: { webChannelTransport: unknown };
    QWebChannel?: (transport: unknown, callback: (channel: any) => void) => void;
    bridge?: any;
  }
}
