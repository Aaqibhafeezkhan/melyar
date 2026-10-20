/**
 * Melyar Liquid Glass Motion System
 * Merkezi hareket token'ları ve yardımcı fonksiyonlar
 * Referans: kaset (SwiftUI) + vue-web-liquid-glass
 */

// ============================================================
// MOTION TOKENS — CSS Variable karşılıkları
// ============================================================

export const motionTokens = {
  // Duration (ms)
  duration: {
    instant: 0,
    press: 120,        // Press feedback
    hover: 160,        // Hover transition
    toggle: 200,       // Toggle state change
    morph: 300,        // Shared glass morph
    search: 280,       // Search expansion
    overlay: 240,      // Small overlay
    panel: 380,        // Panel entry/exit
    expanded: 420,     // Expanded player
    artwork: 500,      // Artwork transition
  } as const,

  // Easing curves
  easing: {
    // Kaset: cubic-bezier(0.2, 1, 0.3, 1) - quick settle
    standard: 'cubic-bezier(0.22, 1, 0.36, 1)',
    // Interactive: responsive, slight overshoot
    interactive: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    // Morph: controlled, no bounce
    morph: 'cubic-bezier(0.25, 0.46, 0.45, 0.94)',
    // Panel: smooth entry/exit
    panel: 'cubic-bezier(0.32, 0.72, 0, 1)',
    // Spring: subtle elasticity for morph
    spring: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    // Linear for progress
    linear: 'linear',
  } as const,

  // Composite transitions
  transition: {
    press: 'transform 120ms cubic-bezier(0.34, 1.56, 0.64, 1)',
    hover: 'background 160ms cubic-bezier(0.22, 1, 0.36, 1), border-color 160ms cubic-bezier(0.22, 1, 0.36, 1), box-shadow 160ms cubic-bezier(0.22, 1, 0.36, 1)',
    toggle: 'background 200ms cubic-bezier(0.25, 0.46, 0.45, 0.94), border-color 200ms cubic-bezier(0.25, 0.46, 0.45, 0.94), color 200ms cubic-bezier(0.25, 0.46, 0.45, 0.94)',
    morph: 'transform 300ms cubic-bezier(0.25, 0.46, 0.45, 0.94), width 300ms cubic-bezier(0.25, 0.46, 0.45, 0.94), height 300ms cubic-bezier(0.25, 0.46, 0.45, 0.94), border-radius 300ms cubic-bezier(0.25, 0.46, 0.45, 0.94), box-shadow 300ms cubic-bezier(0.25, 0.46, 0.45, 0.94)',
    search: 'width 280ms cubic-bezier(0.22, 1, 0.36, 1), opacity 200ms cubic-bezier(0.22, 1, 0.36, 1)',
    panel: 'transform 380ms cubic-bezier(0.32, 0.72, 0, 1), opacity 300ms cubic-bezier(0.32, 0.72, 0, 1)',
    overlay: 'transform 240ms cubic-bezier(0.32, 0.72, 0, 1), opacity 200ms cubic-bezier(0.32, 0.72, 0, 1)',
    expanded: 'transform 420ms cubic-bezier(0.32, 0.72, 0, 1), opacity 350ms cubic-bezier(0.32, 0.72, 0, 1)',
    artwork: 'transform 500ms cubic-bezier(0.22, 1, 0.36, 1), border-radius 500ms cubic-bezier(0.22, 1, 0.36, 1), box-shadow 500ms cubic-bezier(0.22, 1, 0.36, 1)',
  } as const,
} as const;

// ============================================================
// REDUCED MOTION TOKENS
// ============================================================

export const reducedMotionTokens = {
  duration: {
    instant: 0,
    press: 0,
    hover: 0,
    toggle: 50,
    morph: 100,
    search: 100,
    overlay: 100,
    panel: 150,
    expanded: 150,
    artwork: 200,
  },
  easing: {
    standard: 'linear',
    interactive: 'linear',
    morph: 'linear',
    panel: 'linear',
    spring: 'linear',
    linear: 'linear',
  },
  transition: {
    press: 'transform 0ms linear',
    hover: 'background 0ms linear, border-color 0ms linear, box-shadow 0ms linear',
    toggle: 'background 50ms linear, border-color 50ms linear, color 50ms linear',
    morph: 'transform 100ms linear, width 100ms linear, height 100ms linear, border-radius 100ms linear',
    search: 'width 100ms linear, opacity 100ms linear',
    panel: 'transform 150ms linear, opacity 150ms linear',
    overlay: 'transform 100ms linear, opacity 100ms linear',
    expanded: 'transform 150ms linear, opacity 150ms linear',
    artwork: 'transform 200ms linear, border-radius 200ms linear',
  },
} as const;

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Reduced motion kontrolü
 */
export function prefersReducedMotion(): boolean {
  if (typeof window === 'undefined') return false;
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * Motion token'ları alır (reduced motionaware)
 */
export function getMotionTokens() {
  return prefersReducedMotion() ? reducedMotionTokens : motionTokens;
}

/**
 * CSS transition string'i oluşturur
 */
export function createTransition(
  properties: string | string[],
  type: keyof typeof motionTokens.transition = 'hover'
): string {
  const props = Array.isArray(properties) ? properties : [properties];
  const tokens = getMotionTokens();
  // Fallback to standard if specific transition not found
  const transition = tokens.transition[type] || tokens.transition.hover;
  return props.map(p => `${p} ${transition.split(', ').find(t => t.startsWith(p)) || transition}`).join(', ');
}

/**
 * FLIP animasyonu için ölçüm ve uygulama
 * First, Last, Invert, Play
 */
export interface FlipRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export function getFlipRect(element: HTMLElement): FlipRect {
  const rect = element.getBoundingClientRect();
  return {
    x: rect.left,
    y: rect.top,
    width: rect.width,
    height: rect.height,
  };
}

export function applyFlipTransform(
  element: HTMLElement,
  first: FlipRect,
  last: FlipRect,
  onComplete?: () => void
): () => void {
  const dx = first.x - last.x;
  const dy = first.y - last.y;
  const sx = first.width / last.width;
  const sy = first.height / last.height;

  // Initial transform (inverted)
  element.style.transformOrigin = 'top left';
  element.style.transform = `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})`;
  element.style.transition = 'none';

  // Force reflow
  element.getBoundingClientRect();

  // Play - animate to identity
  const tokens = getMotionTokens();
  element.style.transition = tokens.transition.morph;
  element.style.transform = 'translate(0, 0) scale(1, 1)';

  const handleTransitionEnd = (e: TransitionEvent) => {
    if (e.propertyName === 'transform') {
      element.style.transition = '';
      element.style.transform = '';
      element.style.transformOrigin = '';
      element.removeEventListener('transitionend', handleTransitionEnd);
      onComplete?.();
    }
  };

  element.addEventListener('transitionend', handleTransitionEnd);

  // Cleanup function
  return () => {
    element.removeEventListener('transitionend', handleTransitionEnd);
    element.style.transition = '';
    element.style.transform = '';
    element.style.transformOrigin = '';
  };
}

/**
 * Shared element transition için yardımcı
 * Iki element arasında FLIP morph uygular
 */
export function createSharedElementTransition(
  fromElement: HTMLElement,
  toElement: HTMLElement,
  options?: {
    duration?: number;
    easing?: string;
    onComplete?: () => void;
  }
): () => void {
  const first = getFlipRect(fromElement);
  const last = getFlipRect(toElement);

  // Clone from element for transition
  const clone = fromElement.cloneNode(true) as HTMLElement;
  clone.style.position = 'fixed';
  clone.style.left = `${first.x}px`;
  clone.style.top = `${first.y}px`;
  clone.style.width = `${first.width}px`;
  clone.style.height = `${first.height}px`;
  clone.style.zIndex = '9999';
  clone.style.pointerEvents = 'none';
  clone.style.transition = 'none';
  clone.style.transformOrigin = 'top left';

  // Hide original elements during transition
  fromElement.style.opacity = '0';
  toElement.style.opacity = '0';

  document.body.appendChild(clone);

  // Force reflow
  clone.getBoundingClientRect();

  // Animate
  const duration = options?.duration ?? motionTokens.duration.morph;
  const easing = options?.easing ?? motionTokens.easing.morph;
  clone.style.transition = `transform ${duration}ms ${easing}, opacity ${duration}ms ${easing}`;
  clone.style.transform = `translate(${last.x - first.x}px, ${last.y - first.y}px) scale(${last.width / first.width}, ${last.height / first.height})`;

  const handleEnd = (e: TransitionEvent) => {
    if (e.propertyName === 'transform') {
      clone.removeEventListener('transitionend', handleEnd);
      document.body.removeChild(clone);
      fromElement.style.opacity = '';
      toElement.style.opacity = '';
      options?.onComplete?.();
    }
  };

  clone.addEventListener('transitionend', handleEnd);

  return () => {
    clone.removeEventListener('transitionend', handleEnd);
    document.body.removeChild(clone);
    fromElement.style.opacity = '';
    toElement.style.opacity = '';
  };
}

/**
 * Spring animasyonu için basit yardımcı (WAAPI)
 */
export function animateSpring(
  element: HTMLElement,
  keyframes: Keyframe[],
  options?: {
    duration?: number;
    damping?: number;
    stiffness?: number;
  }
): Animation {
  // Web Animations API with spring-like config
  return element.animate(keyframes, {
    duration: options?.duration ?? motionTokens.duration.morph,
    easing: motionTokens.easing.spring,
    fill: 'forwards',
  });
}

/**
 * Staggered animasyon için gecikme hesapla
 */
export function getStaggerDelay(index: number, baseDelay: number = 40, maxDelay: number = 300): number {
  return Math.min(baseDelay * index, maxDelay);
}

// ============================================================
// CSS VARIABLE MAPPING (for runtime access)
// ============================================================

export const cssMotionVars = {
  '--motion-duration-press': '120ms',
  '--motion-duration-hover': '160ms',
  '--motion-duration-toggle': '200ms',
  '--motion-duration-morph': '300ms',
  '--motion-duration-search': '280ms',
  '--motion-duration-overlay': '240ms',
  '--motion-duration-panel': '380ms',
  '--motion-duration-expanded': '420ms',
  '--motion-duration-artwork': '500ms',
  '--motion-easing-standard': 'cubic-bezier(0.22, 1, 0.36, 1)',
  '--motion-easing-interactive': 'cubic-bezier(0.34, 1.56, 0.64, 1)',
  '--motion-easing-morph': 'cubic-bezier(0.25, 0.46, 0.45, 0.94)',
  '--motion-easing-panel': 'cubic-bezier(0.32, 0.72, 0, 1)',
  '--motion-easing-spring': 'cubic-bezier(0.34, 1.56, 0.64, 1)',
} as const;

export function applyMotionVarsToRoot() {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  Object.entries(cssMotionVars).forEach(([key, value]) => {
    root.style.setProperty(key, value);
  });
}