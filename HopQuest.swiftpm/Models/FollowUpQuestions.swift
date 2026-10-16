import Foundation

/// A question written as plain data (turned into a Brain Gate `Question` by the app).
struct QuizItem: Equatable {
    let subject: String          // matches Subject raw values: Math, Road Safety, Nature, Science, Words, Coding, Kindness
    let prompt: String
    let choices: [String]        // the first one is the right answer; the app shuffles them
    let explain: String
}

/// Follow-up questions the pop-quiz buddy asks about games the child has actually played.
enum FollowUpBank {
    static func items(for c: VillageChallenge) -> [QuizItem] {
        switch c {
        case .meadow:
            return [
                QuizItem(subject: "Road Safety", prompt: "In Meadow Street you hopped across roads. What do you do before crossing?",
                         choices: ["Stop and look both ways", "Run fast", "Close your eyes"], explain: "Stop, look left, look right, and look left again."),
                QuizItem(subject: "Road Safety", prompt: "Where is the safest place to cross a street?",
                         choices: ["At a crosswalk", "Between parked cars", "Around a corner"], explain: "Crosswalks are where drivers expect people to cross."),
            ]
        case .driving:
            return [
                QuizItem(subject: "Road Safety", prompt: "At Driving School, what does a red light mean?",
                         choices: ["Stop", "Go faster", "Honk"], explain: "Red means stop. Green means go when it's safe."),
                QuizItem(subject: "Road Safety", prompt: "Which pedal makes the car slow down?",
                         choices: ["The brake", "The gas", "The radio"], explain: "The brake slows the car. The gas makes it go."),
                QuizItem(subject: "Road Safety", prompt: "What do blinkers tell other drivers?",
                         choices: ["Which way you will turn", "That you're hungry", "What song is playing"], explain: "Blinkers show which way you're about to turn."),
            ]
        case .robot:
            return [
                QuizItem(subject: "Science", prompt: "In the Robot Lab, which part gives a robot its power?",
                         choices: ["The battery", "The wheels", "The paint"], explain: "Batteries store the energy that makes robots go."),
                QuizItem(subject: "Science", prompt: "What does a robot's sensor do?",
                         choices: ["Notices things around it", "Makes it heavy", "Keeps it warm"], explain: "Sensors help robots see, hear or feel what's around them."),
                QuizItem(subject: "Math", prompt: "Code: Forward, Forward, Forward. How many steps does the robot take?",
                         choices: ["3", "2", "4"], explain: "Each Forward block is one step: 1, 2, 3!"),
            ]
        case .lily:
            return [
                QuizItem(subject: "Nature", prompt: "In Lily River you hopped on lily pads. Where do lily pads grow?",
                         choices: ["In ponds and rivers", "On mountains", "In the desert"], explain: "Lily pads float on calm, fresh water."),
                QuizItem(subject: "Nature", prompt: "Which animal loves to sit on lily pads?",
                         choices: ["A frog", "A camel", "A penguin"], explain: "Frogs rest on lily pads and hunt bugs from them."),
            ]
        case .rally:
            return [
                QuizItem(subject: "Road Safety", prompt: "In City Rally, what should you do at a stop sign?",
                         choices: ["Stop all the way", "Slow down a little", "Speed up"], explain: "A stop sign means come to a full stop and look."),
                QuizItem(subject: "Road Safety", prompt: "Why do cars have seat belts?",
                         choices: ["To keep you safe", "To look cool", "To hold snacks"], explain: "Seat belts keep everyone safe in their seats."),
            ]
        case .castleHill:
            return [
                QuizItem(subject: "Words", prompt: "Castle Hill was the longest hop! Which word means 'very big'?",
                         choices: ["Huge", "Tiny", "Quiet"], explain: "Huge means very, very big."),
                QuizItem(subject: "Math", prompt: "A castle has 4 towers. Two more are built. How many towers now?",
                         choices: ["6", "5", "8"], explain: "4 + 2 = 6 towers."),
            ]
        case .fort:
            return [
                QuizItem(subject: "Science", prompt: "In Fort Friends you built ramps. What does a ramp help you do?",
                         choices: ["Go up a little at a time", "Fly", "Dig a hole"], explain: "A ramp is an inclined plane. It makes climbing easier."),
                QuizItem(subject: "Science", prompt: "Why does a bridge need strong supports?",
                         choices: ["So it doesn't fall down", "So it looks shiny", "So it's noisy"], explain: "Supports hold up the weight of everything on the bridge."),
            ]
        case .bop:
            return [
                QuizItem(subject: "Words", prompt: "After a Pillow Bop match, what does a good sport say?",
                         choices: ["Good game!", "You're bad!", "Nothing"], explain: "Saying 'Good game' shows kindness, win or lose."),
                QuizItem(subject: "Math", prompt: "You bopped 3 bots, then 4 more. How many bops?",
                         choices: ["7", "6", "8"], explain: "3 + 4 = 7 bops!"),
            ]
        case .coding:
            return [
                QuizItem(subject: "Coding", prompt: "In the Coding Lab, what does a for loop do?",
                         choices: ["Repeats code", "Makes a picture", "Ends the game"], explain: "for loops repeat the lines inside them."),
                QuizItem(subject: "Coding", prompt: "Which tag did you use for a big title on your web page?",
                         choices: ["<h1>", "<p>", "<ul>"], explain: "<h1> makes the biggest heading."),
                QuizItem(subject: "Coding", prompt: "What do we call a mistake in code?",
                         choices: ["A bug", "A bump", "A badge"], explain: "Finding and fixing bugs is called debugging."),
            ]
        case .kart:
            return [
                QuizItem(subject: "Science", prompt: "In Bubble Kart, what makes a kart slow down on a turn?",
                         choices: ["Letting go of the gas", "Honking", "Waving"], explain: "Slowing down helps you turn without sliding."),
                QuizItem(subject: "Words", prompt: "If you come in first place, you are the…",
                         choices: ["Winner", "Loser", "Driver's seat"], explain: "First place means you won the race!"),
            ]
        }
    }

    /// For kids who haven't finished a game yet: general follow-ups about the village.
    static let general: [QuizItem] = [
        QuizItem(subject: "Road Safety", prompt: "Before you cross a road, you should…", choices: ["Look both ways", "Run", "Hop backwards"], explain: "Always stop and look both ways."),
        QuizItem(subject: "Nature", prompt: "Butterflies in the village like to visit…", choices: ["Flowers", "Rocks", "Cars"], explain: "Butterflies sip nectar from flowers."),
        QuizItem(subject: "Math", prompt: "There are 2 benches on each side of the fountain. That's 2 sides. How many benches?", choices: ["4", "2", "3"], explain: "2 + 2 = 4 benches."),
    ]

    /// Picks a follow-up about one of the finished challenges (or a general one), rotating so repeats are rare.
    static func pick(done: [VillageChallenge], turn: Int) -> QuizItem {
        let pool = done.isEmpty ? general : done.flatMap { items(for: $0) }
        return pool[abs(turn) % pool.count]
    }
}
