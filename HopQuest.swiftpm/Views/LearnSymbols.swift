import SwiftUI

// SF Symbols for each learning game: one icon language for the lists, instead of a different emoji per row.

extension ReadingGame {
    var symbol: String {
        switch self {
        case .firstSound: return "textformat.abc"
        case .buildWord: return "puzzlepiece.fill"
        case .sightWords: return "eye.fill"
        case .rhymes: return "music.note"
        case .sentences: return "book.fill"
        }
    }
}

extension MarketGame {
    var symbol: String {
        switch self {
        case .countCoins: return "centsign.circle.fill"
        case .payExactly: return "cart.fill"
        case .makeChange: return "arrow.left.arrow.right"
        case .compare: return "scalemass.fill"
        case .addUp: return "list.bullet.clipboard.fill"
        }
    }
}

extension Experiment {
    var symbol: String {
        switch self {
        case .sinkFloat: return "drop.fill"
        case .magnets: return "paperclip"
        case .plantParts: return "leaf.fill"
        case .weather: return "cloud.sun.fill"
        case .matter: return "cube.fill"
        }
    }
}

extension WritingGame {
    var symbol: String {
        switch self {
        case .capitals: return "textformat.size.larger"
        case .lowercase: return "textformat.size.smaller"
        case .numbers: return "number"
        case .words: return "pencil.line"
        }
    }
}

extension ClockGame {
    var symbol: String {
        switch self {
        case .oclock: return "clock.fill"
        case .halfPast: return "circle.lefthalf.filled"
        case .quarters: return "chart.pie.fill"
        case .setClock: return "hand.draw.fill"
        case .hourLater: return "clock.arrow.circlepath"
        }
    }
}

/// The buddy who runs each learning place (all from the Sticker Book roster, so they match the rest of the game).
enum PlaceHost {
    static var reading: GameCharacter { Roster.character(id: "ollie") }
    static var market: GameCharacter { Roster.character(id: "benny") }
    static var science: GameCharacter { Roster.character(id: "ocho") }
    static var music: GameCharacter { Roster.character(id: "fizz") }
    static var writing: GameCharacter { Roster.character(id: "polly") }
    static var clock: GameCharacter { Roster.character(id: "gemma") }
}
