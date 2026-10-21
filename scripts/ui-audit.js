/*
 * Interface audit.
 *
 * Drives the interface through every view and every overlay, then reports
 * what is wrong: a console error, an element that reaches outside the
 * window, a translation key that was never replaced, an interactive element
 * without an accessible name, a view that renders nothing.
 *
 * It also pushes deliberately awkward data through the interface, a title
 * long enough to break any layout and a track with no artwork, because
 * those are what a real library contains.
 *
 * Run it with:
 *
 *   MELYAR_EVAL_FILE=scripts/ui-audit.js ./build/melyar
 *
 * The application prints "DENETIM_SONUCU problems=0" when the interface is
 * clean, and the continuous integration fails when it is not.
 */
(function () {
  const problems = [];
  const note = (kind, detail) => problems.push(kind + ": " + detail);

  const originalError = console.error;
  console.error = function () {
    note("console.error", Array.prototype.map.call(arguments, String).join(" ").slice(0, 200));
    originalError.apply(console, arguments);
  };
  window.addEventListener("error", (e) => note("uncaught", String(e.message).slice(0, 200)));
  window.addEventListener("unhandledrejection", (e) => note("unhandled", String(e.reason).slice(0, 200)));

  // An element inside a horizontal scroller is allowed to reach past the
  // edge of the window, that is what a scroller is for.
  function inScroller(el) {
    let p = el.parentElement;
    while (p) {
      const s = getComputedStyle(p);
      if (s.overflowX === "auto" || s.overflowX === "scroll" || s.overflowX === "hidden") return true;
      p = p.parentElement;
    }
    return false;
  }

  function checkOverflow(tag) {
    const w = window.innerWidth;
    const bad = Array.prototype.slice.call(document.querySelectorAll("*")).filter((el) => {
      const r = el.getBoundingClientRect();
      if (r.width <= 0 || r.width >= w * 2) return false;
      if (r.right <= w + 2 && r.left >= -2) return false;
      return !inScroller(el);
    });
    if (bad.length) {
      const b = bad[0];
      note(
        "overflow",
        tag + ": " + bad.length + " elements reach outside the window, first <" +
          b.tagName + " class=" + String(b.className).slice(0, 70) + ">",
      );
    }
  }

  function checkText(tag) {
    const keys = Array.prototype.slice
      .call(document.querySelectorAll("*"))
      .filter((el) => el.children.length === 0)
      .map((el) => (el.textContent || "").trim())
      .filter((t) => /^[a-z]+(\.[a-zA-Z]+)+$/.test(t));
    if (keys.length) note("missing-translation", tag + ": " + Array.from(new Set(keys)).join(", "));
  }

  function checkAccessibleNames(tag) {
    const unnamed = Array.prototype.slice
      .call(document.querySelectorAll("button, a, input, [role=button]"))
      .filter((el) => {
        if (el.getAttribute("aria-hidden") === "true") return false;
        if (el.getAttribute("aria-label")) return false;
        if ((el.textContent || "").trim()) return false;
        if (el.getAttribute("title")) return false;
        if (el.getAttribute("placeholder")) return false;
        const labelled = el.getAttribute("aria-labelledby");
        if (labelled && document.getElementById(labelled)) return false;
        return true;
      });
    if (unnamed.length) {
      note(
        "no-accessible-name",
        tag + ": " + unnamed.length + " interactive elements have no accessible name, first class=" +
          String(unnamed[0].className).slice(0, 70),
      );
    }
  }

  // The contrast of the text against what is behind it. A light surface with
  // light text is invisible, and the browser engine does not always blur
  // what is behind a panel, so this has to be checked rather than assumed.
  //
  // The colours have to be read carefully. Tailwind writes its tints in
  // oklab() and color-mix(), so a plain regex over rgb() finds nothing and
  // the measurement ends up against the wrong background. The engine does
  // not always normalise either: this QtWebEngine hands oklab() back
  // untouched, so it is read here.
  const colourContext = document.createElement("canvas").getContext("2d");

  /** Convert a colour in oklab to sRGB, per the CSS colour specification. */
  function oklabToSrgb(L, a, b, alpha) {
    const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    const s_ = L - 0.0894841775 * a - 1.291485548 * b;
    const l = l_ * l_ * l_;
    const m = m_ * m_ * m_;
    const s = s_ * s_ * s_;
    const enc = (v) => {
      const c = Math.max(0, Math.min(1, v));
      return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
    };
    return {
      r: enc(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s) * 255,
      g: enc(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s) * 255,
      b: enc(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s) * 255,
      a: alpha,
    };
  }

  function parseColor(value) {
    if (!value) return null;

    // oklab, which is what Tailwind writes its tints in.
    const oklab = /oklab\(\s*(-?[\d.eE+-]+)[,\s]+(-?[\d.eE+-]+)[,\s]+(-?[\d.eE+-]+)\s*(?:\/\s*([\d.]+)(%?)\s*)?\)/i.exec(
      value,
    );
    if (oklab) {
      let alpha = 1;
      if (oklab[4] !== undefined) {
        alpha = parseFloat(oklab[4]);
        if (oklab[5] === "%") alpha /= 100;
      }
      return oklabToSrgb(
        parseFloat(oklab[1]),
        parseFloat(oklab[2]),
        parseFloat(oklab[3]),
        alpha,
      );
    }

    // The common case, and the one that needs the alpha.
    const m = /rgba?\(([^)]+)\)/.exec(value);
    if (m) {
      const parts = m[1].split(/[,/\s]+/).filter(Boolean).map(parseFloat);
      if (parts.length >= 3 && !parts.some((p) => Number.isNaN(p))) {
        return { r: parts[0], g: parts[1], b: parts[2], a: parts.length > 3 ? parts[3] : 1 };
      }
    }

    // Anything else, let the engine work it out.
    try {
      colourContext.fillStyle = "#000000";
      colourContext.fillStyle = value;
      const normalised = colourContext.fillStyle;
      if (normalised && normalised !== value) {
        const n = /rgba?\(([^)]+)\)/.exec(normalised);
        if (n) {
          const parts = n[1].split(/[,/\s]+/).filter(Boolean).map(parseFloat);
          if (parts.length >= 3) {
            return { r: parts[0], g: parts[1], b: parts[2], a: parts.length > 3 ? parts[3] : 1 };
          }
        }
        const hex = /^#([0-9a-f]{6})$/i.exec(normalised);
        if (hex) {
          return {
            r: parseInt(hex[1].slice(0, 2), 16),
            g: parseInt(hex[1].slice(2, 4), 16),
            b: parseInt(hex[1].slice(4, 6), 16),
            a: 1,
          };
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  function blend(top, bottom) {
    const a = top.a;
    return {
      r: top.r * a + bottom.r * (1 - a),
      g: top.g * a + bottom.g * (1 - a),
      b: top.b * a + bottom.b * (1 - a),
      a: 1,
    };
  }

  function luminance(c) {
    const f = (v) => {
      const s = v / 255;
      return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
  }

  function contrast(a, b) {
    const la = luminance(a);
    const lb = luminance(b);
    const lighter = Math.max(la, lb);
    const darker = Math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /**
   * The colour behind an element: every layer between it and the first
   * opaque one, composited together. The layers come back as well, so a
   * measurement that looks wrong can be read rather than guessed at.
   */
  function backgroundBehind(el) {
    const layers = [];
    const labels = [];
    let node = el;
    while (node) {
      const bg = parseColor(getComputedStyle(node).backgroundColor);
      if (bg && bg.a > 0) {
        layers.push(bg);
        labels.push(
          String(node.className || node.tagName).slice(0, 26) + " @" + bg.a.toFixed(2),
        );
        if (bg.a >= 0.99) break;
      }
      node = node.parentElement;
    }
    let result = { r: 255, g: 255, b: 255, a: 1 };
    for (let i = layers.length - 1; i >= 0; i -= 1) {
      result = blend(layers[i], result);
    }
    result.over = labels.join(" over ") || "the page default";
    return result;
  }

  function checkContrast(tag) {
    const texts = Array.prototype.slice
      .call(document.querySelectorAll("*"))
      .filter((el) => {
        if (el.children.length > 0) return false;
        if (!(el.textContent || "").trim()) return false;
        if (el.getAttribute("aria-hidden") === "true") return false;
        const rect = el.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
      });

    const bad = [];
    texts.forEach((el) => {
      const style = getComputedStyle(el);
      if (style.visibility === "hidden" || style.opacity === "0") return;
      const fg = parseColor(style.color);
      if (!fg || fg.a === 0) return;
      const bg = backgroundBehind(el);
      const ratio = contrast(fg.a < 1 ? blend(fg, bg) : fg, bg);
      if (ratio < 2.4) {
        bad.push(
          (el.textContent || "").trim().slice(0, 24) +
            " (ratio " +
            ratio.toFixed(1) +
            ", color " +
            style.color +
            ", behind rgb(" +
            [bg.r, bg.g, bg.b].map((v) => Math.round(v)).join(", ") +
            ") from " +
            bg.over +
            ", class " +
            String(el.className).slice(0, 40) +
            ")",
        );
      }
    });

    if (bad.length) {
      const unique = Array.from(new Set(bad));
      note(
        "low-contrast",
        tag + ": " + unique.length + " pieces of text are hard to read, first: " + unique[0],
      );
    }
  }

  const steps = [];

  function view(name, needsHeading) {
    steps.push([
      "view:" + name,
      function () { window.__navigate(name); },
      function () {
        const cs = document.querySelector(".content-scroll");
        if (!cs) { note("no-view", name + ": the view did not render"); return; }
        if (needsHeading) {
          const h1 = cs.querySelector("h1");
          if (!h1 || !(h1.textContent || "").trim()) note("missing-heading", name + ": no heading");
        }
        if (cs.textContent.trim().length < 10) note("empty-view", name + ": nothing rendered");
      },
    ]);
  }

  view("home", true);
  view("songs", true);
  view("liked", true);
  view("history", true);
  view("albums", true);
  view("artists", true);
  view("search", false);

  steps.push([
    "settings",
    function () {
      // The equaliser bands are only shown once the equaliser is on, so it
      // has to be turned on before the panel is checked.
      window.__testSetSetting("equalizerEnabled", "true");
      window.bridge.openUri("melyar://settings");
    },
    function () {
      const panel = document.querySelector(".settings-panel");
      if (!panel) { note("no-panel", "settings: the panel did not open"); return; }
      const labels = Array.prototype.slice
        .call(panel.querySelectorAll("h3"))
        .map((e) => (e.textContent || "").trim());
      ["Appearance", "Playback", "Interface", "Advanced"].forEach((want) => {
        if (labels.indexOf(want) === -1) {
          note("missing-section", "settings: no '" + want + "' section, found: " + labels.join(", "));
        }
      });
      const sliders = panel.querySelectorAll("input[type=range]").length;
      if (sliders < 10) note("missing-equalizer", "settings: the equaliser bands are missing (" + sliders + ")");
    },
  ]);

  steps.push([
    "context-menu",
    function () {
      // The menu needs a track to open on, and the library is empty in a
      // clean profile.
      window.__testSetState({
        results: [{
          id: "audit-menu", title: "A Track For The Menu", artist: "Someone",
          album: "An Album", duration: 200, thumbnail: "",
        }],
      });
      window.__openMenuOnFirstTrack();
    },
    function () {
      if (!window.__testState().menuOpen) note("no-menu", "context-menu: it did not open");
    },
  ]);
  steps.push([
    "expanded",
    function () { window.__openExpandedPlayer(); },
    function () {
      if (!window.__testState().expandedPlayerOpen) note("no-overlay", "expanded: it did not open");
    },
  ]);
  steps.push([
    "lyrics",
    function () { window.__openLyrics(); },
    function () {
      if (!window.__testState().lyricsOpen) note("no-overlay", "lyrics: it did not open");
    },
  ]);
  steps.push([
    "queue",
    function () { window.__openQueue(); },
    function () {
      if (!window.__testState().queueOpen) note("no-overlay", "queue: it did not open");
    },
  ]);

  // Awkward data. A title this long has to be truncated rather than push
  // the layout apart, and a track with no artwork has to fall back to the
  // placeholder instead of leaving a hole.
  const awkward = {
    id: "audit-edge-case",
    title:
      "An Extremely Long Track Title That Has To Be Truncated Rather Than Pushing The Layout Apart In Every Single Row Of The Table",
    artist: "A Collaborating Artist With A Really Unreasonably Long Name That Goes On And On And On",
    album: "Also An Unusually Long Album Name Here To Make Sure That One Is Handled As Well",
    duration: 245,
    thumbnail: "",
  };
  steps.push([
    "awkward-data",
    function () {
      window.__testSetState({
        results: [awkward],
        liked: [awkward],
        history: [awkward],
        queue: [awkward],
        current: awkward,
      });
      window.__navigate("songs");
    },
    null,
  ]);
  steps.push([
    "search-with-results",
    function () { window.__testSearch("daft punk"); },
    function () {
      setTimeout(function () {
        const s = window.__testState();
        if (!s.results || s.results.length === 0) {
          note("no-results", "the search returned nothing");
        } else {
          const bad = s.results.filter((t) => !t.title || !t.artist);
          if (bad.length) note("incomplete-track", bad.length + " results have no title or artist");
        }
      }, 3000);
    },
  ]);

  let index = 0;
  function next() {
    if (index >= steps.length) {
      // The light theme is checked as well, because the surfaces that float
      // over the page were drawn for the dark one.
      if (window.__setTheme) {
        window.__setTheme("light");
        setTimeout(function () {
          try {
            checkOverflow("light-theme");
            checkText("light-theme");
            checkAccessibleNames("light-theme");
            checkContrast("light-theme");
          } catch (e) {
            note("check", "light-theme: " + String(e).slice(0, 110));
          }
          finish();
        }, 900);
      } else {
        finish();
      }
      return;
    }
    const step = steps[index++];
    try {
      step[1]();
    } catch (e) {
      note("threw", step[0] + ": " + String(e).slice(0, 140));
    }
    setTimeout(function () {
      try {
        checkOverflow(step[0]);
        checkText(step[0]);
        checkAccessibleNames(step[0]);
        checkContrast(step[0]);
        if (step[2]) step[2]();
      } catch (e) {
        note("check", step[0] + ": " + String(e).slice(0, 110));
      }
      next();
    }, 900);
  }

  function finish() {
    setTimeout(function () {
      const unique = Array.from(new Set(problems));
      console.log("DENETIM_SONUCU problems=" + unique.length);
      unique.forEach((p) => console.log("  SORUN: " + p));
      if (unique.length === 0) console.log("  SORUN YOK");
      window.bridge.quit();
    }, 1200);
  }

  setTimeout(next, 1200);
})();
