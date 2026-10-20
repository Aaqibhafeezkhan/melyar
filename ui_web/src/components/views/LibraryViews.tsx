import { Clock3, Heart, Library, Music2 } from "lucide-react";
import { usePlayer } from "@/store";
import { allKnown, findAlbum, findArtist, groupAlbums, groupArtists, libraryTracks } from "@/lib/registry";
import { TrackTable } from "@/components/TrackTable";
import { Artwork } from "@/components/Toolbar";
import { formatTime } from "@/lib/lyrics";
import type { View } from "@/lib/types";

function LibraryHeader({
  icon: Icon,
  kicker,
  title,
  meta,
  gradient,
  round = false,
}: {
  icon: typeof Heart;
  kicker: string;
  title: string;
  meta: string;
  gradient: string;
  round?: boolean;
}) {
  return (
    <header className="mb-8 flex items-end gap-6">
      <div
        className={`cover grid ${round ? "rounded-full" : ""} size-36 shrink-0 place-items-center text-white lg:size-40`}
        style={{ background: gradient }}
      >
        <Icon className="size-12 opacity-90" />
      </div>
      <div className="min-w-0 pb-1">
        <p className="text-xs font-bold uppercase tracking-wider text-text-tertiary">{kicker}</p>
        <h1 className="mt-1 truncate text-4xl font-bold tracking-tight lg:text-5xl">{title}</h1>
        <p className="mt-2 text-sm text-text-tertiary">{meta}</p>
      </div>
    </header>
  );
}

export function SongsView() {
  const liked = usePlayer((s) => s.liked);
  const history = usePlayer((s) => s.history);
  const library = libraryTracks(liked, history);
  const totalSecs = library.reduce((acc, t) => acc + (t.duration || 0), 0);
  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <LibraryHeader
        icon={Library}
        kicker="Kitaplık"
        title="Şarkılar"
        meta={`${library.length} parça · ${formatTime(totalSecs)}`}
        gradient="linear-gradient(135deg,#8e8e93,#48484a)"
      />
      <TrackTable tracks={library} emptyText="Çaldığın ve beğendiğin şarkılar burada birikir." />
    </div>
  );
}

export function LikedView() {
  const liked = usePlayer((s) => s.liked);
  const playTrack = usePlayer((s) => s.playTrack);
  const totalSecs = liked.reduce((acc, t) => acc + (t.duration || 0), 0);
  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <LibraryHeader
        icon={Heart}
        kicker="Çalma Listesi"
        title="Beğenilen Şarkılar"
        meta={`${liked.length} parça · ${formatTime(totalSecs)}`}
        gradient="linear-gradient(135deg,#fc5c7d,#fa233b)"
      />
      {liked.length > 0 ? (
        <button
          className="play-btn-main mb-5"
          aria-label="Tümünü çal"
          onClick={() => {
            const first = liked[0];
            if (first) playTrack(first, liked);
          }}
        >
          <svg viewBox="0 0 24 24" className="ml-0.5 size-5 fill-current"><path d="M8 5v14l11-7z" /></svg>
        </button>
      ) : null}
      <TrackTable tracks={liked} emptyText="Kalp ikonuna dokunduğun şarkılar burada listelenir." />
    </div>
  );
}

export function HistoryView() {
  const history = usePlayer((s) => s.history);
  const playTrack = usePlayer((s) => s.playTrack);
  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <LibraryHeader
        icon={Clock3}
        kicker="Çalma Listesi"
        title="Son Çalınanlar"
        meta={`${history.length} parça`}
        gradient="linear-gradient(135deg,#5e5ce6,#30d158)"
      />
      {history.length > 0 ? (
        <button
          className="play-btn-main mb-5"
          aria-label="Tümünü çal"
          onClick={() => {
            const first = history[0];
            if (first) playTrack(first, history);
          }}
        >
          <svg viewBox="0 0 24 24" className="ml-0.5 size-5 fill-current"><path d="M8 5v14l11-7z" /></svg>
        </button>
      ) : null}
      <TrackTable tracks={history} emptyText="Çaldığın parçalar burada görünür." />
    </div>
  );
}

export function AlbumsView() {
  const liked = usePlayer((s) => s.liked);
  const history = usePlayer((s) => s.history);
  const navigate = usePlayer((s) => s.navigate);
  const playTrack = usePlayer((s) => s.playTrack);
  // Personal albums first, then anything else discovered via search
  const albums = [...groupAlbums(libraryTracks(liked, history)), ...groupAlbums(allKnown())].filter(
    (a, i, arr) => arr.findIndex((x) => x.key === a.key) === i,
  );

  if (albums.length === 0) {
    return (
      <div className="px-6 pb-10 pt-6 lg:px-9">
        <h1 className="mb-8 text-4xl font-bold tracking-tight">Albümler</h1>
        <TrackTable tracks={[]} emptyText="Albümler çaldıkça ve beğendikçe burada toplanır." />
      </div>
    );
  }

  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <h1 className="mb-6 text-4xl font-bold tracking-tight">Albümler</h1>
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
        {albums.map((album) => (
          <div key={album.key} className="grid-item group flex flex-col gap-3">
            <button
              onClick={() => navigate({ name: "album", key: album.key })}
              className="relative"
              aria-label={`${album.name} albümünü aç`}
            >
              <Artwork src={album.cover} className="aspect-square w-full" />
              <div className="absolute inset-0 grid place-items-center opacity-0 transition-opacity group-hover:opacity-100">
                <span
                  className="grid size-11 place-items-center rounded-full bg-accent text-white shadow-xl"
                  onClick={(e) => {
                    e.stopPropagation();
                    playTrack(album.tracks[0]!, album.tracks);
                  }}
                  role="button"
                  aria-label={`${album.name} çal`}
                >
                  <svg viewBox="0 0 24 24" className="ml-0.5 size-5 fill-current"><path d="M8 5v14l11-7z" /></svg>
                </span>
              </div>
            </button>
            <div className="min-w-0">
              <button className="block w-full truncate text-left text-[13.5px] font-semibold hover:underline" onClick={() => navigate({ name: "album", key: album.key })}>
                {album.name}
              </button>
              <p className="truncate text-[12px] text-text-tertiary">{album.artist}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export function ArtistsView() {
  const liked = usePlayer((s) => s.liked);
  const history = usePlayer((s) => s.history);
  const navigate = usePlayer((s) => s.navigate);
  const artists = [...groupArtists(libraryTracks(liked, history)), ...groupArtists(allKnown())].filter(
    (a, i, arr) => arr.findIndex((x) => x.key === a.key) === i,
  );

  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <h1 className="mb-6 text-4xl font-bold tracking-tight">Sanatçılar</h1>
      {artists.length === 0 ? (
        <TrackTable tracks={[]} emptyText="Dinlediğin sanatçılar burada görünür." />
      ) : (
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
          {artists.map((a) => (
            <button key={a.key} className="grid-item group flex flex-col gap-3" onClick={() => navigate({ name: "artist", key: a.key })}>
              <Artwork src={a.cover} className="aspect-square w-full rounded-full" />
              <div className="min-w-0 text-center">
                <p className="truncate text-[13.5px] font-semibold">{a.name}</p>
                <p className="text-[11.5px] text-text-tertiary">Sanatçı</p>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export function AlbumDetailView({ albumKey }: { albumKey: string }) {
  const playTrack = usePlayer((s) => s.playTrack);
  const navigate = usePlayer((s) => s.navigate);
  const album = findAlbum(allKnown(), albumKey);

  if (!album) {
    return (
      <div className="px-6 pb-10 pt-6 lg:px-9">
        <p className="py-16 text-center text-sm text-text-tertiary">Albüm bulunamadı.</p>
      </div>
    );
  }
  const totalSecs = album.tracks.reduce((acc, t) => acc + (t.duration || 0), 0);

  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <header className="mb-8 flex flex-col items-center gap-6 text-center sm:flex-row sm:items-end sm:text-left">
        <Artwork src={album.cover} className="size-40 shrink-0 lg:size-48" />
        <div className="min-w-0">
          <p className="text-xs font-bold uppercase tracking-wider text-text-tertiary">Albüm</p>
          <h1 className="mt-1 truncate text-4xl font-bold tracking-tight lg:text-5xl">{album.name}</h1>
          <p className="mt-2 text-sm text-text-tertiary">
            <span className="font-medium text-text-secondary">{album.artist}</span> · {album.tracks.length} parça ·{" "}
            {formatTime(totalSecs)}
          </p>
        </div>
      </header>
      <TrackTable tracks={album.tracks} showAlbum={false} />
      <button className="mt-6 text-sm text-text-tertiary hover:text-text-secondary hover:underline" onClick={() => navigate({ name: "albums" })}>
        ← Albümlere dön
      </button>
    </div>
  );
}

export function ArtistDetailView({ artistKey }: { artistKey: string }) {
  const playTrack = usePlayer((s) => s.playTrack);
  const navigate = usePlayer((s) => s.navigate);
  const artist = findArtist(allKnown(), artistKey);

  if (!artist) {
    return (
      <div className="px-6 pb-10 pt-6 lg:px-9">
        <p className="py-16 text-center text-sm text-text-tertiary">Sanatçı bulunamadı.</p>
      </div>
    );
  }
  const albums = groupAlbums(artist.tracks);

  return (
    <div className="px-6 pb-10 pt-6 lg:px-9">
      <header className="mb-8 flex flex-col items-center gap-6 text-center sm:flex-row sm:items-end sm:text-left">
        <Artwork src={artist.cover} className="size-36 shrink-0 rounded-full lg:size-44" />
        <div className="min-w-0">
          <p className="flex items-center justify-center gap-1.5 text-xs font-bold uppercase tracking-wider text-text-tertiary sm:justify-start">
            <Music2 className="size-3.5" /> Sanatçı
          </p>
          <h1 className="mt-1 truncate text-4xl font-bold tracking-tight lg:text-5xl">{artist.name}</h1>
          <p className="mt-2 text-sm text-text-tertiary">{artist.tracks.length} bilinen parça</p>
        </div>
      </header>

      {albums.length > 1 ? (
        <section className="mb-8">
          <h2 className="mb-4 text-xl font-bold tracking-tight">Albümler</h2>
          <div className="flex gap-4 overflow-x-auto pb-2">
            {albums.map((album) => (
              <button key={album.key} className="card w-36 shrink-0" onClick={() => navigate({ name: "album", key: album.key })}>
                <Artwork src={album.cover} className="mb-3 aspect-square w-full" />
                <p className="truncate text-left text-[13px] font-semibold">{album.name}</p>
                <p className="text-left text-[11.5px] text-text-tertiary">{album.tracks.length} parça</p>
              </button>
            ))}
          </div>
        </section>
      ) : null}

      <section>
        <h2 className="mb-3 text-xl font-bold tracking-tight">Parçalar</h2>
        <TrackTable tracks={artist.tracks} />
      </section>
    </div>
  );
}

export type { View };