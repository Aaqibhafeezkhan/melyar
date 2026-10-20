# Maintainer: mahmud
pkgname=melyar
pkgver=0.1.0
pkgrel=1
pkgdesc="Ultra-lightweight native YouTube Music desktop client in C++20 and Rust"
arch=('x86_64')
url="https://github.com/mahmud/melyar"
license=('MIT')
depends=('qt6-base' 'qt6-declarative' 'qt6-webengine' 'qt6-webchannel' 'mpv')
makedepends=('cmake' 'rust' 'cargo' 'pkgconf' 'corrosion')

build() {
    cd "$srcdir/.."
    export PATH="$HOME/.local/bin:$PATH"
    cmake -B build-release -S . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr
    cmake --build build-release -j$(nproc)
}

package() {
    cd "$srcdir/.."
    DESTDIR="$pkgdir" cmake --install build-release
}
