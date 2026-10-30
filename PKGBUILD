# Maintainer: mahmud <mahmudjonmurodov@mail.ru>
pkgname=melyar
pkgver=0.0.3
pkgrel=2
pkgdesc="Ultra-lightweight native YouTube Music desktop client in C++20 and Rust"
arch=('x86_64')
url="https://github.com/MAKHMUDuz/melyar"
license=('MIT' 'Apache')
depends=(
    'mpv'
    'qt6-base'
    'qt6-declarative'
    'qt6-svg'
    'qt6-wayland'
    'qt6-webchannel'
    'qt6-webengine'
)
makedepends=('cmake' 'rust' 'cargo' 'pkgconf' 'nodejs' 'pnpm')
optdepends=(
    'openbsd-netcat: media controls in the desktop entry menu'
    'yt-dlp: resolves metadata for tracks missing from InnerTube results'
)

build() {
    cd "$srcdir/$pkgname"

    # Disable LTO for the CXX bridge and final link. Arch's default LTO flags
    # can otherwise discard Rust bridge symbols during the final link.
    export CFLAGS="${CFLAGS:-} -fno-lto"
    export CXXFLAGS="${CXXFLAGS:-} -fno-lto"
    export LDFLAGS="${LDFLAGS:-} -fno-lto"

    pushd ui_web
    pnpm install --frozen-lockfile
    pnpm build
    popd

    cmake -B build-release -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build-release --parallel "$(nproc)"
}

package() {
    cd "$srcdir/$pkgname"
    DESTDIR="$pkgdir" cmake --install build-release

    install -Dm644 LICENSE-MIT "$pkgdir/usr/share/licenses/$pkgname/LICENSE-MIT"
    install -Dm644 LICENSE-APACHE "$pkgdir/usr/share/licenses/$pkgname/LICENSE-APACHE"
}
