#include "bridge.hpp"

#include <QMetaObject>
#include <QtConcurrent/QtConcurrent>
#include <iostream>

#include "melyar_core/src/lib.rs.h"

MelyarBridge* MelyarBridge::s_instance = nullptr;

MelyarBridge* MelyarBridge::instance() {
    return s_instance;
}

MelyarBridge::MelyarBridge(QObject *parent) : QObject(parent) {
    s_instance = this;
    melyar::init_melyar_core();
    loadFavorites();
    loadHistory();
}

MelyarBridge::~MelyarBridge() {
    if (s_instance == this) {
        s_instance = nullptr;
    }
}

void MelyarBridge::search(const QString &query) {
    if (query.trimmed().isEmpty()) {
        return;
    }

    // Run async in background thread pool to ensure 0ms UI frame drops
    (void)QtConcurrent::run([this, query]() {
        rust::String r_query(query.toStdString());
        auto results = melyar::search(r_query);

        QVariantList q_results;
        for (const auto &item : results) {
            QVariantMap track;
            track["id"] = QString::fromStdString(std::string(item.id));
            track["title"] = QString::fromStdString(std::string(item.title));
            track["artist"] = QString::fromStdString(std::string(item.artist));
            track["album"] = QString::fromStdString(std::string(item.album));
            track["duration"] = item.duration_secs;
            track["thumbnail"] = QString::fromStdString(std::string(item.thumbnail_url));
            q_results.append(track);
        }

        QMetaObject::invokeMethod(this, [this, q_results]() {
            handleSearchResults(q_results);
        }, Qt::QueuedConnection);
    });
}

void MelyarBridge::playTrack(const QString &trackId) {
    (void)QtConcurrent::run([trackId]() {
        rust::String r_id(trackId.toStdString());
        melyar::play_track(r_id);
    });
}

void MelyarBridge::togglePlay() {
    melyar::toggle_play();
}

void MelyarBridge::seek(double seconds) {
    melyar::seek(seconds);
}

void MelyarBridge::setVolume(double volume) {
    if (m_volume != volume) {
        m_volume = volume;
        melyar::set_volume(volume);
        emit volumeChanged();
    }
}

void MelyarBridge::nextTrack() {
    melyar::next_track();
}

void MelyarBridge::previousTrack() {
    melyar::previous_track();
}

void MelyarBridge::toggleFavorite(const QString &trackId, const QString &title,
                                 const QString &artist, const QString &album,
                                 double duration, const QString &thumb) {
    bool fav = melyar::toggle_favorite(
        rust::String(trackId.toStdString()),
        rust::String(title.toStdString()),
        rust::String(artist.toStdString()),
        rust::String(album.toStdString()),
        duration,
        rust::String(thumb.toStdString())
    );
    Q_UNUSED(fav);
    loadFavorites();
}

bool MelyarBridge::isFavorite(const QString &trackId) {
    return melyar::is_favorite(rust::String(trackId.toStdString()));
}

void MelyarBridge::loadFavorites() {
    (void)QtConcurrent::run([this]() {
        auto favs = melyar::get_favorites();
        QVariantList q_favs;
        for (const auto &item : favs) {
            QVariantMap track;
            track["id"] = QString::fromStdString(std::string(item.id));
            track["title"] = QString::fromStdString(std::string(item.title));
            track["artist"] = QString::fromStdString(std::string(item.artist));
            track["album"] = QString::fromStdString(std::string(item.album));
            track["duration"] = item.duration_secs;
            track["thumbnail"] = QString::fromStdString(std::string(item.thumbnail_url));
            q_favs.append(track);
        }

        QMetaObject::invokeMethod(this, [this, q_favs]() {
            m_favorites = q_favs;
            emit favoritesChanged();
        }, Qt::QueuedConnection);
    });
}

void MelyarBridge::loadHistory() {
    (void)QtConcurrent::run([this]() {
        auto hist = melyar::get_history();
        QVariantList q_hist;
        for (const auto &item : hist) {
            QVariantMap track;
            track["id"] = QString::fromStdString(std::string(item.id));
            track["title"] = QString::fromStdString(std::string(item.title));
            track["artist"] = QString::fromStdString(std::string(item.artist));
            track["album"] = QString::fromStdString(std::string(item.album));
            track["duration"] = item.duration_secs;
            track["thumbnail"] = QString::fromStdString(std::string(item.thumbnail_url));
            q_hist.append(track);
        }

        QMetaObject::invokeMethod(this, [this, q_hist]() {
            m_history = q_hist;
            emit historyChanged();
        }, Qt::QueuedConnection);
    });
}

void MelyarBridge::fetchLyrics(const QString &trackId) {
    rust::String r_id(trackId.toStdString());
    auto lrc = melyar::fetch_lyrics(r_id);
    m_currentLyrics = QString::fromStdString(std::string(lrc));
    emit lyricsChanged();
}

void MelyarBridge::handleProgressUpdate(double current, double total) {
    m_currentPosition = current;
    if (total > 0.0) {
        m_currentDuration = total;
    }
    emit progressUpdated(current, total);
}

void MelyarBridge::handleTrackChanged(const QString &id, const QString &title,
                                     const QString &artist, const QString &album,
                                     double duration, const QString &thumb) {
    m_currentTrackId = id;
    m_currentTitle = title;
    m_currentArtist = artist;
    m_currentAlbum = album;
    m_currentDuration = duration;
    m_currentThumbnail = thumb;
    m_currentLyrics = "";
    emit currentTrackChanged();
    loadHistory();
}

void MelyarBridge::handleStateChanged(bool isPlaying) {
    if (m_isPlaying != isPlaying) {
        m_isPlaying = isPlaying;
        emit playbackStateChanged(isPlaying);
    }
}

void MelyarBridge::handleLyricsLoaded(const QString &trackId, const QString &lrc) {
    if (m_currentTrackId == trackId) {
        m_currentLyrics = lrc;
        emit lyricsChanged();
    }
}

void MelyarBridge::handleSearchResults(const QVariantList &results) {
    m_searchResults = results;
    emit searchResultsChanged();
}

// ----------------------------------------------------------------------------
// CXX Callbacks from Rust
// ----------------------------------------------------------------------------

namespace melyar {

void on_progress_update(double current, double total) {
    auto *b = MelyarBridge::instance();
    if (b) {
        QMetaObject::invokeMethod(b, [b, current, total]() {
            b->handleProgressUpdate(current, total);
        }, Qt::QueuedConnection);
    }
}

void on_track_changed(CxxTrackMetadata track) {
    auto *b = MelyarBridge::instance();
    if (b) {
        QString id = QString::fromStdString(std::string(track.id));
        QString title = QString::fromStdString(std::string(track.title));
        QString artist = QString::fromStdString(std::string(track.artist));
        QString album = QString::fromStdString(std::string(track.album));
        double dur = track.duration_secs;
        QString thumb = QString::fromStdString(std::string(track.thumbnail_url));

        QMetaObject::invokeMethod(b, [b, id, title, artist, album, dur, thumb]() {
            b->handleTrackChanged(id, title, artist, album, dur, thumb);
        }, Qt::QueuedConnection);
    }
}

void on_state_changed(bool is_playing) {
    auto *b = MelyarBridge::instance();
    if (b) {
        QMetaObject::invokeMethod(b, [b, is_playing]() {
            b->handleStateChanged(is_playing);
        }, Qt::QueuedConnection);
    }
}

void on_lyrics_loaded(rust::String track_id, rust::String lyrics_lrc) {
    auto *b = MelyarBridge::instance();
    if (b) {
        QString q_id = QString::fromStdString(std::string(track_id));
        QString q_lrc = QString::fromStdString(std::string(lyrics_lrc));

        QMetaObject::invokeMethod(b, [b, q_id, q_lrc]() {
            b->handleLyricsLoaded(q_id, q_lrc);
        }, Qt::QueuedConnection);
    }
}

void on_search_results(rust::Vec<CxxTrackMetadata> results) {
    auto *b = MelyarBridge::instance();
    if (b) {
        QVariantList q_list;
        for (const auto &item : results) {
            QVariantMap track;
            track["id"] = QString::fromStdString(std::string(item.id));
            track["title"] = QString::fromStdString(std::string(item.title));
            track["artist"] = QString::fromStdString(std::string(item.artist));
            track["album"] = QString::fromStdString(std::string(item.album));
            track["duration"] = item.duration_secs;
            track["thumbnail"] = QString::fromStdString(std::string(item.thumbnail_url));
            q_list.append(track);
        }

        QMetaObject::invokeMethod(b, [b, q_list]() {
            b->handleSearchResults(q_list);
        }, Qt::QueuedConnection);
    }
}

} // namespace melyar
