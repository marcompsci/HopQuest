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
        ReadAlong.shared.finished(utterance.speechString)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if !synthesizer.isSpeaking { SoundFX.shared.duckMusic(false) }
        ReadAlong.shared.finished(utterance.speechString)
    }

    /// Read with Me (v8.1): which word is being spoken, so the words on screen can light up as they're read.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let index = ReadAlongMath.spokenWordIndex(speech: utterance.speechString, utf16Location: characterRange.location)
        ReadAlong.shared.speaking(utterance.speechString, word: index)
    }

    /// Speaks `text`, cutting off whatever was being said before.
    func say(_ text: String) {
        say(text, pitch: 1.15, rate: 0.9)
    }

    /// Speaks even when grown-ups turned narration off: for a speaker button the child tapped on purpose.
    func sayAnyway(_ text: String) {
        say(text, pitch: 1.15, rate: 0.9, force: true)
    }

    /// Speaks in a character's voice (story cutscenes): `pitch` 0.5...2, `rate` compared to normal speed.
    func say(_ text: String, pitch: Float, rate: Float, force: Bool = false) {
        guard enabled || force else { return }
        // In Spanish, a line is spoken in Spanish only when every sentence of it has a translation
        let spanish = L10n.isSpanish ? L10n.spanishSpeech(text) : nil
        let clean = Self.speakable(spanish ?? text)
        guard !clean.isEmpty else { return }
        configureSession()
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: clean)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * rate   // a little slower for kids
        utterance.pitchMultiplier = min(2, max(0.5, pitch))          // a little brighter by default
        utterance.postUtteranceDelay = 0.05
        // the learning content is English, so anything without a Spanish line is read in English
        utterance.voice = AVSpeechSynthesisVoice(language: spanish != nil ? "es-MX" : "en-US")
        // words light up only when what is heard is what is written (not when a Spanish line is read)
        ReadAlong.shared.started(source: spanish == nil ? text : "", speech: clean)
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
    static func speakable(_ text: String) -> String { ReadAlongMath.speakable(text) }
}
