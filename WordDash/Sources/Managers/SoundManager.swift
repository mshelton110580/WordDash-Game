import AVFoundation

// MARK: - SoundManager
// Synthesized sound effects using AudioToolbox system sounds + AVAudioEngine tones.
// Mirrors web SoundEngine (Web Audio API oscillator-based beeps).

class SoundManager {

    static let shared = SoundManager()

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixerNode: AVAudioMixerNode?

    var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                stopEngine()
            } else {
                setupEngine()
            }
        }
    }

    private init() {
        loadSettings()
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        guard isEnabled else { return }
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixerNode = audioEngine?.mainMixerNode

        guard let engine = audioEngine, let player = playerNode else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("SoundManager: audio engine start failed: \(error)")
        }
    }

    private func stopEngine() {
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
    }

    // MARK: - Tone Generation

    /// Generate a PCM buffer containing a simple sine/square wave tone.
    private func makeToneBuffer(frequency: Double, duration: Double, amplitude: Float, waveform: WaveformType = .sine) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let phase = 2.0 * Double.pi * frequency * t
            var sample: Float
            switch waveform {
            case .sine:
                sample = Float(sin(phase))
            case .square:
                sample = Float(sin(phase) >= 0 ? 1.0 : -1.0)
            case .sawtooth:
                let cyclePos = (frequency * t).truncatingRemainder(dividingBy: 1.0)
                sample = Float(2.0 * cyclePos - 1.0)
            case .triangle:
                let cyclePos = (frequency * t).truncatingRemainder(dividingBy: 1.0)
                sample = cyclePos < 0.5 ? Float(4.0 * cyclePos - 1.0) : Float(3.0 - 4.0 * cyclePos)
            }

            // Envelope: quick fade-in (5ms), quick fade-out (10ms)
            let fadeInSamples = Int(sampleRate * 0.005)
            let fadeOutSamples = Int(sampleRate * 0.01)
            let fadeOutStart = Int(frameCount) - fadeOutSamples

            if i < fadeInSamples {
                sample *= Float(i) / Float(fadeInSamples)
            } else if i > fadeOutStart {
                sample *= Float(Int(frameCount) - i) / Float(fadeOutSamples)
            }

            channelData[i] = sample * amplitude
        }
        return buffer
    }

    private func playTone(frequency: Double, duration: Double, volume: Float, waveform: WaveformType = .sine) {
        guard isEnabled else { return }
        guard let engine = audioEngine, engine.isRunning,
              let player = playerNode,
              let buffer = makeToneBuffer(frequency: frequency, duration: duration, amplitude: volume, waveform: waveform) else {
            return
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    // MARK: - Sound Effects

    /// Short click when a tile is selected during drag.
    func playTileClick() {
        playTone(frequency: 600, duration: 0.06, volume: 0.12, waveform: .square)
    }

    /// Rising arpeggio on valid word submission.
    func playWordSuccess() {
        let notes: [(freq: Double, delay: Double)] = [
            (523, 0.0), (659, 0.07), (784, 0.14), (1047, 0.21)
        ]
        for note in notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + note.delay) {
                self.playTone(frequency: note.freq, duration: 0.12, volume: 0.15, waveform: .sine)
            }
        }
    }

    /// Low buzz on invalid word.
    func playWordFail() {
        playTone(frequency: 180, duration: 0.18, volume: 0.2, waveform: .sawtooth)
    }

    /// Low thump for bomb/explosion.
    func playExplosion() {
        playTone(frequency: 80, duration: 0.25, volume: 0.3, waveform: .sine)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.playTone(frequency: 60, duration: 0.35, volume: 0.2, waveform: .triangle)
        }
    }

    /// 5-note ascending fanfare on level complete.
    func playLevelComplete() {
        let fanfare: [(freq: Double, delay: Double)] = [
            (523, 0.0), (659, 0.1), (784, 0.2), (1047, 0.3), (1319, 0.45)
        ]
        for note in fanfare {
            DispatchQueue.main.asyncAfter(deadline: .now() + note.delay) {
                self.playTone(frequency: note.freq, duration: 0.18, volume: 0.2, waveform: .sine)
            }
        }
    }

    /// High ping when coins are earned.
    func playCoinEarned() {
        playTone(frequency: 1047, duration: 0.1, volume: 0.1, waveform: .sine)
    }

    /// Power-up activation sound.
    func playPowerUp() {
        playTone(frequency: 440, duration: 0.15, volume: 0.15, waveform: .triangle)
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let progress = PersistenceManager.shared.loadProgress()
        isEnabled = progress.soundEnabled
    }

    // MARK: - Waveform Type

    enum WaveformType {
        case sine, square, sawtooth, triangle
    }
}
