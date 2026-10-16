import Foundation
import CoreGraphics

enum Subject: String {
    case math = "Math"
    case road = "Road Safety"
    case nature = "Nature"
    case science = "Science"
    case words = "Words"
    case coding = "Coding"
    case kindness = "Kindness"
}

struct Question: Identifiable {
    let id = UUID()
    let subject: Subject
    let prompt: String
    let choices: [String]
    let answer: Int
    let explain: String
}

/// Questions shown at Brain Gates. Answers never "fail" a kid — wrong picks just get a hint and another try.
enum QuestionBank {
    /// Who questions are pitched at: 1 little (4–5), 2 growing (6–7), 3 big (8–10).
    /// GameStore keeps this in sync with the grown-ups' setting and how the child is doing.
    static var tier = 2

    static func deck(for chapter: Chapter) -> [Question] {
        var deck: [Question]
        switch tier {
        case 1:
            deck = road + nature
            deck += Array(science.prefix(4))
            deck += littleWords
            for _ in 0..<8 { deck.append(littleMath()) }
        case 3:
            deck = Array(road.shuffled().prefix(4))
            deck += Array(nature.shuffled().prefix(3))
            deck += Array(science.shuffled().prefix(2))
            deck += bigScience
            deck += bigWords
            deck += bigNature
            for _ in 0..<8 { deck.append(bigMath(level: chapter.difficulty)) }
        default:
            deck = road + nature + science + words
            for _ in 0..<8 { deck.append(math(level: chapter.difficulty)) }
        }
        return deck.shuffled()
    }

    /// One question on a subject, pitched at the current learning level (used by Hop Village buddies).
    static func one(_ subject: Subject) -> Question {
        let pool: [Question]
        switch (subject, tier) {
        case (.math, 1): return littleMath()
        case (.math, 3): return bigMath(level: 0.4)
        case (.math, _): return math(level: 0.3)
        case (.road, _): pool = road
        case (.nature, 3): pool = nature + bigNature
        case (.nature, _): pool = nature
        case (.science, 1): pool = Array(science.prefix(4))
        case (.science, 3): pool = science + bigScience
        case (.science, _): pool = science
        case (.words, 1): pool = littleWords
        case (.words, 3): pool = words + bigWords
        case (.words, _): pool = words
        case (.coding, _): pool = coding
        case (.kindness, _): pool = kindness
        }
        return pool.randomElement() ?? math(level: 0.3)
    }

    /// Little learners: counting pictures and adding within 5, with only three answers to pick from.
    static func littleMath() -> Question {
        if Bool.random() {
            let things = ["🍎", "⭐", "🐟", "🎈", "🌼"].randomElement()!
            let n = Int.random(in: 2...6)
            return number("How many \(things) do you see?\n\(String(repeating: things + " ", count: n))", n,
                          explain: "Let's count them together: \((1...n).map(String.init).joined(separator: ", ")). That's \(n)!", choices: 3)
        }
        let a = Int.random(in: 1...3), b = Int.random(in: 1...2)
        return number("What is \(a) + \(b)?", a + b,
                      explain: "Hold up \(a) fingers, then \(b) more. Count them all: \(a + b)!", choices: 3)
    }

    /// Big learners: times tables, two-digit adding, and sharing (division).
    static func bigMath(level: CGFloat) -> Question {
        switch Int.random(in: 0..<3) {
        case 0:
            let a = Int.random(in: 3...9), b = Int.random(in: 3...9)
            return number("What is \(a) × \(b)?", a * b, explain: "\(a) groups of \(b) is \(a * b).")
        case 1:
            let a = Int.random(in: 15...49), b = Int.random(in: 11...39)
            return number("What is \(a) + \(b)?", a + b,
                          explain: "Add the tens, then the ones: \(a / 10 * 10 + b / 10 * 10) + \(a % 10 + b % 10) = \(a + b).")
        default:
            let b = Int.random(in: 2...6), q = Int.random(in: 2...8)
            return number("Share \(b * q) cookies equally with \(b) friends. How many does each friend get?", q,
                          explain: "\(b * q) ÷ \(b) = \(q), because \(b) × \(q) = \(b * q).")
        }
    }

    static func math(level: CGFloat) -> Question {
        if level < 0.3 {
            let a = Int.random(in: 1...9), b = Int.random(in: 1...9)
            return number("What is \(a) + \(b)?", a + b,
                          explain: "\(a) plus \(b) makes \(a + b). Try counting up from \(a)!")
        } else if level < 0.7 {
            let a = Int.random(in: 10...20), b = Int.random(in: 1...9)
            return number("What is \(a) − \(b)?", a - b,
                          explain: "Start at \(a) and count back \(b). You land on \(a - b).")
        } else {
            let a = Int.random(in: 2...6), b = Int.random(in: 2...5)
            return number("What is \(a) × \(b)?", a * b,
                          explain: "\(a) groups of \(b) is \(a * b).")
        }
    }

    private static func number(_ prompt: String, _ correct: Int, explain: String, choices: Int = 4) -> Question {
        var set: Set<Int> = [correct]
        while set.count < choices {
            let candidate = correct + Int.random(in: -3...3)
            if candidate >= 0 { set.insert(candidate) }
        }
        let options = Array(set).shuffled()
        return Question(subject: .math, prompt: prompt,
                        choices: options.map { String($0) },
                        answer: options.firstIndex(of: correct) ?? 0,
                        explain: explain)
    }

    /// The first choice passed in is always the correct one; it gets shuffled here.
    private static func q(_ subject: Subject, _ prompt: String, _ choices: [String], _ explain: String) -> Question {
        let correct = choices[0]
        let shuffled = choices.shuffled()
        return Question(subject: subject, prompt: prompt, choices: shuffled,
                        answer: shuffled.firstIndex(of: correct) ?? 0, explain: explain)
    }

    static var road: [Question] { [
        q(.road, "Before you cross the street, which way do you look?",
          ["Left, right, then left again", "Only straight ahead", "Up at the sky"],
          "Look left, right, and left again — cars can come from both sides!"),
        q(.road, "What does a RED traffic light mean?", ["Stop", "Go fast", "Honk the horn"],
          "Red means stop and wait."),
        q(.road, "What does a GREEN traffic light mean?", ["Go, when it's safe", "Stop", "Turn around"],
          "Green means go — but still check that the way is clear."),
        q(.road, "What does a YELLOW traffic light mean?", ["Slow down, red is coming", "Speed up", "Park the car"],
          "Yellow is a warning: the light is about to turn red."),
        q(.road, "What shape is a STOP sign?", ["Octagon (8 sides)", "Circle", "Triangle"],
          "A stop sign has 8 sides. That shape is called an octagon."),
        q(.road, "Where is the safest place to cross the street?", ["At a crosswalk", "Between parked cars", "Wherever is closest"],
          "Crosswalks are where drivers expect people to cross."),
        q(.road, "What should everyone in a car wear?", ["A seat belt", "Sunglasses", "A crown"],
          "Seat belts keep you safely in your seat."),
        q(.road, "What should you wear on a bike or skateboard?", ["A helmet", "Flip-flops", "A cape"],
          "Helmets protect your brain if you fall."),
    ] }

    static var nature: [Question] { [
        q(.nature, "Which one is a vegetable?", ["Carrot", "Banana", "Grapes"],
          "Carrots are roots that grow under the ground."),
        q(.nature, "Which animal has black and white stripes?", ["Zebra", "Elephant", "Lion"],
          "Zebras have stripes, and no two zebras match!"),
        q(.nature, "What do plants need to grow?", ["Sunlight, water, and soil", "Candy and soda", "Video games"],
          "Plants make their food from sunlight and water."),
        q(.nature, "Which animal is the tallest?", ["Giraffe", "Penguin", "Rabbit"],
          "Giraffes are the tallest animals on land."),
        q(.nature, "Broccoli is really a bunch of tiny…", ["Flower buds", "Rocks", "Feathers"],
          "Each little broccoli bump is a flower bud."),
        q(.nature, "What do bees make?", ["Honey", "Milk", "Bread"],
          "Bees turn flower nectar into honey."),
        q(.nature, "Which fruit is yellow and gets peeled?", ["Banana", "Strawberry", "Blueberry"],
          "You peel a banana before you eat it."),
    ] }

    static var science: [Question] { [
        q(.science, "What makes a robot's wheels spin?", ["Motors", "Stickers", "Paint"],
          "Motors turn electricity into spinning motion."),
        q(.science, "What gives a robot energy?", ["A battery", "A pillow", "A sandwich"],
          "Batteries store electricity for robots to use."),
        q(.science, "What do magnets stick to?", ["Some metals, like iron", "Wood", "Paper"],
          "Magnets pull on metals like iron and steel."),
        q(.science, "Which one is a liquid?", ["Water", "Ice", "A rock"],
          "Water flows and takes the shape of its cup — that's a liquid."),
        q(.science, "What pulls things down to the ground?", ["Gravity", "Wind", "Music"],
          "Gravity pulls everything toward the Earth."),
        q(.science, "How many legs does a spider have?", ["8", "6", "4"],
          "Spiders have 8 legs. Insects have 6."),
    ] }

    static var words: [Question] { [
        q(.words, "Which word rhymes with CAT?", ["Hat", "Dog", "Sun"],
          "Cat and hat both end with \"-at\"."),
        q(.words, "Which word starts with the same sound as BALLOON?", ["Bear", "Moon", "Cake"],
          "Balloon and bear both start with B."),
        q(.words, "What's the opposite of HOT?", ["Cold", "Big", "Fast"],
          "Hot and cold are opposites."),
        q(.words, "How many letters are in the word STAR?", ["4", "3", "5"],
          "S-T-A-R: that's 4 letters."),
        q(.words, "Which word means a big home for a king or queen?", ["Castle", "Tent", "Cave"],
          "Castles are where kings and queens live in stories."),
    ] }

    // MARK: Little learners (short words, pictures)

    static var littleWords: [Question] { [
        q(.words, "Which word rhymes with CAT?", ["Hat", "Dog", "Sun"],
          "Cat and hat both end with \"-at\"."),
        q(.words, "What's the opposite of BIG?", ["Small", "Red", "Fast"],
          "Big and small are opposites."),
        q(.words, "Which one starts with the B sound? 🐻", ["Bear", "Moon", "Cake"],
          "B-B-Bear starts with B."),
        q(.words, "What sound does a cow make?", ["Moo", "Quack", "Woof"],
          "Cows say moo!"),
    ] }

    // MARK: Big learners (8–10)

    static var bigScience: [Question] { [
        q(.science, "Which planet is closest to the Sun?", ["Mercury", "Mars", "Jupiter"],
          "Mercury is the closest planet to the Sun, and the smallest."),
        q(.science, "What do plants take in from the air to make food?", ["Carbon dioxide", "Salt", "Smoke"],
          "Plants use sunlight, water, and carbon dioxide to make sugar. That's photosynthesis!"),
        q(.science, "When water boils and turns into a gas, what is it called?", ["Steam", "Ice", "Juice"],
          "Boiling turns liquid water into a gas called water vapor, or steam."),
        q(.science, "A ramp that makes lifting easier is which simple machine?", ["Inclined plane", "Magnet", "Battery"],
          "Ramps are inclined planes, one of the six simple machines."),
        q(.science, "What part of a robot follows the code people write?", ["The computer chip", "The wheels", "The paint"],
          "A tiny computer called a microcontroller runs the code."),
    ] }

    static var bigWords: [Question] { [
        q(.words, "Which word means the same as HAPPY?", ["Joyful", "Tired", "Angry"],
          "Joyful and happy are synonyms: words that mean the same thing."),
        q(.words, "Which word is spelled correctly?", ["Because", "Becuase", "Becawse"],
          "B-E-C-A-U-S-E spells because."),
        q(.words, "Which word is a verb (an action word)?", ["Jump", "Blue", "Table"],
          "Jump is something you do, so it's a verb."),
        q(.words, "What is the plural of MOUSE?", ["Mice", "Mouses", "Meese"],
          "One mouse, two mice. Some plurals are irregular!"),
    ] }

    static var coding: [Question] { [
        q(.coding, "What does print(\"Hi\") do in Python?", ["Shows Hi on the screen", "Prints on paper", "Deletes Hi"], "print() shows its message."),
        q(.coding, "Which tag makes a big heading on a web page?", ["<h1>", "<p>", "<li>"], "<h1> is the biggest heading."),
        q(.coding, "What is a loop for?", ["Repeating code", "Drawing a circle", "Ending a program"], "Loops repeat code so you don't have to write it again."),
        q(.coding, "What is a variable?", ["A labeled box that stores a value", "A kind of bug", "A web page"], "Variables store values, like score = 0."),
        q(.coding, "Which language styles colors on a web page?", ["CSS", "HTML", "Python"], "CSS decides how things look."),
        q(.coding, "A mistake in code is called a…", ["Bug", "Bee", "Button"], "Fixing bugs is called debugging!"),
        q(.coding, "What does if do?", ["Makes a decision", "Repeats forever", "Draws a picture"], "if checks if something is true, then decides what to do."),
        q(.coding, "An event like on_tap runs…", ["When something happens", "Only at the very start", "Never"], "Events wait for something to happen, like a tap."),
    ] }

    static var kindness: [Question] { [
        q(.kindness, "A friend drops their blocks. What's a kind thing to do?", ["Help pick them up", "Laugh", "Walk away"], "Helping shows you care."),
        q(.kindness, "Someone looks sad and alone. You could…", ["Ask them to play", "Ignore them", "Point at them"], "Inviting someone in can make their whole day."),
        q(.kindness, "You lose a game. A good sport says…", ["Good game!", "That's not fair!", "I quit!"], "Good sports are kind, win or lose."),
        q(.kindness, "If you bump into someone by accident, you say…", ["I'm sorry, are you okay?", "Move!", "Nothing"], "Saying sorry helps fix little accidents."),
        q(.kindness, "How can you show you're listening?", ["Look at them and wait your turn", "Talk over them", "Play with a toy"], "Good listeners look and wait their turn to talk."),
        q(.kindness, "Your buddy feels nervous. You could say…", ["You can do it! I'll help.", "That's silly.", "Hurry up."], "Encouraging words help friends feel brave."),
    ] }

    static var bigNature: [Question] { [
        q(.nature, "Which animal is a mammal?", ["Dolphin", "Shark", "Salmon"],
          "Dolphins breathe air and feed their babies milk, so they're mammals."),
        q(.nature, "What do caterpillars turn into?", ["Butterflies", "Bees", "Spiders"],
          "Caterpillars make a chrysalis and come out as butterflies. That's metamorphosis!"),
        q(.nature, "Where does most rain come from?", ["Water evaporating from oceans", "Mountains", "The Moon"],
          "The Sun warms ocean water into vapor, it forms clouds, then falls as rain: the water cycle."),
    ] }
}
