import Foundation
#if canImport(Combine)
import Combine
#endif

// Read with Me (v8.1): as the narrator reads a story, each word lights up on screen in time with the voice.
// The matching is plain Swift (ReadAlongMath), tested in Tests/Learn.

enum ReadAlongMath {
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

    /// The words of a line (split on spaces), as ranges.
    static func words(_ s: String) -> [Range<String.Index>] {
        var out: [Range<String.Index>] = []
        var start: String.Index?
        var i = s.startIndex
        while i < s.endIndex {
            if s[i].isWhitespace {
                if let st = start { out.append(st..<i); start = nil }
            } else if start == nil {
                start = i
            }
            i = s.index(after: i)
        }
        if let st = start { out.append(st..<s.endIndex) }
        return out
    }

    /// Which word of the spoken string a character position falls in (0-based).
    static func spokenWordIndex(speech: String, utf16Location: Int) -> Int {
        let prefix = String(decoding: Array(speech.utf16.prefix(max(0, utf16Location))), as: UTF16.self)
        // the word starting at the location is the next one after every word already finished
        let done = words(prefix).count
        let endsInsideWord = !(prefix.last?.isWhitespace ?? true) && !prefix.isEmpty
        return max(0, endsInsideWord ? done - 1 : done)
    }

    /// The word on screen that matches spoken word `spoken`, when the screen shows `display` and the narrator read `source`.
    /// `source` may start with extra words that aren't on screen (a story's title before page one). Words that make
    /// no sound (an emoji on its own) are skipped. Nil when the screen isn't showing what is being read.
    static func displayRange(display: String, source: String, spoken: Int) -> Range<String.Index>? {
        guard !display.isEmpty, source.hasSuffix(display) else { return nil }
        let sourceWords = words(source)
        // map the spoken word back to a source word, skipping silent ones
        var count = -1
        var sourceIndex: Int?
        for (i, w) in sourceWords.enumerated() where !speakable(String(source[w])).isEmpty {
            count += speakable(String(source[w])).split(separator: " ").count
            if count >= spoken { sourceIndex = i; break }
        }
        guard let si = sourceIndex else { return nil }
        let displayWords = words(display)
        let offset = sourceWords.count - displayWords.count
        let di = si - offset
        return displayWords.indices.contains(di) ? displayWords[di] : nil
    }
}

#if canImport(Combine)
/// What the narrator is reading right now, for screens that show the words.
final class ReadAlong: ObservableObject {
    static let shared = ReadAlong()

    /// The line the narrator was given (empty when the words won't match, like a Spanish line).
    @Published private(set) var source = ""
    /// The word being spoken, counted in the spoken line.
    @Published private(set) var word: Int?

    private var speech = ""

    func started(source: String, speech: String) {
        onMain {
            self.source = source
            self.speech = speech
            self.word = nil
        }
    }

    func speaking(_ speech: String, word: Int) {
        onMain {
            guard speech == self.speech else { return }
            self.word = word
        }
    }

    func finished(_ speech: String) {
        onMain {
            guard speech == self.speech else { return }
            self.word = nil
        }
    }

    private func onMain(_ f: @escaping () -> Void) {
        if Thread.isMainThread { f() } else { DispatchQueue.main.async(execute: f) }
    }
}
#endif
