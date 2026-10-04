# Melyar Waybar & Status Bar IPC Entegrasyonu

Melyar, Linux durum çubukları (Waybar, Polybar, Hyprland, i3status) için sıfır gecikmeli Unix Domain Socket IPC sunucusu barındırır.
Soket otomatik olarak `$XDG_RUNTIME_DIR/melyar.sock` (veya `/tmp/melyar.sock`) adresinde dinlemeye başlar.

---

## 1. Waybar Yapılandırması (`~/.config/waybar/config.jsonc`)

Waybar konfigürasyonunuza aşağıdaki özel modülü ekleyin:

```jsonc
"custom/melyar": {
    "format": "{icon} {}",
    "return-type": "json",
    "max-length": 45,
    "format-icons": {
        "playing": "",
        "paused": "",
        "stopped": ""
    },
    "exec": "socat -u UNIX-CONNECT:${XDG_RUNTIME_DIR:-/tmp}/melyar.sock -",
    "on-click": "echo toggle | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "on-click-right": "echo next | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "on-click-middle": "echo prev | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "interval": 1
}
```

Modülü bar diziliminize ekleyin:
```jsonc
"modules-center": ["custom/melyar"]
```

---

## 2. Waybar CSS Stili (`~/.config/waybar/style.css`)

```css
#custom-melyar {
    background-color: #181818;
    color: #1DB954;
    padding: 0 12px;
    margin: 4px 6px;
    border-radius: 14px;
    border: 1px solid #282828;
    font-weight: 500;
}

#custom-melyar.playing {
    color: #1ED760;
    border-color: #1DB954;
}

#custom-melyar.paused {
    color: #b3b3b3;
    border-color: #3e3e3e;
}

#custom-melyar.stopped {
    color: #727272;
}
```

---

## 3. Komut Satırından Hızlı Kontrol (CLI / Kısayol)

Terminalden veya Hyprland/Sway `bind` kuralları ile kontrol:

```bash
# Oynat / Duraklat
echo toggle | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock

# Sonraki Şarkı
echo next | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock

# Önceki Şarkı
echo prev | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock

# Çalmayı Durdur
echo stop | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock
```

Hyprland için kısayol örneği (`~/.config/hypr/hyprland.conf`):
```ini
bind = , XF86AudioPlay, exec, echo toggle | nc -U $XDG_RUNTIME_DIR/melyar.sock
bind = , XF86AudioNext, exec, echo next | nc -U $XDG_RUNTIME_DIR/melyar.sock
bind = , XF86AudioPrev, exec, echo prev | nc -U $XDG_RUNTIME_DIR/melyar.sock
```
