import Foundation

// Brain Bubble (v8.5): a home-screen widget with one question and three answers to tap right on the widget.
// Shared by the app and the widget; tested in Tests/Learn. No streaks, no timers: just a question whenever you look.

struct BubbleQuestion: Equatable {
    let emoji: String
    let question: String
    let choices: [String]
    let answer: Int
    /// A short fun fact shown after answering.
    let fact: String
}

enum BubbleBank {
    /// 41 questions (a prime number, so stepping through them by 7 visits every one before any repeats).
    static let all: [BubbleQuestion] = [
        BubbleQuestion(emoji: "➕", question: "What is 4 + 3?", choices: ["6", "7", "8"], answer: 1, fact: "4 + 3 = 7. So does 3 + 4!"),
        BubbleQuestion(emoji: "➖", question: "What is 9 − 4?", choices: ["5", "4", "6"], answer: 0, fact: "9 take away 4 leaves 5."),
        BubbleQuestion(emoji: "🔟", question: "What is 10 + 6?", choices: ["106", "16", "15"], answer: 1, fact: "Ten and six more make 16."),
        BubbleQuestion(emoji: "✋", question: "How many fingers on two hands?", choices: ["5", "8", "10"], answer: 2, fact: "Five and five make ten!"),
        BubbleQuestion(emoji: "🕷️", question: "How many legs does a spider have?", choices: ["6", "8", "10"], answer: 1, fact: "Spiders have 8 legs. Insects have 6."),
        BubbleQuestion(emoji: "🐞", question: "How many legs does an insect have?", choices: ["6", "4", "8"], answer: 0, fact: "Every insect has 6 legs."),
        BubbleQuestion(emoji: "🔺", question: "How many sides does a triangle have?", choices: ["4", "3", "5"], answer: 1, fact: "Tri means three!"),
        BubbleQuestion(emoji: "⬛", question: "How many corners does a square have?", choices: ["4", "3", "6"], answer: 0, fact: "A square has 4 sides and 4 corners."),
        BubbleQuestion(emoji: "📅", question: "How many days are in a week?", choices: ["5", "7", "10"], answer: 1, fact: "Seven days, from Sunday to Saturday."),
        BubbleQuestion(emoji: "🗓️", question: "How many months are in a year?", choices: ["10", "12", "7"], answer: 1, fact: "Twelve months, January to December."),
        BubbleQuestion(emoji: "🌈", question: "How many colors are in a rainbow?", choices: ["7", "3", "12"], answer: 0, fact: "Red, orange, yellow, green, blue, indigo, violet."),
        BubbleQuestion(emoji: "☀️", question: "What is the closest star to Earth?", choices: ["The Moon", "The Sun", "Mars"], answer: 1, fact: "The Sun is a star! The Moon and Mars aren't stars."),
        BubbleQuestion(emoji: "🌙", question: "What goes around the Earth?", choices: ["The Sun", "The Moon", "A comet"], answer: 1, fact: "The Moon goes around the Earth about once a month."),
        BubbleQuestion(emoji: "🧊", question: "What is ice made of?", choices: ["Water", "Glass", "Salt"], answer: 0, fact: "Ice is frozen water. Warm it up and it melts!"),
        BubbleQuestion(emoji: "🌱", question: "What do plants need to grow?", choices: ["Candy", "Sunlight and water", "Toys"], answer: 1, fact: "Plants make food from sunlight, water and air."),
        BubbleQuestion(emoji: "🐳", question: "Which of these is a mammal?", choices: ["Shark", "Whale", "Goldfish"], answer: 1, fact: "Whales breathe air and feed their babies milk."),
        BubbleQuestion(emoji: "🐣", question: "Which of these hatches from an egg?", choices: ["Puppy", "Chick", "Kitten"], answer: 1, fact: "Birds, turtles and frogs all hatch from eggs."),
        BubbleQuestion(emoji: "🐛", question: "What does a caterpillar turn into?", choices: ["A butterfly", "A bee", "A worm"], answer: 0, fact: "It makes a chrysalis, then comes out as a butterfly."),
        BubbleQuestion(emoji: "🐸", question: "What is a baby frog called?", choices: ["Kitten", "Tadpole", "Cub"], answer: 1, fact: "Tadpoles swim with tails, then grow legs!"),
        BubbleQuestion(emoji: "🦒", question: "Which animal has the longest neck?", choices: ["Giraffe", "Horse", "Elephant"], answer: 0, fact: "A giraffe's neck can be taller than a grown-up!"),
        BubbleQuestion(emoji: "🐝", question: "What do bees make?", choices: ["Milk", "Honey", "Silk"], answer: 1, fact: "Bees make honey from flower nectar."),
        BubbleQuestion(emoji: "🦴", question: "What holds your body up?", choices: ["Your bones", "Your hair", "Your nails"], answer: 0, fact: "You have about 206 bones when you're grown!"),
        BubbleQuestion(emoji: "👃", question: "Which sense uses your nose?", choices: ["Hearing", "Smell", "Touch"], answer: 1, fact: "Your nose can tell apart lots of smells."),
        BubbleQuestion(emoji: "🎩", question: "Which word rhymes with hat?", choices: ["Hot", "Cat", "Hen"], answer: 1, fact: "Hat, cat, bat and mat all rhyme."),
        BubbleQuestion(emoji: "⬆️", question: "What is the opposite of up?", choices: ["Down", "Over", "Left"], answer: 0, fact: "Up and down are opposites."),
        BubbleQuestion(emoji: "🔥", question: "What is the opposite of hot?", choices: ["Warm", "Cold", "Big"], answer: 1, fact: "Hot and cold are opposites."),
        BubbleQuestion(emoji: "🐘", question: "What is the opposite of big?", choices: ["Small", "Tall", "Heavy"], answer: 0, fact: "Big and small are opposites."),
        BubbleQuestion(emoji: "🔤", question: "Which letter comes after C?", choices: ["B", "D", "E"], answer: 1, fact: "A, B, C, D!"),
        BubbleQuestion(emoji: "🅰️", question: "Which of these is a vowel?", choices: ["B", "T", "A"], answer: 2, fact: "The vowels are A, E, I, O and U."),
        BubbleQuestion(emoji: "🍎", question: "What sound does apple start with?", choices: ["a", "p", "l"], answer: 0, fact: "A is for apple!"),
        BubbleQuestion(emoji: "🚦", question: "What does a red light mean?", choices: ["Go", "Stop", "Hurry"], answer: 1, fact: "Red means stop. Green means go."),
        BubbleQuestion(emoji: "🚸", question: "Before crossing the street, you should…", choices: ["Run fast", "Look both ways", "Close your eyes"], answer: 1, fact: "Stop, look left and right, and hold a grown-up's hand."),
        BubbleQuestion(emoji: "🕒", question: "How many minutes are in an hour?", choices: ["30", "60", "100"], answer: 1, fact: "Sixty minutes make one hour."),
        BubbleQuestion(emoji: "🪙", question: "How many cents are in a dime?", choices: ["5", "10", "25"], answer: 1, fact: "A dime is worth 10 cents."),
        BubbleQuestion(emoji: "🌍", question: "How many continents are there?", choices: ["5", "7", "9"], answer: 1, fact: "Africa, Antarctica, Asia, Australia, Europe, North and South America."),
        BubbleQuestion(emoji: "🧲", question: "What does a magnet pull?", choices: ["Paper", "Iron", "Wood"], answer: 1, fact: "Magnets pull iron and steel."),
        BubbleQuestion(emoji: "🌊", question: "Is ocean water salty or sweet?", choices: ["Salty", "Sweet", "Spicy"], answer: 0, fact: "Ocean water is salty. Don't drink it!"),
        BubbleQuestion(emoji: "🥕", question: "Which part of a carrot do we eat?", choices: ["The flower", "The root", "The seed"], answer: 1, fact: "Carrots are roots that grow under the ground."),
        BubbleQuestion(emoji: "🦉", question: "When are owls most awake?", choices: ["At night", "At lunch", "In the morning"], answer: 0, fact: "Owls hunt at night. They're nocturnal!"),
        BubbleQuestion(emoji: "✖️", question: "What is 2 groups of 3?", choices: ["5", "6", "9"], answer: 1, fact: "3 + 3 = 6, so 2 groups of 3 is 6."),
        BubbleQuestion(emoji: "🍕", question: "A pizza cut into 2 equal parts. Each part is…", choices: ["A half", "A third", "A quarter"], answer: 0, fact: "Two equal parts are called halves."),
    ]
    static let step = 7
}

struct BrainBubble: Codable, Equatable {
    /// How many questions have gone by; the question shown is `start + turn × 7`, so every question comes up once per lap.
    var start = 0
    var turn = 0
    var picked: Int?
    var answered = 0
    var right = 0

    var index: Int { (start + turn * BubbleBank.step) % BubbleBank.all.count }
    var question: BubbleQuestion { BubbleBank.all[index] }
    var isAnswered: Bool { picked != nil }
    var gotIt: Bool { picked == question.answer }

    /// Tap an answer. One try per question; the right answer is shown either way.
    /// `asked` is the question the tapped widget was showing: a tap from an out-of-date widget is ignored.
    mutating func pick(_ i: Int, asked: Int? = nil) {
        if let asked, asked != index { return }
        guard picked == nil, question.choices.indices.contains(i) else { return }
        picked = i
        answered += 1
        if i == question.answer { right += 1 }
    }

    /// `asked` is the question the tapped widget was showing: a second tap from an out-of-date widget doesn't skip a question.
    mutating func next(asked: Int? = nil) {
        if let asked, asked != index { return }
        turn += 1
        picked = nil
    }
}

extension SharedStore {
    static let bubbleKey = "hopquest.widget.brainbubble"

    static func loadBubble(_ d: UserDefaults? = defaults) -> BrainBubble {
        if let data = d?.data(forKey: bubbleKey), let b = try? JSONDecoder().decode(BrainBubble.self, from: data) { return b }
        // the first question is picked once and saved, so the question shown is the question answered
        var b = BrainBubble()
        b.start = Int.random(in: 0..<BubbleBank.all.count)
        save(b, d)
        return b
    }

    static func save(_ b: BrainBubble, _ d: UserDefaults? = defaults) {
        guard let d, let data = try? JSONEncoder().encode(b) else { return }
        d.set(data, forKey: bubbleKey)
    }
}
