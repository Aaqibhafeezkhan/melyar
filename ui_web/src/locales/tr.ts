/**
 * Türkçe metinler.
 *
 * Anahtar adları `en.ts` ile aynı olmalıdır. Yeni bir metin eklerken
 * her iki dosyaya da aynı anahtarla ekleyin.
 */
export const tr: Record<string, string> = {
  // Gezinme
  "nav.section.listen": "DİNLE",
  "nav.section.library": "KİTAPLIK",
  "nav.home": "Ana Sayfa",
  "nav.search": "Ara",
  "nav.songs": "Şarkılar",
  "nav.liked": "Beğenilenler",
  "nav.history": "Son Çalınanlar",
  "nav.albums": "Albümler",
  "nav.artists": "Sanatçılar",
  "nav.playlists": "Çalma Listeleri",
  "nav.queue": "Çalma Sırası",
  "nav.aria.library": "Kitaplık navigasyonu",
  "nav.search.placeholder": "Sanatçı, şarkı, albüm ara",

  // Araç çubuğu
  "toolbar.shuffle": "Karıştır",
  "toolbar.prev": "Önceki",
  "toolbar.play": "Çal",
  "toolbar.pause": "Duraklat",
  "toolbar.next": "Sonraki",
  "toolbar.repeat": "Döngü",
  "toolbar.expand": "Genişletilmiş oynatıcıyı aç",
  "toolbar.noTrack": "Çalmaya başlamak için bir parça seç",
  "toolbar.lyrics.open": "Sözleri Aç",
  "toolbar.lyrics.close": "Sözleri Kapat",
  "toolbar.queue": "Sıra",
  "toolbar.mute.on": "Sessize Al",
  "toolbar.mute.off": "Sesi Aç",
  "toolbar.volume": "Ses",

  // Sıra paneli
  "queue.title": "Çalma Sırası",
  "queue.count": "{n} parça",
  "queue.clear": "Sırayı temizle",
  "queue.close": "Kuyruğu kapat",
  "queue.empty": "Sıra boş. Bir parça çaldığında burada listelenir.",

  // Parça tablosu
  "track.play": "Çal",
  "track.pause": "Duraklat",
  "track.like": "Beğen",
  "track.unlike": "Beğeniyi kaldır",
  "track.options": "Seçenekler",
  "track.empty": "Burada henüz bir şey yok.",
  "track.col.track": "Parça",
  "track.col.album": "Albüm",
  "track.col.duration": "Süre",

  // Sağ tık menüsü
  "menu.playNext": "Sonra Çal",
  "menu.addToQueue": "Sıraya Ekle",
  "menu.like": "Beğen",
  "menu.unlike": "Beğeniyi Kaldır",
  "menu.addToPlaylist": "Çalma Listesine Ekle",
  "menu.download": "İndir (Çevrimdışı)",
  "menu.goToLyrics": "Sözlere Git",
  "menu.copyLink": "Bağlantıyı Kopyala",
  "menu.goToArtist": "Sanatçıya Git",
  "menu.removeFromQueue": "Çaldan Kaldır",

  // Söz katmanı
  "lyrics.aria": "Sözler",
  "lyrics.close": "Sözleri kapat",
  "lyrics.title": "Sözler",
  "lyrics.notFound": "Bu parça için söz bulunamadı",
  "lyrics.notFoundHint": "Başka bir parçayı deneyebilirsin.",
  "lyrics.prev": "Önceki",
  "lyrics.queue.open": "Kuyruğu Aç",
  "lyrics.queue.close": "Kuyruğu Kapat",

  // Genişletilmiş oynatıcı
  "expanded.aria": "Genişletilmiş Oynatıcı",
  "expanded.minimize": "Küçült",
  "expanded.nowPlaying": "Şimdi Çalıyor",
  "expanded.unknownArtist": "Bilinmeyen Sanatçı",
  "expanded.moreActions": "Diğer İşlemler",
  "expanded.share": "Paylaş",
  "expanded.linkCopied": "Paylaşım bağlantısı kopyalandı",
  "expanded.lyricsLoading": "Sözler yükleniyor…",
  "expanded.repeat": "Döngü",
  "expanded.shuffle": "Karışık",
  "expanded.externalLink": "Harici Bağlantı",

  // Ana sayfa
  "home.greeting.night": "İyi geceler",
  "home.greeting.morning": "Günaydın",
  "home.greeting.day": "İyi günler",
  "home.greeting.evening": "İyi akşamlar",
  "home.resume": "Kaldığın yerden:",
  "home.subtitle": "YouTube Music'te milyonlarca parça seni bekliyor.",
  "home.kicker.recent": "Son çalınan",
  "home.recentlyPlayed": "Son Çalınanlar",
  "home.liked": "Beğenilenler",
  "home.showAll": "Tümünü gör",
  "home.libraryEmpty.title": "Kitaplığın burada görünecek",
  "home.libraryEmpty.body":
    "Yukarıdaki arama kutusundan bir şey bul ve çal. Çaldığın parçalar burada listelenir; kalp ikonuyla beğendiklerini kaydedebilirsin.",
  "home.genres": "Türleri Keşfet",
  "home.genre.turkishPop": "Türkçe Pop",
  "home.genre.electronic": "Elektronik",
  "home.genre.classical": "Klasik",

  // Kitaplık
  "library.kicker": "Kitaplık",
  "library.songs.title": "Şarkılar",
  "library.songs.empty": "Çaldığın ve beğendiğin şarkılar burada birikir.",
  "library.liked.kicker": "Çalma Listesi",
  "library.liked.title": "Beğenilen Şarkılar",
  "library.liked.empty": "Kalp ikonuna dokunduğun şarkılar burada listelenir.",
  "library.history.kicker": "Çalma Listesi",
  "library.history.title": "Son Çalınanlar",
  "library.history.empty": "Çaldığın parçalar burada görünür.",
  "library.albums.title": "Albümler",
  "library.albums.empty": "Albümler çaldıkça ve beğendikçe burada toplanır.",
  "library.artists.title": "Sanatçılar",
  "library.artists.empty": "Dinlediğin sanatçılar burada görünür.",
  "library.col.artist": "Sanatçı",
  "library.playAll": "Tümünü çal",
  "library.openAlbum": "{name} albümünü aç",
  "library.playAlbum": "{name} çal",
  "library.count": "{n} parça",
  "library.countDuration": "{n} parça · {time}",
  "library.albums.notFound": "Albüm bulunamadı.",
  "library.albums.label": "Albüm",
  "library.albums.back": "← Albümlere dön",
  "library.artists.notFound": "Sanatçı bulunamadı.",
  "library.artists.label": "Sanatçı",
  "library.artists.knownTracks": "{n} bilinen parça",
  "library.detail.tracks": "Parçalar",

  // Arama
  "search.placeholder": "Şarkı, sanatçı veya albüm ara",
  "search.hint": "Sanatçı, şarkı veya albüm adı yaz. Sonuçlar YouTube Music'ten canlı gelir.",
  "search.noResults": "\"{query}\" için sonuç bulunamadı.",
  "search.artists": "Sanatçılar",
  "search.songs": "Şarkılar",

  // Bildirimler
  "toast.liked": "Beğenilenlere eklendi",
  "toast.unliked": "Beğenilenlerden çıkarıldı",
  "toast.playNext": "Sıradaki olarak eklendi",
  "toast.queued": "Sıraya eklendi",
  "toast.linkCopied": "Bağlantı kopyalandı",

  // Ayarlar
  "settings.language": "Dil",
  "settings.language.description": "Arayüzün dili.",

  // Ortak
  "common.loading": "Yükleniyor...",
  "common.unknownTrack": "Bilinmeyen Parça",
  "common.unknownArtist": "Bilinmeyen Sanatçı",
  "common.close": "Kapat",
};
