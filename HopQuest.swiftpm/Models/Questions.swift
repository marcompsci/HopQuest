import Foundation
import CoreGraphics

enum Subject: String {
    case math = "Math"
    case road = "Road Safety"
    case nature = "Nature"
    case science = "Science"
    case words = "Words"
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
    static func deck(for chapter: Chapter) -> [Question] {
        var deck = road + nature + science + words
        for _ in 0..<8 {
            deck.append(math(level: chapter.difficulty))
        }
        return deck.shuffled()
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

    private static func number(_ prompt: String, _ correct: Int, explain: String) -> Question {
        var set: Set<Int> = [correct]
        while set.count < 4 {
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
}
