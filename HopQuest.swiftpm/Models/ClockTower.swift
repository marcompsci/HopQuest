import Foundation

// The Clock Tower (v4.5): Gemma Giraffe's tower in Hop Village. Kids read and set a real clock face:
// o'clock, half past, quarter hours, and "one hour later". Plain Swift, tested in Tests/Learn.

/// A time on a 12-hour clock face.
struct ClockTime: Equatable, Hashable {
    /// 1 to 12.
    var hour: Int
    /// 0 to 59.
    var minute: Int

    init(_ hour: Int, _ minute: Int = 0) {
        self.hour = ((hour - 1) % 12 + 12) % 12 + 1
        self.minute = ((minute % 60) + 60) % 60
    }

    /// "3:05"
    var digital: String { "\(hour):\(minute < 10 ? "0" : "")\(minute)" }

    /// How a grown-up would say it to a child: "3 o'clock", "half past 3", "quarter past 3", "quarter to 4", "10 past 3".
    var spoken: String {
        let next = ClockTime(hour + 1).hour
        switch minute {
        case 0: return "\(hour) o'clock"
        case 15: return "quarter past \(hour)"
        case 30: return "half past \(hour)"
        case 45: return "quarter to \(next)"
        case 1...29: return "\(minute) past \(hour)"
        default: return "\(60 - minute) to \(next)"
        }
    }

    /// Hands, in degrees clockwise from 12. The hour hand creeps forward as the minutes go by, like a real clock.
    var hourAngle: Double { (Double(hour % 12) + Double(minute) / 60) * 30 }
    var minuteAngle: Double { Double(minute) * 6 }

    /// Minutes since 12:00, for adding time.
    var minutesFromTwelve: Int { (hour % 12) * 60 + minute }

    func adding(minutes: Int) -> ClockTime {
        let total = ((minutesFromTwelve + minutes) % 720 + 720) % 720
        return ClockTime(total / 60 == 0 ? 12 : total / 60, total % 60)
    }
}

enum ClockHands {
    /// A finger angle (degrees clockwise from 12) to the nearest 5 minutes.
    static func minute(fromAngle a: Double) -> Int {
        let m = Int((normalized(a) / 6 / 5).rounded()) * 5
        return m % 60
    }

    /// A finger angle to the nearest hour on the face.
    static func hour(fromAngle a: Double) -> Int {
        let h = Int((normalized(a) / 30).rounded()) % 12
        return h == 0 ? 12 : h
    }

    static func normalized(_ a: Double) -> Double { (a.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) }

    /// The angle of a point from the clock's center (y down, like the screen), clockwise from 12.
    static func angle(dx: Double, dy: Double) -> Double { normalized(atan2(dx, -dy) * 180 / .pi) }

    /// Moving the minute hand past 12 moves the hour on, like winding a real clock.
    static func wind(_ t: ClockTime, toMinute m: Int) -> ClockTime {
        var hour = t.hour
        if t.minute >= 45 && m <= 15 { hour += 1 }
        if t.minute <= 15 && m >= 45 { hour -= 1 }
        return ClockTime(hour, m)
    }
}

enum ClockGame: String, CaseIterable, Codable, Identifiable {
    case oclock, halfPast, quarters, setClock, hourLater

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oclock: return "O'Clock"
        case .halfPast: return "Half Past"
        case .quarters: return "Quarter Hours"
        case .setClock: return "Set the Clock"
        case .hourLater: return "One Hour Later"
        }
    }

    var skill: String {
        switch self {
        case .oclock: return "telling time to the hour"
        case .halfPast: return "telling time to the half hour"
        case .quarters: return "telling time to the quarter hour"
        case .setClock: return "showing a time on a clock"
        case .hourLater: return "working out elapsed time"
        }
    }

    var intro: String {
        switch self {
        case .oclock: return "The short hand shows the hour. When the long hand points to 12, it's o'clock!"
        case .halfPast: return "When the long hand points to 6, it's half past. The short hand is halfway to the next number."
        case .quarters: return "Long hand on 3 is quarter past. On 9, it's quarter to the next hour."
        case .setClock: return "Move the hands to show the time. Drag the long hand for minutes and the short hand for hours."
        case .hourLater: return "Look at the clock. What time will it be one hour later?"
        }
    }
}

struct ClockRound: Equatable {
    enum Kind: Equatable {
        case choose
        /// Move the hands to `time`.
        case set
    }
    let kind: Kind
    /// The time on the clock (choose) or the time to make (set).
    let time: ClockTime
    let say: String
    /// Digital times to pick from (empty for `.set`).
    let choices: [String]
    let answer: String
    let cheer: String
    /// A little picture of what happens then ("🥞 breakfast").
    let moment: String
}

enum ClockBank {
    static let cheers = ["Right on time!", "Tick tock, you got it!", "Clock expert!", "That's right!", "Super timing!"]

    /// Things in a day, so times mean something.
    static let moments: [(hour: Int, text: String)] = [
        (7, "🥞 breakfast"), (8, "🎒 school starts"), (10, "🍎 snack time"), (12, "🥪 lunch"), (3, "⚽ play outside"),
        (4, "📚 reading time"), (6, "🍝 dinner"), (7, "🛁 bath time"), (8, "🌙 bedtime"), (9, "🐶 walk the dog"),
        (11, "🎨 art class"), (1, "🎵 music class"), (2, "🧩 puzzle time"), (5, "🚲 bike ride"),
    ]

    static func minutes(for game: ClockGame) -> [Int] {
        switch game {
        case .oclock: return [0]
        case .halfPast: return [0, 30, 30]
        case .quarters: return [15, 45, 15, 45, 30]
        case .setClock: return [0, 30]
        case .hourLater: return [0, 30]
        }
    }

    /// Three different times that a child could mix up with `t` (hands swapped, the hour off by one).
    static func confusions<G: RandomNumberGenerator>(for t: ClockTime, game: ClockGame, using rng: inout G) -> [ClockTime] {
        var pool: [ClockTime] = [ClockTime(t.hour + 1, t.minute), ClockTime(t.hour - 1, t.minute)]
        // the classic mix-up: reading the long hand as the hour
        if t.minute % 5 == 0, t.minute > 0 { pool.append(ClockTime(t.minute / 5, t.hour * 5 % 60)) }
        switch game {
        case .oclock: pool += [ClockTime(t.hour + 2), ClockTime(12 - t.hour)]
        case .halfPast: pool += [ClockTime(t.hour, t.minute == 30 ? 0 : 30), ClockTime(t.hour + 1, t.minute == 30 ? 0 : 30)]
        case .quarters: pool += [ClockTime(t.hour, 60 - t.minute), ClockTime(t.hour + 1, 60 - t.minute), ClockTime(t.hour, 30)]
        case .hourLater: pool += [ClockTime(t.hour + 2, t.minute), ClockTime(t.hour, (t.minute + 30) % 60)]
        case .setClock: break
        }
        var seen: Set<ClockTime> = [t]
        var out: [ClockTime] = []
        for c in pool.shuffled(using: &rng) where !seen.contains(c) {
            seen.insert(c); out.append(c)
        }
        return Array(out.prefix(2))
    }

    static func rounds<G: RandomNumberGenerator>(for game: ClockGame, count: Int = 5, using rng: inout G) -> [ClockRound] {
        var used: Set<ClockTime> = []
        var out: [ClockRound] = []
        let mins = minutes(for: game)
        while out.count < count {
            let m = mins[out.count % mins.count]
            let moment = moments.randomElement(using: &rng)!
            // half the time use a moment of the day, so the hour means something
            let hour = Bool.random(using: &rng) ? moment.hour : Int.random(in: 1...12, using: &rng)
            let t = ClockTime(hour, m)
            guard !used.contains(t) else { continue }
            used.insert(t)
            let cheer = cheers.randomElement(using: &rng)!
            let label = hour == moment.hour && m == 0 ? moment.text : ""
            switch game {
            case .oclock, .halfPast, .quarters:
                let choices = ([t] + confusions(for: t, game: game, using: &rng)).shuffled(using: &rng).map(\.digital)
                out.append(ClockRound(kind: .choose, time: t, say: "What time does the clock show?", choices: choices,
                                      answer: t.digital, cheer: "It's \(t.spoken). \(cheer)", moment: label))
            case .setClock:
                out.append(ClockRound(kind: .set, time: t, say: "Show \(t.spoken) on the clock.", choices: [],
                                      answer: t.digital, cheer: "That's \(t.spoken)! \(cheer)", moment: label))
            case .hourLater:
                let later = t.adding(minutes: 60)
                let choices = ([later] + confusions(for: later, game: game, using: &rng)).shuffled(using: &rng).map(\.digital)
                out.append(ClockRound(kind: .choose, time: t, say: "The clock says \(t.spoken). What time will it be one hour later?",
                                      choices: choices, answer: later.digital,
                                      cheer: "One hour after \(t.spoken) is \(later.spoken). \(cheer)", moment: ""))
            }
        }
        return out
    }

    static func rounds(for game: ClockGame, count: Int = 5) -> [ClockRound] {
        var g = SystemRandomNumberGenerator()
        return rounds(for: game, count: count, using: &g)
    }

    /// Set the Clock: right when both hands show the time (the hour hand may sit anywhere in its hour, as on a real clock).
    static func isSet(_ shown: ClockTime, to target: ClockTime) -> Bool { shown.hour == target.hour && shown.minute == target.minute }
}

struct ClockSave: Codable, Equatable {
    var best: [String: Int] = [:]
    var plays: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        best = (try? c.decodeIfPresent([String: Int].self, forKey: .best)) ?? [:]
        plays = (try? c.decodeIfPresent(Int.self, forKey: .plays)) ?? 0
    }

    func best(_ g: ClockGame) -> Int { best[g.rawValue] ?? 0 }

    mutating func record(_ g: ClockGame, stars: Int) -> Int {
        plays += 1
        let old = best(g)
        guard stars > old else { return 0 }
        best[g.rawValue] = min(3, stars)
        return min(3, stars) - old
    }

    var totalStars: Int { best.values.reduce(0, +) }
    static let maxStars = ClockGame.allCases.count * 3
}
