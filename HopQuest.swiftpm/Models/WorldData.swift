import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

// Story worlds beyond the first one are DATA, not code: Assets.xcassets/worlds.dataset/worlds.json lists each
// world, its chapters, how each hop level looks (ground, floating platforms, decorations, vehicle colors) and
// extra Brain Gate questions. Adding a world means adding to that file. World 1 (Meadow Street to Castle Hill)
// stays in Chapters.swift, so nothing about the original story changes.

/// How a hop level looks and feels.
struct HopStyle: Codable, Equatable {
    /// "meadow", "snow" or "sand".
    var ground: String = "meadow"
    /// What floats in the rivers: "log", "lily", "ice" or "surfboard".
    var floaters: String = "log"
    /// Little things on the grass (emoji).
    var decorations: [String] = ["🌼", "🌷", "🌸"]
    /// Vehicle colors as hex ("FF9F45"); nil keeps the usual cars.
    var vehicleColors: [String]? = nil
    /// Overrides how often rivers appear (0...0.8); nil uses the chapter's difficulty.
    var riverChance: Double? = nil
    /// Extra Brain Gate questions for this level. The first choice is the right answer.
    var questions: [WorldQuestion] = []

    init() {}

    enum CodingKeys: String, CodingKey { case ground, floaters, decorations, vehicleColors, riverChance, questions }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ground = (try? c.decodeIfPresent(String.self, forKey: .ground)) ?? "meadow"
        floaters = (try? c.decodeIfPresent(String.self, forKey: .floaters)) ?? "log"
        decorations = (try? c.decodeIfPresent([String].self, forKey: .decorations)) ?? ["🌼", "🌷", "🌸"]
        vehicleColors = try? c.decodeIfPresent([String].self, forKey: .vehicleColors)
        riverChance = try? c.decodeIfPresent(Double.self, forKey: .riverChance)
        questions = (try? c.decodeIfPresent([WorldQuestion].self, forKey: .questions)) ?? []
    }

    var isSnow: Bool { ground == "snow" }
    var isSand: Bool { ground == "sand" }
}

struct WorldQuestion: Codable, Equatable {
    var subject: String
    var prompt: String
    /// The first choice is the right one (the game shuffles them).
    var choices: [String]
    var explain: String
}

struct WorldChapter: Codable, Equatable {
    var id: Int
    var title: String
    /// Only "hop" for now (drive levels still come from code).
    var kind: String
    var icon: String
    var rows: Int
    var gateEvery: Int
    var difficulty: Double
    /// Read aloud when the level opens.
    var intro: String
    var style: HopStyle
}

struct WorldDef: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var icon: String
    var blurb: String
    /// The chapter that must be finished first (6 = Castle Hill, the end of World 1).
    var unlockAfter: Int
    /// Card color (hex).
    var color: String
    var chapters: [WorldChapter]

    /// The world's look on its own screen, from its first level's ground.
    var ground: String { chapters.first?.style.ground ?? "meadow" }
}

struct WorldFile: Codable, Equatable {
    var version: Int
    var worlds: [WorldDef]
}

enum WorldData {
    static let supportedKinds: Set<String> = ["hop"]
    static let groundKinds: Set<String> = ["meadow", "snow", "sand"]
    static let floaterKinds: Set<String> = ["log", "lily", "ice", "surfboard"]

    static func decode(_ data: Data) throws -> WorldFile {
        try JSONDecoder().decode(WorldFile.self, from: data)
    }

    /// Everything wrong with a worlds file, in plain words (empty = good to ship).
    static func problems(in file: WorldFile, builtInIDs: Set<Int>) -> [String] {
        var out: [String] = []
        var seen = builtInIDs
        var worldIDs: Set<String> = []
        for w in file.worlds {
            if !worldIDs.insert(w.id).inserted { out.append("World id \(w.id) is used twice") }
            if w.chapters.isEmpty { out.append("\(w.title) has no chapters") }
            if !builtInIDs.contains(w.unlockAfter) && !file.worlds.flatMap(\.chapters).contains(where: { $0.id == w.unlockAfter }) {
                out.append("\(w.title) unlocks after chapter \(w.unlockAfter), which doesn't exist")
            }
            if UInt32(w.color, radix: 16) == nil { out.append("\(w.title) color \(w.color) isn't hex") }
            for c in w.chapters {
                if !seen.insert(c.id).inserted { out.append("Chapter id \(c.id) is used twice") }
                if !supportedKinds.contains(c.kind) { out.append("\(c.title): kind \(c.kind) isn't supported") }
                if !(12...60).contains(c.rows) { out.append("\(c.title): rows \(c.rows) should be 12...60") }
                if c.gateEvery < 4 || c.gateEvery >= c.rows { out.append("\(c.title): gateEvery \(c.gateEvery) should be 4...rows-1") }
                if !(0...1).contains(c.difficulty) { out.append("\(c.title): difficulty should be 0...1") }
                if !groundKinds.contains(c.style.ground) { out.append("\(c.title): ground \(c.style.ground) isn't known") }
                if !floaterKinds.contains(c.style.floaters) { out.append("\(c.title): floaters \(c.style.floaters) isn't known") }
                if let r = c.style.riverChance, !(0...0.8).contains(r) { out.append("\(c.title): riverChance should be 0...0.8") }
                for hex in c.style.vehicleColors ?? [] where UInt32(hex, radix: 16) == nil { out.append("\(c.title): vehicle color \(hex) isn't hex") }
                for q in c.style.questions {
                    if !(2...4).contains(q.choices.count) { out.append("\(c.title): \"\(q.prompt)\" needs 2 to 4 choices") }
                    if Set(q.choices).count != q.choices.count { out.append("\(c.title): \"\(q.prompt)\" repeats a choice") }
                    if q.prompt.isEmpty || q.explain.isEmpty { out.append("\(c.title): a question is missing words") }
                }
            }
        }
        return out
    }

    /// A world's chapters as game chapters.
    static func chapters(of w: WorldDef) -> [Chapter] {
        w.chapters.map { c in
            Chapter(id: c.id, title: c.title, kind: .hop, icon: c.icon, rows: c.rows, gateEvery: c.gateEvery,
                    trackLength: 0, difficulty: CGFloat(c.difficulty), mapX: 0, mapY: 0, style: c.style)
        }
    }
}

/// The worlds that ship with the app (read once from the asset catalog).
enum Worlds {
    static let all: [WorldDef] = {
        #if canImport(UIKit)
        if let asset = NSDataAsset(name: "worlds"), let file = try? WorldData.decode(asset.data),
           WorldData.problems(in: file, builtInIDs: Set(Chapters.all.map(\.id) + Chapters.team.map(\.id) + Chapters.kartCups.map(\.id))).isEmpty {
            return file.worlds
        }
        #endif
        return []
    }()

    static var chapters: [Chapter] { all.flatMap(WorldData.chapters(of:)) }

    static func world(containing chapterID: Int) -> WorldDef? {
        all.first { $0.chapters.contains { $0.id == chapterID } }
    }

    static func intro(_ chapterID: Int) -> String? {
        all.flatMap(\.chapters).first { $0.id == chapterID }?.intro
    }
}
