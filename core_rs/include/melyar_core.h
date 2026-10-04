// CXX Bridge Header - This is what cxx generates
// Normally auto-generated, but we need it for the build

#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace melyar {

struct TrackMetadata {
    std::string video_id;
    std::string title;
    std::string artist;
    std::string album;
    uint32_t duration_seconds;
    std::string thumbnail_url;
    bool is_explicit;
};

struct SearchResult {
    std::vector<TrackMetadata> tracks;
    std::string continuation_token;
};

struct LyricsLine {
    uint64_t timestamp_ms;
    std::string text;
};

struct SyncedLyrics {
    std::string track_id;
    std::vector<LyricsLine> lines;
    std::string source;
};

struct PlaybackState {
    bool is_playing;
    uint64_t current_position_ms;
    uint64_t total_duration_ms;
    float volume;
    std::unique_ptr<TrackMetadata> track;
};

// Opaque handles
class SearchHandle {
public:
    static std::unique_ptr<SearchHandle> create(uint64_t id);
    uint64_t id() const;
private:
    SearchHandle(uint64_t id);
    uint64_t id_;
};

class PlaybackHandle {
public:
    static std::unique_ptr<PlaybackHandle> create(uint64_t id);
    uint64_t id() const;
private:
    PlaybackHandle(uint64_t id);
    uint64_t id_;
};

class LyricsHandle {
public:
    static std::unique_ptr<LyricsHandle> create(uint64_t id);
    uint64_t id() const;
private:
    LyricsHandle(uint64_t id);
    uint64_t id_;
};

// Event listener interface (implemented by C++)
class EventListener {
public:
    virtual ~EventListener() = default;
    virtual void on_track_changed(const TrackMetadata& track) = 0;
    virtual void on_playback_state_changed(const PlaybackState& state) = 0;
    virtual void on_progress_update(uint64_t current_ms, uint64_t total_ms) = 0;
    virtual void on_lyrics_ready(const SyncedLyrics& lyrics) = 0;
    virtual void on_error(const std::string& error) = 0;
};

// Rust engine opaque type
class MelyarEngine {
public:
    static std::unique_ptr<MelyarEngine> create();
    ~MelyarEngine();

    std::unique_ptr<SearchHandle> search_tracks(const std::string& query);
    SearchResult search_next_page(const SearchHandle& handle);
    void search_cancel(const SearchHandle& handle);

    std::unique_ptr<PlaybackHandle> play_track(const std::string& track_id);
    bool toggle_play(const PlaybackHandle& handle);
    void seek(const PlaybackHandle& handle, uint64_t position_ms);
    void set_volume(const PlaybackHandle& handle, float volume);
    void next_track(const PlaybackHandle& handle);
    void previous_track(const PlaybackHandle& handle);
    PlaybackState get_playback_state(const PlaybackHandle& handle);

    std::unique_ptr<LyricsHandle> fetch_lyrics(const std::string& track_id);
    SyncedLyrics get_lyrics(const LyricsHandle& handle);

    void set_event_listener(EventListener* listener);

private:
    MelyarEngine();
    void* impl_; // Opaque pointer to Rust engine
};

} // namespace melyar