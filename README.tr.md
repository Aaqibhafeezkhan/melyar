<div align="center">

# Melyar

**Ultra-lightweight native YouTube Music desktop client in C++20 and Rust**

[English](README.md) · Türkçe

[![CI](https://github.com/MAKHMUDuz/melyar/actions/workflows/ci.yml/badge.svg)](https://github.com/MAKHMUDuz/melyar/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-APACHE)

</div>

---

Melyar, YouTube Music'i masaüstünde çalıştıran hafif bir yerel müzik istemcisidir.
Rust çekirdek (InnerTube istemcisi, mpv ses motoru, MPRIS, Waybar IPC) ile Qt6/QML
kabuğu ve React tabanlı web arayüzünden oluşur.

Proje **C++20 + Rust + Qt6 + React/TypeScript** yığınıyla yazılmıştır. Çalma motoru
olarak `libmpv`, ağ katmanı olarak YouTube'un resmi `InnerTube` API'si kullanılır.

---

## Özellikler

**Çalma**
- YouTube Music arama, şarkı / albüm / sanatçı / oynatma listesi sayfaları
- `libmpv` üzerinden streaming çalma, gapless ön-yükleme (prefetch)
- Kuyruk yönetimi, karıştır (shuffle) ve tekrarlama (repeat) modları
- Ses seviyesi, seek, ekolayzer ayarı
- Senkronize şarkı sözleri (LRC) — `lrclib` kaynağından, önbellekli

**Kütüphane**
- Favoriler, dinleme geçmişi ve arama geçmişi (SQLite, `~/.local/share/melyar/melyar.db`)
- Albüm / sanatçı / oynatma listesi kütüphane görünümleri

**Linux entegrasyonu**
- **MPRIS** D-Bus arayüzü (`org.mpris.MediaPlayer2.melyar`) — GNOME, KDE, i3, sway ile uyum
- **Waybar / Polybar / i3status** için Unix Domain Socket IPC (`$XDG_RUNTIME_DIR/melyar.sock`)
- Global medya kısayolları (XF86AudioPlay / Next / Prev)
- `.desktop` girdisi ve uygulama ikonu (SVG)

**Arayüz**
- Liquid-glass / cam efektli arayüz, hareket (motion) token sistemi
- Light/dark tema, tamamen responsive düzen
- Gelişmiş oynatıcı, kuyruk paneli, söz görünümü, arama sonuçları

---

## Mimari

```
┌──────────────────────────────────────────────────────────┐
│  ui_web/            React 19 + TypeScript + Tailwind 4    │
│                     (WebChannel üzerinden Rust ile konuşur)│
├──────────────────────────────────────────────────────────┤
│  ui_cpp/            Qt6 / QML kabuk + C++ bridge           │
├──────────────────────────────────────────────────────────┤
│  core_rs/           Rust çekirdek                          │
│    ├── innertube/    InnerTube istemcisi, cipher, sözler   │
│    ├── audio/        mpv motoru + kuyruk                    │
│    ├── db/           SQLite depolama                       │
│    └── linux/        MPRIS (D-Bus) + Waybar socket IPC     │
└──────────────────────────────────────────────────────────┘
```

C++ ↔ Rust iletişimi [`cxx`](https://cxx.rs) köprüsü üzerinden sağlanır.
Rust tarafı `tokio` runtime'ı üzerinde asenkron çalışır, ses `libmpv` ile senkron
oynatılır.

---

## Gereksinimler

| Bileşen | Sürüm |
|---|---|
| CMake | ≥ 3.25 |
| Rust | ≥ 1.75 |
| Qt6 | Core, Gui, Quick, Qml, WebEngineQuick, WebChannel |
| mpv | ≥ 2.x (`libmpv`) |
| pkg-config | — |
| Node.js + pnpm | ≥ 20 / ≥ 9 (yalnızca web arayüzü geliştirmek için) |
| yt-dlp | önerilir (bazı metadata çözümlemeleri için) |

Corrosion (Rust ↔ CMake entegrasyonu) `CMakeLists.txt` tarafından otomatik olarak
indirilir; ayrıca kurulum gerekmez.

### Arch / Manjaro

```bash
sudo pacman -S base-devel cmake rust pkgconf \
    qt6-base qt6-declarative qt6-webengine qt6-webchannel mpv
```

### Debian / Ubuntu

```bash
sudo apt install build-essential cmake pkg-config rustc cargo \
    qt6-base-dev qt6-declarative-dev qt6-webengine-dev qt6-webchannel-dev \
    libmpv-dev yt-dlp
```

---

## Derleme

### 1. Web arayüzünü derle (opsiyonel ama önerilir)

`ui_web/dist/` depoda hazır gelir. Yine de güncel arayüzü kullanmak için:

```bash
cd ui_web
pnpm install
pnpm build
cd ..
```

### 2. C++ + Rust çekirdeğini derle

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

### 3. Çalıştır

```bash
./build/melyar
```

Web arayüzünü canlı geliştirmek için Vite dev sunucusunu ayrı bir terminalde
başlatın ve uygulamayı şu şekilde çalıştırın:

```bash
cd ui_web && pnpm dev      # terminal 1
MELYAR_DEV_URL=http://localhost:5173 ./build/melyar   # terminal 2
```

### Kurulum

```bash
sudo cmake --install build
```

CMake'in varsayılan kurulum prefix'i `/usr/local` olacaktır:

| Dosya | Yol |
|---|---|
| Binary | `/usr/local/bin/melyar` |
| Web arayüzü | `/usr/local/share/melyar/web/` |
| `.desktop` | `/usr/local/share/applications/melyar.desktop` |
| İkon | `/usr/local/share/icons/hicolor/scalable/apps/melyar.svg` |

Sistem dizinine (`/usr`) kurmak için derleme sırasında prefix verin:

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
sudo cmake --install build
```

Uygulama, web arayüzünü şu sırayla arar: çalışma dizini → binary'nin yanı →
`/usr/share/melyar/web/` → `/usr/local/share/melyar/web/`. Geliştirme sırasında
canlı Vite sunucusuna bağlanmak için `MELYAR_DEV_URL` ortam değişkenini
kullanın.

### Arch / AUR paketi

Depodaki `PKGBUILD` ile:

```bash
makepkg -si
```

---

## Waybar / durum çubuğu entegrasyonu

Melyar, `$XDG_RUNTIME_DIR/melyar.sock` adresinde Unix Domain Socket üzerinden
sıfır gecikmeli bir IPC sunucusu çalıştırır.

`~/.config/waybar/config.jsonc`:

```jsonc
"custom/melyar": {
    "format": "{icon} {}",
    "return-type": "json",
    "exec": "socat -u UNIX-CONNECT:${XDG_RUNTIME_DIR:-/tmp}/melyar.sock -",
    "on-click": "echo toggle | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "on-click-right": "echo next | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "on-click-middle": "echo prev | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "interval": 1
}
```

Komutlar: `toggle`, `next`, `prev`, `stop`.

Detaylı kurulum, CSS ve Hyprland/Sway kısayol örnekleri için
[`docs/WAYBAR.md`](docs/WAYBAR.md) dosyasına bakın.

---

## Proje yapısı

```
melyar/
├── core_rs/              Rust çekirdek
│   ├── src/
│   │   ├── innertube/     InnerTube API istemcisi, stream cipher, sözler
│   │   ├── audio/         mpv ses motoru ve kuyruk yönetimi
│   │   ├── db/            SQLite depolama (favoriler, geçmiş, cache)
│   │   ├── linux/         MPRIS (D-Bus) ve Waybar socket IPC
│   │   └── lib.rs         cxx köprüsü ve genel API
│   └── build.rs
├── ui_cpp/                Qt6 / QML kabuk ve C++ bridge
│   ├── main.cpp
│   ├── bridge/
│   └── qml/               QML bileşenleri (Liquid glass arayüz)
├── ui_web/                React + TypeScript web arayüzü
│   ├── src/components/
│   ├── src/lib/
│   └── dist/              derlenmiş çıktı
├── docs/                  Waybar ve entegrasyon belgeleri
├── resources/             ikonlar ve .desktop dosyası
├── CMakeLists.txt
├── Cargo.toml
└── PKGBUILD
```

---

## Veri konumu

| Veri | Yol |
|---|---|
| Veritabanı (favoriler, geçmiş, söz cache) | `~/.local/share/melyar/melyar.db` |
| IPC soketi | `$XDG_RUNTIME_DIR/melyar.sock` |

---

## Lisans

Bu proje çift lisanslıdır — aşağıdakilerden birini seçebilirsiniz:

- **MIT** — [`LICENSE-MIT`](LICENSE-MIT)
- **Apache-2.0** — [`LICENSE-APACHE`](LICENSE-APACHE)

`SPDX-License-Identifier: MIT OR Apache-2.0`

---

## Notlar

- Melyar, YouTube'un resmi olmayan bir istemcisidir. YouTube, Spotify ya da
  başka bir sağlayıcıyla resmi bir ortaklık veya sponsorluk ilişkisi yoktur.
- Yalnızca kişisel kullanım ve eğitim amaçlı geliştirilmiştir. İçerik
  lisansları, hesap şartları ve bulunduğunuz ülkenin yasaları size aittir.

---

<a name="english"></a>

## English

Melyar is an ultra-lightweight native desktop client for YouTube Music, written in
**C++20 + Rust** with a **Qt6/QML** shell and a **React + TypeScript** web UI.

**Highlights:** InnerTube-based search and streaming, `libmpv` playback with
gapless prefetch, queue with shuffle/repeat, synced LRC lyrics, favorites and
history backed by SQLite, MPRIS D-Bus integration, and a zero-latency Unix
socket IPC for Waybar/Polybar/i3status.

**Build:**

```bash
cd ui_web && pnpm install && pnpm build && cd ..
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
./build/melyar
```

**Requirements:** CMake ≥ 3.25, Rust ≥ 1.75, Qt6 (Core, Gui, Quick, Qml,
WebEngineQuick, WebChannel), mpv ≥ 2.x, pkg-config.

**License:** MIT OR Apache-2.0
