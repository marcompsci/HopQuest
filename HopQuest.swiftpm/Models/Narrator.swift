import AVFoundation

/// Reads questions, tips, and lessons out loud so pre-readers (ages 5–6) can play on their own.
/// Uses the built-in iOS voice — no audio files, nothing sent off the device.
final class Narrator: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Narrator()

    /// Turned on/off by grown-ups in settings (mirrors PlayerProfile.narration).
    var enabled = true {
        didSet { if !enabled { stop() } }
    }

    private let synth = AVSpeechSynthesizer()
    private var configured = false

    private override init() {
        super.init()
        synth.delegate = self
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        SoundFX.shared.duckMusic(true)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if !synthesizer.isSpeaking { SoundFX.shared.duckMusic(false) }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if !synthesizer.isSpeaking { SoundFX.shared.duckMusic(false) }
    }

    /// Speaks `text`, cutting off whatever was being said before.
    func say(_ text: String) {
        guard enabled else { return }
        let clean = Self.speakable(text)
        guard !clean.isEmpty else { return }
        configureSession()
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: clean)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9   // a little slower for kids
        utterance.pitchMultiplier = 1.15                             // a little brighter
        utterance.postUtteranceDelay = 0.05
        // All game text is English for now, so always use an English voice.
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }

    /// Reads a Brain Gate question with its choices: "What is 3 + 4? Is it 6, 7, or 8?"
    func ask(_ question: Question) {
        let choices = question.choices
        let list: String
        if choices.count > 1 {
            list = choices.dropLast().joined(separator: ", ") + ", or " + (choices.last ?? "")
        } else {
            list = choices.first ?? ""
        }
        say("\(question.prompt) Is it \(list)?")
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }

    private func configureSession() {
        guard !configured else { return }
        configured = true
        SoundFX.shared.start()
    }

    /// Strips emoji and swaps symbols the voice would read oddly.
    static func speakable(_ text: String) -> String {
        var t = text
            .replacingOccurrences(of: "×", with: " times ")
            .replacingOccurrences(of: "−", with: " minus ")
            .replacingOccurrences(of: " + ", with: " plus ")
            .replacingOccurrences(of: "·", with: ", ")
            .replacingOccurrences(of: "...", with: ", ")
            .replacingOccurrences(of: "mph", with: "miles per hour")
        t = String(String.UnicodeScalarView(t.unicodeScalars.filter { scalar in
            let p = scalar.properties
            if p.isEmojiPresentation { return false }
            if p.generalCategory == .otherSymbol { return false }
            if scalar.value == 0xFE0F || scalar.value == 0x200D { return false }   // emoji joiners
            if (0x2190...0x21FF).contains(scalar.value) || (0x25A0...0x25FF).contains(scalar.value) { return false } // arrows, shapes
            return true
        }))
        return t
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
