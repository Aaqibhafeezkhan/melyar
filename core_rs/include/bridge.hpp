#pragma once
#include "rust/cxx.h"

namespace melyar {
    struct CxxTrackMetadata;

    void on_progress_update(double current, double total);
    void on_track_changed(CxxTrackMetadata track);
    void on_state_changed(bool is_playing);
    void on_lyrics_loaded(rust::String track_id, rust::String lyrics_lrc);
    void on_search_results(rust::Vec<CxxTrackMetadata> results);
}
