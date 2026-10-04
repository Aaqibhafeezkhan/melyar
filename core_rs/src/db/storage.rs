use anyhow::Result;
use parking_lot::Mutex;
use rusqlite::{params, Connection};
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::ffi::CxxTrackMetadata;

pub struct DbStorage {
    conn: Mutex<Connection>,
}

impl DbStorage {
    pub fn new() -> Result<Self> {
        let db_path = Self::get_db_path()?;
        if let Some(parent) = db_path.parent() {
            fs::create_dir_all(parent)?;
        }

        let conn = Connection::open(&db_path)?;

        // WAL mode returns a row in SQLite, so query_row consumes it without error
        let _ = conn.query_row("PRAGMA journal_mode = WAL;", [], |_| Ok(()));

        // Schema & performance tuning
        conn.execute_batch(
            "PRAGMA synchronous = NORMAL;
             PRAGMA foreign_keys = ON;
             PRAGMA temp_store = MEMORY;
             PRAGMA cache_size = -2000;

             CREATE TABLE IF NOT EXISTS history (
                 track_id TEXT PRIMARY KEY,
                 title TEXT NOT NULL,
                 artist TEXT NOT NULL,
                 album TEXT NOT NULL,
                 duration REAL NOT NULL,
                 thumbnail TEXT NOT NULL,
                 played_at INTEGER NOT NULL
             );

             CREATE TABLE IF NOT EXISTS favorites (
                 track_id TEXT PRIMARY KEY,
                 title TEXT NOT NULL,
                 artist TEXT NOT NULL,
                 album TEXT NOT NULL,
                 duration REAL NOT NULL,
                 thumbnail TEXT NOT NULL,
                 added_at INTEGER NOT NULL
             );

             CREATE TABLE IF NOT EXISTS lyrics_cache (
                 track_id TEXT PRIMARY KEY,
                 lrc TEXT NOT NULL,
                 cached_at INTEGER NOT NULL
             );",
        )?;

        Ok(Self {
            conn: Mutex::new(conn),
        })
    }

    fn get_db_path() -> Result<PathBuf> {
        if let Some(data_dir) = dirs::data_dir() {
            Ok(data_dir.join("melyar").join("melyar.db"))
        } else {
            let home = std::env::var("HOME").unwrap_or_else(|_| ".".into());
            Ok(PathBuf::from(home).join(".local/share/melyar/melyar.db"))
        }
    }

    fn current_timestamp() -> i64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs() as i64
    }

    pub fn add_history(&self, track: &CxxTrackMetadata) -> Result<()> {
        let conn = self.conn.lock();
        let now = Self::current_timestamp();
        conn.execute(
            "INSERT INTO history (track_id, title, artist, album, duration, thumbnail, played_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(track_id) DO UPDATE SET
                 played_at = ?7,
                 title = ?2,
                 artist = ?3,
                 album = ?4,
                 duration = ?5,
                 thumbnail = ?6",
            params![
                track.id,
                track.title,
                track.artist,
                track.album,
                track.duration_secs,
                track.thumbnail_url,
                now
            ],
        )?;
        Ok(())
    }

    pub fn get_history(&self, limit: usize) -> Result<Vec<CxxTrackMetadata>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT track_id, title, artist, album, duration, thumbnail
             FROM history ORDER BY played_at DESC LIMIT ?1",
        )?;

        let rows = stmt.query_map(params![limit as i64], |row| {
            Ok(CxxTrackMetadata {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                album: row.get(3)?,
                duration_secs: row.get(4)?,
                thumbnail_url: row.get(5)?,
                lyrics: String::new(),
            })
        })?;

        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn toggle_favorite(&self, track: &CxxTrackMetadata) -> Result<bool> {
        let conn = self.conn.lock();
        let mut check_stmt = conn.prepare("SELECT 1 FROM favorites WHERE track_id = ?1")?;
        let exists = check_stmt.exists(params![track.id])?;

        if exists {
            conn.execute("DELETE FROM favorites WHERE track_id = ?1", params![track.id])?;
            Ok(false)
        } else {
            let now = Self::current_timestamp();
            conn.execute(
                "INSERT INTO favorites (track_id, title, artist, album, duration, thumbnail, added_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
                params![
                    track.id,
                    track.title,
                    track.artist,
                    track.album,
                    track.duration_secs,
                    track.thumbnail_url,
                    now
                ],
            )?;
            Ok(true)
        }
    }

    pub fn is_favorite(&self, track_id: &str) -> Result<bool> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare("SELECT 1 FROM favorites WHERE track_id = ?1")?;
        Ok(stmt.exists(params![track_id])?)
    }

    pub fn get_favorites(&self) -> Result<Vec<CxxTrackMetadata>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare(
            "SELECT track_id, title, artist, album, duration, thumbnail
             FROM favorites ORDER BY added_at DESC",
        )?;

        let rows = stmt.query_map([], |row| {
            Ok(CxxTrackMetadata {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                album: row.get(3)?,
                duration_secs: row.get(4)?,
                thumbnail_url: row.get(5)?,
                lyrics: String::new(),
            })
        })?;

        let mut result = Vec::new();
        for r in rows {
            result.push(r?);
        }
        Ok(result)
    }

    pub fn get_cached_lyrics(&self, track_id: &str) -> Result<Option<String>> {
        let conn = self.conn.lock();
        let mut stmt = conn.prepare("SELECT lrc FROM lyrics_cache WHERE track_id = ?1")?;
        let mut rows = stmt.query(params![track_id])?;
        if let Some(row) = rows.next()? {
            Ok(Some(row.get(0)?))
        } else {
            Ok(None)
        }
    }

    pub fn cache_lyrics(&self, track_id: &str, lrc: &str) -> Result<()> {
        let conn = self.conn.lock();
        let now = Self::current_timestamp();
        conn.execute(
            "INSERT INTO lyrics_cache (track_id, lrc, cached_at)
             VALUES (?1, ?2, ?3)
             ON CONFLICT(track_id) DO UPDATE SET lrc = ?2, cached_at = ?3",
            params![track_id, lrc, now],
        )?;
        Ok(())
    }

    #[cfg(test)]
    pub fn new_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let _ = conn.query_row("PRAGMA journal_mode = WAL;", [], |_| Ok(()));
        conn.execute_batch(
            "PRAGMA synchronous = NORMAL;
             PRAGMA foreign_keys = ON;
             PRAGMA temp_store = MEMORY;

             CREATE TABLE IF NOT EXISTS history (
                 track_id TEXT PRIMARY KEY,
                 title TEXT NOT NULL,
                 artist TEXT NOT NULL,
                 album TEXT NOT NULL,
                 duration REAL NOT NULL,
                 thumbnail TEXT NOT NULL,
                 played_at INTEGER NOT NULL
             );

             CREATE TABLE IF NOT EXISTS favorites (
                 track_id TEXT PRIMARY KEY,
                 title TEXT NOT NULL,
                 artist TEXT NOT NULL,
                 album TEXT NOT NULL,
                 duration REAL NOT NULL,
                 thumbnail TEXT NOT NULL,
                 added_at INTEGER NOT NULL
             );

             CREATE TABLE IF NOT EXISTS lyrics_cache (
                 track_id TEXT PRIMARY KEY,
                 lrc TEXT NOT NULL,
                 cached_at INTEGER NOT NULL
             );",
        )?;

        Ok(Self {
            conn: Mutex::new(conn),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_storage_history() {
        let storage = DbStorage::new_in_memory().unwrap();
        let track = CxxTrackMetadata {
            id: "track1".to_string(),
            title: "Song A".to_string(),
            artist: "Artist A".to_string(),
            album: "Album A".to_string(),
            duration_secs: 180.0,
            thumbnail_url: "https://example.com/1.jpg".to_string(),
            lyrics: String::new(),
        };

        storage.add_history(&track).unwrap();
        let history = storage.get_history(10).unwrap();
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].id, "track1");
        assert_eq!(history[0].title, "Song A");
        assert_eq!(history[0].artist, "Artist A");
        assert_eq!(history[0].duration_secs, 180.0);
    }

    #[test]
    fn test_storage_favorites() {
        let storage = DbStorage::new_in_memory().unwrap();
        let track = CxxTrackMetadata {
            id: "fav1".to_string(),
            title: "Fav Song".to_string(),
            artist: "Fav Artist".to_string(),
            album: "Fav Album".to_string(),
            duration_secs: 240.0,
            thumbnail_url: "https://example.com/fav.jpg".to_string(),
            lyrics: String::new(),
        };

        assert!(!storage.is_favorite("fav1").unwrap());
        let toggled_on = storage.toggle_favorite(&track).unwrap();
        assert!(toggled_on);
        assert!(storage.is_favorite("fav1").unwrap());

        let favs = storage.get_favorites().unwrap();
        assert_eq!(favs.len(), 1);
        assert_eq!(favs[0].id, "fav1");

        let toggled_off = storage.toggle_favorite(&track).unwrap();
        assert!(!toggled_off);
        assert!(!storage.is_favorite("fav1").unwrap());
        assert!(storage.get_favorites().unwrap().is_empty());
    }

    #[test]
    fn test_lyrics_cache() {
        let storage = DbStorage::new_in_memory().unwrap();
        assert!(storage.get_cached_lyrics("song123").unwrap().is_none());

        storage.cache_lyrics("song123", "[00:10.00] Line 1").unwrap();
        let lyrics = storage.get_cached_lyrics("song123").unwrap();
        assert_eq!(lyrics, Some("[00:10.00] Line 1".to_string()));
    }
}