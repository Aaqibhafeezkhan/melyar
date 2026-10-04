// CXX Bridge C++ Implementation
// This file is compiled by cxx_build and provides the C++ side of the FFI bridge

#include "melyar_core.h"
#include <memory>

namespace melyar {

// SearchHandle implementation
std::unique_ptr<SearchHandle> SearchHandle::create(uint64_t id) {
    return std::make_unique<SearchHandle>(id);
}

SearchHandle::SearchHandle(uint64_t id_) : id(id_) {}

// PlaybackHandle implementation
std::unique_ptr<PlaybackHandle> PlaybackHandle::create(uint64_t id) {
    return std::make_unique<PlaybackHandle>(id);
}

PlaybackHandle::PlaybackHandle(uint64_t id_) : id(id_) {}

// LyricsHandle implementation
std::unique_ptr<LyricsHandle> LyricsHandle::create(uint64_t id) {
    return std::make_unique<LyricsHandle>(id);
}

LyricsHandle::LyricsHandle(uint64_t id_) : id(id_) {}

} // namespace melyar