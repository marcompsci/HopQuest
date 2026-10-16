import Foundation

// The Coding Lab curriculum. Three tracks, five lessons each. Every lesson adds real lines of code to a project
// the child keeps building: a web page (HTML + CSS), a Python program, and a playable Python game.
// Kids fill in code by tapping choices (no typing needed), then press Run to see what their code does.

enum CodeTrack: String, CaseIterable, Codable, Identifiable {
    case web, python, games
    var id: String { rawValue }

    var title: String {
        switch self {
        case .web: return "Web Designer"
        case .python: return "Python Coder"
        case .games: return "Game Maker"
        }
    }

    var language: String {
        switch self {
        case .web: return "HTML & CSS"
        case .python, .games: return "Python"
        }
    }

    var icon: String {
        switch self {
        case .web: return "🌐"
        case .python: return "🐍"
        case .games: return "🎮"
        }
    }

    var builds: String {
        switch self {
        case .web: return "Build your own web page"
        case .python: return "Write programs that talk back"
        case .games: return "Code a game you can play"
        }
    }

    var colorHex: UInt32 {
        switch self {
        case .web: return 0x4D96FF
        case .python: return 0x34C77B
        case .games: return 0xFF7A59
        }
    }
}

enum SlotKind: String, Codable { case text, number, word, color, tag }

struct CodeSlot: Equatable {
    let id: String
    let kind: SlotKind
    let choices: [String]
    /// What the child is picking, in kid words ("a title", "how high").
    let prompt: String
}

enum CodeSection: String { case style, body, main }

struct CodeLineTemplate: Equatable {
    /// Code with [[slot]] placeholders, e.g. `print("[[hello]]")`.
    let text: String
    let indent: Int
    let section: CodeSection
    let slots: [CodeSlot]

    init(_ text: String, indent: Int = 0, section: CodeSection = .main, _ slots: [CodeSlot] = []) {
        self.text = text
        self.indent = indent
        self.section = section
        self.slots = slots
    }
}

struct LearnCard: Equatable {
    let title: String
    let text: String
    /// A tiny code example shown in a box.
    let example: String?
}

struct LessonQuiz: Equatable {
    let prompt: String
    let choices: [String]      // the first one is right; the app shuffles
    let explain: String
}

struct CodeLesson: Identifiable, Equatable {
    let id: String
    let track: CodeTrack
    let number: Int
    let title: String
    /// What the child will have built when the lesson is done.
    let goal: String
    let cards: [LearnCard]
    let lines: [CodeLineTemplate]
    let funFact: String
    let quiz: LessonQuiz

    var slotKeys: [String] { lines.flatMap { $0.slots.map { "\(id).\($0.id)" } } }
}

/// What the Coding Lab remembers (inside PlayerProfile, on this device only).
struct CodeLabSave: Codable, Equatable {
    var completed: Set<String> = []
    /// Chosen values: "web1.title" → "Hi, I'm {kid}!"
    var values: [String: String] = [:]

    init() {}

    enum CodingKeys: String, CodingKey { case completed, values }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        completed = (try? c.decodeIfPresent(Set<String>.self, forKey: .completed)) ?? []
        values = (try? c.decodeIfPresent([String: String].self, forKey: .values)) ?? [:]
    }

    func isDone(_ lesson: CodeLesson) -> Bool { completed.contains(lesson.id) }

    /// The next lesson to do in a track (nil when the track is finished).
    func nextLesson(in track: CodeTrack) -> CodeLesson? {
        CodeCurriculum.lessons(for: track).first { !completed.contains($0.id) }
    }

    /// Lessons unlock in order within a track.
    func isUnlocked(_ lesson: CodeLesson) -> Bool {
        lesson.number == 1 || completed.contains("\(lesson.track.rawValue)\(lesson.number - 1)")
    }
}

// MARK: - The lessons

enum CodeCurriculum {
    private static func slot(_ id: String, _ kind: SlotKind, _ prompt: String, _ choices: [String]) -> CodeSlot {
        CodeSlot(id: id, kind: kind, choices: choices, prompt: prompt)
    }

    static let lessons: [CodeLesson] = web + python + games

    static func lessons(for track: CodeTrack) -> [CodeLesson] { lessons.filter { $0.track == track } }
    static func lesson(_ id: String) -> CodeLesson? { lessons.first { $0.id == id } }

    // MARK: Web Designer (HTML & CSS)

    static let web: [CodeLesson] = [
        CodeLesson(id: "web1", track: .web, number: 1, title: "Your first web page",
                   goal: "A web page with a big title",
                   cards: [
                    LearnCard(title: "Websites are made of HTML",
                              text: "Every website you visit is written in a language called HTML. HTML tells the computer what each part of the page is: a title, a sentence, a picture.", example: nil),
                    LearnCard(title: "Tags come in pairs",
                              text: "HTML uses tags in pointy brackets. <h1> opens a big heading and </h1> closes it. Whatever goes between them is the heading.",
                              example: "<h1>Hello!</h1>"),
                   ],
                   lines: [CodeLineTemplate("<h1>[[title]]</h1>", section: .body,
                                            [slot("title", .text, "a title for your page", ["Hi, I'm {kid}!", "Welcome to my page!", "{kid}'s Hop Page", "Hop Village News"])])],
                   funFact: "The very first website went online in 1991, and you can still visit it today!",
                   quiz: LessonQuiz(prompt: "Which tag makes a big heading?", choices: ["<h1>", "<p>", "<img>"],
                                    explain: "<h1> is heading 1, the biggest heading.")),
        CodeLesson(id: "web2", track: .web, number: 2, title: "Paragraphs",
                   goal: "Sentences that tell people about you",
                   cards: [
                    LearnCard(title: "<p> is for paragraphs",
                              text: "Use <p> for sentences. Each <p> starts on its own line, just like paragraphs in a book.",
                              example: "<p>I love to hop.</p>"),
                    LearnCard(title: "Open, then close",
                              text: "Don't forget the slash in the closing tag: </p>. It tells the browser where the paragraph ends.", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate("<p>[[about]]</p>", section: .body,
                                     [slot("about", .text, "something about you", ["I love to hop across Meadow Street.", "My buddy is {buddy}.", "I am learning to code!", "I live in Hop Village."])]),
                    CodeLineTemplate("<p>My favorite food is [[food]].</p>", section: .body,
                                     [slot("food", .text, "your favorite food", ["pizza 🍕", "apples 🍎", "tacos 🌮", "noodles 🍜", "carrots 🥕"])]),
                   ],
                   funFact: "A web browser reads your HTML from top to bottom, then draws the page in less than a blink!",
                   quiz: LessonQuiz(prompt: "What is <p> for?", choices: ["A paragraph of text", "A picture", "A purple color"],
                                    explain: "<p> stands for paragraph.")),
        CodeLesson(id: "web3", track: .web, number: 3, title: "Colors with CSS",
                   goal: "Your page in your favorite colors",
                   cards: [
                    LearnCard(title: "CSS is the style",
                              text: "HTML says WHAT things are. CSS says how they LOOK: colors, sizes and spacing. Websites use both together.", example: nil),
                    LearnCard(title: "A CSS rule",
                              text: "A rule names what to style, then lists properties and values inside { }. Each line ends with a semicolon.",
                              example: "h1 { color: purple; }"),
                   ],
                   lines: [
                    CodeLineTemplate("body { background: [[bg]]; }", section: .style,
                                     [slot("bg", .color, "a background color", ["lightblue", "pink", "lightyellow", "palegreen", "lavender"])]),
                    CodeLineTemplate("h1 { color: [[h1]]; }", section: .style,
                                     [slot("h1", .color, "a title color", ["purple", "crimson", "darkorange", "teal", "navy"])]),
                    CodeLineTemplate("p { font-size: [[size]]px; }", section: .style,
                                     [slot("size", .number, "how big the words are", ["18", "24", "30"])]),
                   ],
                   funFact: "Screens make every color by mixing just three kinds of light: red, green and blue.",
                   quiz: LessonQuiz(prompt: "Which language decides what color things are?", choices: ["CSS", "HTML", "Python"],
                                    explain: "CSS is for style: colors, sizes and spacing.")),
        CodeLesson(id: "web4", track: .web, number: 4, title: "Pictures and lists",
                   goal: "A picture and a list of things you like",
                   cards: [
                    LearnCard(title: "Show a picture with <img>",
                              text: "<img> shows a picture. src (short for source) says which picture file to use. <img> doesn't need a closing tag.",
                              example: "<img src=\"buddy.png\">"),
                    LearnCard(title: "Lists",
                              text: "<ul> starts a bullet list and <li> is each list item. Lists are everywhere: menus, steps, shopping lists!",
                              example: "<ul>\n  <li>Hopping</li>\n</ul>"),
                   ],
                   lines: [
                    CodeLineTemplate("<img src=\"[[pic]]\" width=\"150\">", section: .body,
                                     [slot("pic", .word, "a picture", ["buddy.png", "castle.png", "star.png"])]),
                    CodeLineTemplate("<ul>", section: .body),
                    CodeLineTemplate("<li>[[like1]]</li>", indent: 1, section: .body,
                                     [slot("like1", .text, "something you like", ["Hopping 🐰", "Coding 💻", "Robots 🤖", "Racing karts 🏎️", "Reading 📚"])]),
                    CodeLineTemplate("<li>[[like2]]</li>", indent: 1, section: .body,
                                     [slot("like2", .text, "something else you like", ["Drawing 🎨", "Building forts 🧱", "Animals 🐾", "Music 🎵", "Space 🚀"])]),
                    CodeLineTemplate("</ul>", section: .body),
                   ],
                   funFact: "Some websites show millions of pictures. Each one is loaded with an <img> tag, just like yours!",
                   quiz: LessonQuiz(prompt: "What does src tell an <img>?", choices: ["Which picture to show", "How loud it is", "What color it is"],
                                    explain: "src is the source: the picture file to show.")),
        CodeLesson(id: "web5", track: .web, number: 5, title: "Fancy boxes and buttons",
                   goal: "A card with rounded corners and a button",
                   cards: [
                    LearnCard(title: "Classes name a style",
                              text: "class=\"card\" gives an HTML part a name. In CSS, .card { } styles everything with that class.",
                              example: ".card { border: 4px solid gold; }"),
                    LearnCard(title: "Round the corners",
                              text: "border-radius rounds the corners of a box. Bigger numbers make rounder corners. Most app buttons use it!", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate(".card { border: 4px solid [[border]]; border-radius: [[round]]px; padding: 12px; }", section: .style,
                                     [slot("border", .color, "a border color", ["gold", "hotpink", "mediumpurple", "tomato"]),
                                      slot("round", .number, "how round the corners are", ["0", "12", "30"])]),
                    CodeLineTemplate("button { background: [[btn]]; color: white; border-radius: 20px; padding: 10px; }", section: .style,
                                     [slot("btn", .color, "a button color", ["mediumseagreen", "royalblue", "darkorange", "orchid"])]),
                    CodeLineTemplate("<div class=\"card\">[[card]]</div>", section: .body,
                                     [slot("card", .text, "what the card says", ["⭐ Thanks for visiting my page!", "🏰 Next stop: my castle!", "💻 Made by {kid} in the Coding Lab"])]),
                    CodeLineTemplate("<button>[[label]]</button>", section: .body,
                                     [slot("label", .text, "the button's words", ["Say hi! 👋", "Play ▶", "Hop! 🐰"])]),
                   ],
                   funFact: "Designers try lots of colors and corner sizes before picking one. Tap any part of your code to try more!",
                   quiz: LessonQuiz(prompt: "What does border-radius do?", choices: ["Rounds the corners", "Makes it bigger", "Plays a sound"],
                                    explain: "border-radius rounds a box's corners.")),
    ]

    // MARK: Python Coder

    static let python: [CodeLesson] = [
        CodeLesson(id: "python1", track: .python, number: 1, title: "Say hello with print()",
                   goal: "Your first Python program",
                   cards: [
                    LearnCard(title: "Meet Python",
                              text: "Python is a real programming language. Grown-up coders use it to build apps, games, websites and even programs for space missions!", example: nil),
                    LearnCard(title: "print() shows words",
                              text: "print() shows whatever is inside the parentheses. Words in quotes are called a string.",
                              example: "print(\"Hello!\")"),
                   ],
                   lines: [CodeLineTemplate("print(\"[[hello]]\")",
                                            [slot("hello", .text, "what to say", ["Hello, Hop Village!", "Hi, I'm {kid}!", "I love coding!", "Hop hop hooray!"])])],
                   funFact: "Python is named after a funny TV show, not the snake!",
                   quiz: LessonQuiz(prompt: "What does print() do?", choices: ["Shows words on the screen", "Prints on paper", "Deletes your code"],
                                    explain: "print() shows its message in the output.")),
        CodeLesson(id: "python2", track: .python, number: 2, title: "Variables are labeled boxes",
                   goal: "A program that remembers your buddy",
                   cards: [
                    LearnCard(title: "A variable stores a value",
                              text: "A variable is like a box with a label. buddy = \"Pip\" puts the word Pip in a box called buddy.",
                              example: "buddy = \"Pip\""),
                    LearnCard(title: "Join words with +",
                              text: "+ joins strings together, so you can use your variable inside a sentence.",
                              example: "print(\"Hi \" + buddy)"),
                   ],
                   lines: [
                    CodeLineTemplate("buddy = \"[[name]]\"", [slot("name", .text, "your buddy's name", ["{buddy}", "Ollie", "Pip", "Rocky", "Stella"])]),
                    CodeLineTemplate("print(\"[[start]]\" + buddy)", [slot("start", .text, "how the sentence starts", ["My buddy is ", "Hello, ", "Go go go, "])]),
                   ],
                   funFact: "Games use variables for everything: your score, your lives, your name and where you are.",
                   quiz: LessonQuiz(prompt: "In buddy = \"Pip\", what is buddy?", choices: ["A variable", "A number", "A picture"],
                                    explain: "buddy is the variable's name; \"Pip\" is the value inside.")),
        CodeLesson(id: "python3", track: .python, number: 3, title: "Math magic",
                   goal: "A program that counts your stars",
                   cards: [
                    LearnCard(title: "Python is a calculator",
                              text: "Python can add with +, subtract with - and multiply with *. It does the math, then stores the answer.",
                              example: "stars = 3 + 4"),
                    LearnCard(title: "Numbers don't need quotes",
                              text: "\"7\" in quotes is text. 7 without quotes is a number Python can do math with.", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate("stars = [[a]] [[op]] [[b]]",
                                     [slot("a", .number, "a number", ["3", "5", "8", "10"]),
                                      slot("op", .word, "add or multiply", ["+", "*"]),
                                      slot("b", .number, "another number", ["2", "4", "6"])]),
                    CodeLineTemplate("print(\"I have\", stars, \"stars\")"),
                   ],
                   funFact: "Computers can do billions of math problems every second.",
                   quiz: LessonQuiz(prompt: "What is 4 * 3 in Python?", choices: ["12", "7", "43"], explain: "* means multiply: 4 × 3 = 12.")),
        CodeLesson(id: "python4", track: .python, number: 4, title: "Loops repeat things",
                   goal: "A program that cheers again and again",
                   cards: [
                    LearnCard(title: "for loops",
                              text: "A loop repeats code so you don't have to write it again. range(3) means do it 3 times.",
                              example: "for i in range(3):\n    print(\"Hop!\")"),
                    LearnCard(title: "Spaces matter",
                              text: "The lines pushed in (indented) under the loop are the ones that repeat. Python uses 4 spaces.", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate("for i in range([[times]]):", [slot("times", .number, "how many times", ["2", "3", "5"])]),
                    CodeLineTemplate("print(\"[[cheer]]\")", indent: 1, [slot("cheer", .text, "what to repeat", ["Hop!", "Boing!", "Splash!", "Go team!"])]),
                   ],
                   funFact: "A video game draws the screen in a loop about 60 times every second!",
                   quiz: LessonQuiz(prompt: "How many times does for i in range(4): repeat?", choices: ["4", "3", "5"],
                                    explain: "range(4) counts 0, 1, 2, 3: four times.")),
        CodeLesson(id: "python5", track: .python, number: 5, title: "Decisions with if",
                   goal: "A program that decides what to say",
                   cards: [
                    LearnCard(title: "if asks a question",
                              text: "if checks whether something is true. > means 'greater than'. If the answer is yes, the pushed-in lines run.",
                              example: "if stars > 5:\n    print(\"Wow!\")"),
                    LearnCard(title: "else is the other way",
                              text: "else runs when the if answer is no. Your program makes a choice, just like you do!", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate("if stars > [[limit]]:", [slot("limit", .number, "how many stars is a lot", ["5", "10", "20"])]),
                    CodeLineTemplate("print(\"[[yes]]\")", indent: 1, [slot("yes", .text, "what to say if yes", ["Super star! 🌟", "That's a lot of stars!", "You're amazing!"])]),
                    CodeLineTemplate("else:"),
                    CodeLineTemplate("print(\"[[no]]\")", indent: 1, [slot("no", .text, "what to say if no", ["Keep collecting! ⭐", "Almost there!", "Let's find more stars!"])]),
                   ],
                   funFact: "Apps make millions of if decisions, like 'if it's dark, turn on dark mode'.",
                   quiz: LessonQuiz(prompt: "When does the else part run?", choices: ["When the if is not true", "Always", "Never"],
                                    explain: "else is the other path, when the if question is answered no.")),
    ]

    // MARK: Game Maker (Python)

    static let games: [CodeLesson] = [
        CodeLesson(id: "games1", track: .games, number: 1, title: "Set the stage",
                   goal: "A game world",
                   cards: [
                    LearnCard(title: "Games are made of code",
                              text: "Every game you play was built by people writing code. Today you start your own!", example: nil),
                    LearnCard(title: "Functions are commands",
                              text: "set_background() is a function: a command with parentheses. The word inside is its argument: which world to use.",
                              example: "set_background(\"night\")"),
                   ],
                   lines: [CodeLineTemplate("set_background(\"[[world]]\")",
                                            [slot("world", .text, "a world", ["meadow", "night", "ocean", "candy"])])],
                   funFact: "Big games can have millions of lines of code, written by hundreds of people.",
                   quiz: LessonQuiz(prompt: "What is set_background(\"night\")?", choices: ["A function with an argument", "A loop", "A picture file"],
                                    explain: "It's a function call. \"night\" is the argument you give it.")),
        CodeLesson(id: "games2", track: .games, number: 2, title: "Choose your hero",
                   goal: "A hero in your game",
                   cards: [
                    LearnCard(title: "Store the hero in a variable",
                              text: "hero = \"lavender\" keeps the hero's name in a variable. Then add_player(hero) puts that hero in the game.",
                              example: "hero = \"pip\"\nadd_player(hero)"),
                   ],
                   lines: [
                    CodeLineTemplate("hero = \"[[hero]]\"", [slot("hero", .text, "your hero", ["{buddyID}", "lavender", "rocky", "pip", "ollie"])]),
                    CodeLineTemplate("add_player(hero)"),
                   ],
                   funFact: "Game makers often test many heroes before choosing the one that feels best.",
                   quiz: LessonQuiz(prompt: "In add_player(hero), what is hero?", choices: ["A variable holding the hero's name", "A new loop", "A color"],
                                    explain: "hero is the variable you set on the line before.")),
        CodeLesson(id: "games3", track: .games, number: 3, title: "Jump on tap",
                   goal: "A hero who jumps when you tap",
                   cards: [
                    LearnCard(title: "Make your own function",
                              text: "def makes a new function. The pushed-in lines are what it does.",
                              example: "def on_tap():\n    jump(100)"),
                    LearnCard(title: "Events",
                              text: "on_tap is special: the game runs it every time you tap the screen. Code that waits for something to happen is called an event.", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate("def on_tap():"),
                    CodeLineTemplate("jump([[height]])", indent: 1, [slot("height", .number, "how high to jump", ["80", "120", "160"])]),
                   ],
                   funFact: "Every button in every app works with events, just like your on_tap.",
                   quiz: LessonQuiz(prompt: "When does on_tap() run?", choices: ["Every time you tap", "Only once", "Never"],
                                    explain: "on_tap is an event: it runs each time you tap.")),
        CodeLesson(id: "games4", track: .games, number: 4, title: "Stars with a loop",
                   goal: "Stars to collect",
                   cards: [
                    LearnCard(title: "Loops save work",
                              text: "Instead of writing add_star() five times, a loop does it for you.",
                              example: "for i in range(5):\n    add_star()"),
                   ],
                   lines: [
                    CodeLineTemplate("for i in range([[count]]):", [slot("count", .number, "how many stars", ["3", "5", "8"])]),
                    CodeLineTemplate("add_star()", indent: 1),
                   ],
                   funFact: "Game makers use loops to place trees, coins and enemies all over a level.",
                   quiz: LessonQuiz(prompt: "for i in range(5): add_star() makes how many stars?", choices: ["5", "1", "6"],
                                    explain: "The loop runs add_star() 5 times.")),
        CodeLesson(id: "games5", track: .games, number: 5, title: "Keep score and win",
                   goal: "A finished game with a score and a win",
                   cards: [
                    LearnCard(title: "Score is a variable",
                              text: "score starts at 0. Each time you grab a star, the on_star event adds points.",
                              example: "score = score + 1"),
                    LearnCard(title: "global",
                              text: "Inside a function, write global score so Python changes the same score the whole game uses.", example: nil),
                    LearnCard(title: "Win with if",
                              text: "if score >= 10: checks if you have enough points, then say() shows your winning message.", example: nil),
                   ],
                   lines: [
                    CodeLineTemplate("score = 0"),
                    CodeLineTemplate("def on_star():"),
                    CodeLineTemplate("global score", indent: 1),
                    CodeLineTemplate("score = score + [[points]]", indent: 1, [slot("points", .number, "points per star", ["1", "2", "5"])]),
                    CodeLineTemplate("if score >= [[goal]]:", indent: 1, [slot("goal", .number, "points to win", ["5", "10", "20"])]),
                    CodeLineTemplate("say(\"[[win]]\")", indent: 2, [slot("win", .text, "your winning message", ["You win! 🏆", "Level complete! ⭐", "I'm a game maker! 🎮"])]),
                   ],
                   funFact: "You just used variables, functions, events, loops and if: the same tools real game makers use!",
                   quiz: LessonQuiz(prompt: "Why do we write global score inside on_star?", choices: ["To change the game's score", "To make stars", "To jump higher"],
                                    explain: "global lets the function change the score variable everyone uses.")),
    ]

    /// Fills {kid}, {buddy} and {buddyID} in a choice.
    static func resolve(_ choice: String, kid: String, buddy: String, buddyID: String) -> String {
        choice.replacingOccurrences(of: "{kid}", with: safeName(kid))
            .replacingOccurrences(of: "{buddyID}", with: buddyID)
            .replacingOccurrences(of: "{buddy}", with: safeName(buddy))
    }

    /// Names go inside code, so keep only letters, spaces and dashes.
    static func safeName(_ s: String) -> String {
        let kept = String(s.filter { $0.isLetter || $0 == " " || $0 == "-" }.prefix(14)).trimmingCharacters(in: .whitespaces)
        return kept.isEmpty ? "Friend" : kept
    }
}

// MARK: - Building the project

/// Turns lessons + chosen values into source code and into colored lines for the editor.
struct CodeProject {
    enum TokenKind: Equatable { case plain, keyword, string, number, tag, attribute, property, comment, punctuation }

    enum Segment: Equatable {
        case code(String, TokenKind)
        /// An editable blank. `value` is nil until the child picks something.
        case slot(key: String, value: String?, kind: SlotKind)
    }

    struct Line: Identifiable, Equatable {
        let id: String
        let number: Int
        let indent: Int
        let segments: [Segment]
        /// The lesson this line came from (nil = scaffolding the child doesn't edit).
        let lessonID: String?
    }

    let track: CodeTrack
    /// Lessons whose lines are in the project (finished ones plus the current one).
    let lessons: [CodeLesson]
    let values: [String: String]
    var kid = "Friend"
    var buddy = "Buddy"
    var buddyID = "lavender"

    /// Lessons in the project: everything finished, plus the lesson being worked on.
    static func lessonsInProject(track: CodeTrack, save: CodeLabSave, current: CodeLesson?) -> [CodeLesson] {
        CodeCurriculum.lessons(for: track).filter { save.completed.contains($0.id) || $0.id == current?.id }
    }

    func value(_ key: String) -> String? {
        values[key].map { CodeCurriculum.resolve($0, kid: kid, buddy: buddy, buddyID: buddyID) }
    }

    var missingSlots: [String] {
        lessons.flatMap(\.slotKeys).filter { values[$0] == nil }
    }

    /// Runnable source. Blank slots become empty text.
    var source: String {
        render().map { line in
            String(repeating: track == .web ? "  " : "    ", count: line.indent) + line.segments.map { seg -> String in
                switch seg {
                case .code(let s, _): return s
                case .slot(_, let v, _): return v ?? ""
                }
            }.joined()
        }.joined(separator: "\n")
    }

    /// Lines for the editor, with colors and blanks.
    func render() -> [Line] {
        var raw: [(indent: Int, text: String, slots: [CodeSlot], lesson: CodeLesson?, scaffold: Bool)] = []
        func add(_ t: CodeLineTemplate, _ l: CodeLesson?, extraIndent: Int = 0) {
            raw.append((t.indent + extraIndent, t.text, t.slots, l, false))
        }
        func scaffold(_ text: String, _ indent: Int) { raw.append((indent, text, [], nil, true)) }

        if track == .web {
            scaffold("<!DOCTYPE html>", 0)
            scaffold("<html>", 0)
            scaffold("<head>", 0)
            scaffold("<style>", 1)
            for l in lessons { for t in l.lines where t.section == .style { add(t, l, extraIndent: 2) } }
            scaffold("</style>", 1)
            scaffold("</head>", 0)
            scaffold("<body>", 0)
            for l in lessons { for t in l.lines where t.section == .body { add(t, l, extraIndent: 1) } }
            scaffold("</body>", 0)
            scaffold("</html>", 0)
        } else {
            for l in lessons { for t in l.lines { add(t, l) } }
        }

        return raw.enumerated().map { i, r in
            var segs: [Segment] = []
            var rest = Substring(r.text)
            while let open = rest.range(of: "[["), let close = rest[open.upperBound...].range(of: "]]") {
                let id = String(rest[open.upperBound..<close.lowerBound])
                segs += highlight(String(rest[..<open.lowerBound]))
                if let slot = r.slots.first(where: { $0.id == id }), let lesson = r.lesson {
                    let key = "\(lesson.id).\(slot.id)"
                    segs.append(.slot(key: key, value: value(key), kind: slot.kind))
                } else {
                    segs += highlight(String(rest[open.lowerBound..<close.upperBound]))
                }
                rest = rest[close.upperBound...]
            }
            segs += highlight(String(rest))
            return Line(id: "\(i)", number: i + 1, indent: r.indent, segments: segs, lessonID: r.lesson?.id)
        }
    }

    // MARK: Syntax colors

    private static let pyKeywords: Set<String> = ["for", "in", "if", "elif", "else", "def", "global", "return", "and", "or", "not", "True", "False", "None"]
    private static let pyBuiltins: Set<String> = ["print", "range", "str", "int", "len", "set_background", "add_player", "jump", "add_star", "say"]

    func highlight(_ s: String) -> [Segment] {
        guard !s.isEmpty else { return [] }
        return track == .web ? highlightWeb(s) : highlightPython(s)
    }

    private func highlightPython(_ s: String) -> [Segment] {
        var out: [Segment] = []
        let chars = Array(s)
        var i = 0
        func push(_ t: String, _ k: TokenKind) {
            if case .code(let prev, let pk)? = out.last, pk == k { out[out.count - 1] = .code(prev + t, k) } else { out.append(.code(t, k)) }
        }
        while i < chars.count {
            let c = chars[i]
            if c == "\"" || c == "'" {
                var j = i + 1
                while j < chars.count, chars[j] != c { j += 1 }
                push(String(chars[i...min(j, chars.count - 1)]), .string)
                i = j + 1
            } else if c.isLetter || c == "_" {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" { j += 1 }
                let word = String(chars[i..<j])
                push(word, Self.pyKeywords.contains(word) ? .keyword : (Self.pyBuiltins.contains(word) ? .tag : .plain))
                i = j
            } else if c.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber { j += 1 }
                push(String(chars[i..<j]), .number)
                i = j
            } else {
                push(String(c), "():,=+-*<>".contains(c) ? .punctuation : .plain)
                i += 1
            }
        }
        return out
    }

    private func highlightWeb(_ s: String) -> [Segment] {
        var out: [Segment] = []
        let chars = Array(s)
        var i = 0
        func push(_ t: String, _ k: TokenKind) {
            if case .code(let prev, let pk)? = out.last, pk == k { out[out.count - 1] = .code(prev + t, k) } else { out.append(.code(t, k)) }
        }
        var inTag = false
        var inRule = false
        let hasRule = s.contains("{")
        while i < chars.count {
            let c = chars[i]
            if c == "<" { inTag = true; push("<", .tag); i += 1; continue }
            if c == ">" { inTag = false; push(">", .tag); i += 1; continue }
            if c == "\"" {
                var j = i + 1
                while j < chars.count, chars[j] != "\"" { j += 1 }
                push(String(chars[i...min(j, chars.count - 1)]), .string)
                i = j + 1
                continue
            }
            if c == "{" { inRule = true; push("{", .punctuation); i += 1; continue }
            if c == "}" { inRule = false; push("}", .punctuation); i += 1; continue }
            if inTag {
                var j = i
                while j < chars.count, !" =>\"".contains(chars[j]) { j += 1 }
                if j == i { push(String(c), .plain); i += 1; continue }
                let word = String(chars[i..<j])
                let isName = out.last.map { if case .code(let t, _) = $0 { return t.hasSuffix("<") || t.hasSuffix("</") || t == "/" } else { return false } } ?? false
                push(word, isName || word.hasPrefix("/") ? .tag : .attribute)
                i = j
                continue
            }
            if inRule {
                if c == " " { push(" ", .plain); i += 1; continue }
                var j = i
                while j < chars.count, !":;}".contains(chars[j]) { j += 1 }
                if j < chars.count, chars[j] == ":" {
                    push(String(chars[i..<j]), .property)
                    push(":", .punctuation)
                    i = j + 1
                } else {
                    push(String(chars[i..<j]), chars[i..<j].first?.isNumber == true ? .number : .plain)
                    if j < chars.count, chars[j] == ";" { push(";", .punctuation); j += 1 }
                    i = j
                }
                continue
            }
            // text before a { is a CSS selector (body, h1, .card)
            push(String(c), hasRule && c != " " ? .tag : .plain)
            i += 1
        }
        return out
    }
}
