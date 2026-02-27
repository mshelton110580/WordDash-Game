// ============================================================
// WordDash Sound Engine — Web Audio API
// Matches iOS SoundManager: procedural oscillator-based tones
// ============================================================

type WaveformType = 'sine' | 'square' | 'sawtooth' | 'triangle';

const SOUND_ENABLED_KEY = 'worddash_sound_enabled';

class SoundEngineClass {
  private _ctx: AudioContext | null = null;
  private _enabled: boolean = true;

  constructor() {
    this.loadSettings();
  }

  get enabled(): boolean {
    return this._enabled;
  }

  set enabled(val: boolean) {
    this._enabled = val;
    localStorage.setItem(SOUND_ENABLED_KEY, JSON.stringify(val));
    if (!val && this._ctx) {
      this._ctx.close();
      this._ctx = null;
    }
  }

  private loadSettings(): void {
    const stored = localStorage.getItem(SOUND_ENABLED_KEY);
    if (stored !== null) {
      try { this._enabled = JSON.parse(stored); } catch { this._enabled = true; }
    }
  }

  private getContext(): AudioContext | null {
    if (!this._enabled) return null;
    if (!this._ctx || this._ctx.state === 'closed') {
      try {
        this._ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      } catch {
        return null;
      }
    }
    if (this._ctx.state === 'suspended') {
      this._ctx.resume();
    }
    return this._ctx;
  }

  private playTone(frequency: number, duration: number, volume: number, waveform: WaveformType = 'sine', delay: number = 0): void {
    const ctx = this.getContext();
    if (!ctx) return;

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = waveform;
    osc.frequency.value = frequency;

    const startTime = ctx.currentTime + delay;
    const endTime = startTime + duration;

    // Envelope: quick fade-in (5ms), quick fade-out (10ms)
    gain.gain.setValueAtTime(0, startTime);
    gain.gain.linearRampToValueAtTime(volume, startTime + 0.005);
    gain.gain.setValueAtTime(volume, endTime - 0.01);
    gain.gain.linearRampToValueAtTime(0, endTime);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(startTime);
    osc.stop(endTime + 0.01);
  }

  // --- Sound Effects (matching iOS SoundManager) ---

  /** Short click when a tile is selected during drag */
  playTileClick(): void {
    this.playTone(600, 0.06, 0.12, 'square');
  }

  /** Rising arpeggio on valid word submission */
  playWordSuccess(): void {
    const notes: [number, number][] = [[523, 0], [659, 0.07], [784, 0.14], [1047, 0.21]];
    for (const [freq, delay] of notes) {
      this.playTone(freq, 0.12, 0.15, 'sine', delay);
    }
  }

  /** Low buzz on invalid word */
  playWordFail(): void {
    this.playTone(180, 0.18, 0.2, 'sawtooth');
  }

  /** Low thump for bomb/explosion */
  playExplosion(): void {
    this.playTone(80, 0.25, 0.3, 'sine');
    this.playTone(60, 0.35, 0.2, 'triangle', 0.05);
  }

  /** 5-note ascending fanfare on level complete */
  playLevelComplete(): void {
    const fanfare: [number, number][] = [[523, 0], [659, 0.1], [784, 0.2], [1047, 0.3], [1319, 0.45]];
    for (const [freq, delay] of fanfare) {
      this.playTone(freq, 0.18, 0.2, 'sine', delay);
    }
  }

  /** High ping when coins are earned */
  playCoinEarned(): void {
    this.playTone(1047, 0.1, 0.1, 'sine');
  }

  /** Power-up activation sound */
  playPowerUp(): void {
    this.playTone(440, 0.15, 0.15, 'triangle');
  }
}

export const SoundEngine = new SoundEngineClass();
