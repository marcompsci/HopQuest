import Foundation

// Español (v6.5): the interface in Spanish. Learning content (questions, word lists, stories) stays in English for now;
// reading and spelling games teach English on purpose. Plain Swift, tested in Tests/Learn.

enum AppLanguage: String, CaseIterable, Identifiable {
    case automatic, english, spanish
    var id: String { rawValue }
    var label: String {
        switch self {
        case .automatic: return "Automatic / Automático"
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
}

enum L10n {
    static let key = "hopquest.language"

    /// Spanish when chosen, or when "automatic" and the device prefers Spanish.
    static var isSpanish: Bool {
        let choice = AppLanguage(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .automatic
        switch choice {
        case .spanish: return true
        case .english: return false
        case .automatic: return (Locale.preferredLanguages.first ?? "en").hasPrefix("es")
        }
    }

    /// A word or line in the current language (unchanged when there is no translation).
    static func tr(_ s: String) -> String { isSpanish ? (spanish(s) ?? s) : s }

    /// The Spanish for a whole line, or nil when part of it has no translation.
    static func spanish(_ s: String) -> String? {
        if let hit = table[s] { return hit }
        for (re, template) in patterns {
            let range = NSRange(s.startIndex..., in: s)
            if re.firstMatch(in: s, range: range) != nil { return re.stringByReplacingMatches(in: s, range: range, withTemplate: template) }
        }
        return nil
    }

    /// For the narrator: every sentence translated, or nil (so it never mixes languages in one breath).
    static func spanishSpeech(_ text: String) -> String? {
        if let whole = spanish(text) { return whole }
        var parts: [String] = []
        var current = ""
        for ch in text {
            current.append(ch)
            if ".!?".contains(ch) { parts.append(current.trimmingCharacters(in: .whitespaces)); current = "" }
        }
        let rest = current.trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty { parts.append(rest) }
        guard parts.count > 1 else { return nil }
        var out: [String] = []
        for p in parts { guard let t = spanish(p) else { return nil }; out.append(t) }
        return out.joined(separator: " ")
    }

    static let patterns: [(NSRegularExpression, String)] = rawPatterns.compactMap { p in
        (try? NSRegularExpression(pattern: p.0)).map { ($0, p.1) }
    }

    static let rawPatterns: [(String, String)] = [
        ("^Hi, (.+)!$", "¡Hola, $1!"),
        ("^(\\d+) stars$", "$1 estrellas"),
        ("^(\\d+) of (\\d+) stars$", "$1 de $2 estrellas"),
        ("^(\\d+) of (\\d+) challenges$", "$1 de $2 retos"),
        ("^(\\d+) more to open your castle$", "Faltan $1 para abrir tu castillo"),
        ("^(\\d+) of 7 postcards$", "$1 de 7 postales"),
        ("^(\\d+) stories$", "$1 cuentos"),
        ("^Best (\\d+)$", "Récord $1"),
        ("^(\\d+) of (\\d+) earned$", "$1 de $2 ganadas"),
        ("^You did it! (\\d+) new stars!$", "¡Lo lograste! ¡$1 estrellas nuevas!"),
        ("^(\\d+) of (\\d+) lessons$", "$1 de $2 lecciones"),
        ("^(\\d+) of (\\d+) levels done$", "$1 de $2 niveles hechos"),
        ("^Page (\\d+) of (\\d+)$", "Página $1 de $2"),
        ("^Postcards (\\d+) of 7$", "Postales $1 de 7"),
        ("^(\\d+) of (\\d+) right on the first try$", "$1 de $2 bien al primer intento"),
        ("^(.+) done!$", "¡$1 terminado!"),
        ("^(\\d+) new stars?$", "$1 estrellas nuevas"),
        ("^(\\d+) of (\\d+)$", "$1 de $2"),
    ]

    static let table: [String: String] = [
        "1 new star": "1 estrella nueva",
        "Play": "Jugar",
        "Hop Village": "Pueblo Salto",
        "Adventures": "Aventuras",
        "Games": "Juegos",
        "Learn": "Aprender",
        "Worlds": "Mundos",
        "Stickers": "Calcomanías",
        "Fort Friends": "Amigos del Fuerte",
        "Pillow Bop": "Almohadazos",
        "Bubble Kart": "Kart Burbuja",
        "Star Dash": "Carrera Estelar",
        "1-minute quick game": "Juego rápido de 1 minuto",
        "Coding Lab": "Laboratorio de Código",
        "Web pages, Python and games": "Páginas web, Python y juegos",
        "Reading Nook": "Rincón de Lectura",
        "Math Market": "Mercado de Mate",
        "Science Lab": "Laboratorio de Ciencias",
        "Music Maker": "Creador de Música",
        "Writing Desk": "Escritorio de Escritura",
        "Clock Tower": "Torre del Reloj",
        "Around the World": "La Vuelta al Mundo",
        "Spelling Bee": "Concurso de Deletreo",
        "Fraction Bakery": "Panadería de Fracciones",
        "Shape Studio": "Estudio de Figuras",
        "Story Maker": "Creador de Cuentos",
        "Badges": "Insignias",
        "My Castle": "Mi Castillo",
        "Adventure Map": "Mapa de Aventuras",
        "Together": "Juntos",
        "Stories": "Cuentos",
        "Grown-ups": "Adultos",
        "Change your buddy": "Cambia tu amigo",
        "Your castle is open!": "¡Tu castillo está abierto!",
        "Badges never go away once you earn them.": "Las insignias son tuyas para siempre.",
        "Your badges! Tap one to see how to earn it.": "¡Tus insignias! Toca una para ver cómo ganarla.",
        "You earned this badge!": "¡Ganaste esta insignia!",
        "Done": "Listo",
        "Again": "Otra vez",
        "Back": "Atrás",
        "Next page": "Siguiente página",
        "Play again": "Jugar otra vez",
        "Read my story": "Leer mi cuento",
        "The End": "Fin",
        "Make a new story": "Hacer un cuento nuevo",
        "My stories": "Mis cuentos",
        "Show me": "Muéstrame",
        "Stop playing": "Dejar de jugar",
        "Say it again": "Dilo otra vez",
        "Read it again": "Léelo otra vez",
        "Clear": "Borrar",
        "Yes": "Sí",
        "Let's play!": "¡A jugar!",
        "Start my adventure! 🎈": "¡Empieza mi aventura! 🎈",
        "Hold to run": "Mantén para correr",
        "Tap to jump · tap again to double jump": "Toca para saltar · toca otra vez para doble salto",
        "Time's up!": "¡Se acabó el tiempo!",
        "You made it!": "¡Lo lograste!",
        "New best score!": "¡Nuevo récord!",
        "Where?": "¿Dónde?",
        "Who?": "¿Quién?",
        "What happens?": "¿Qué pasa?",
        "What thing?": "¿Qué cosa?",
        "Start at the green dot": "Empieza en el punto verde",
        "Start at the green dot.": "Empieza en el punto verde.",
        "Stay close to the dotted line.": "Quédate cerca de la línea punteada.",
        "Keep going all the way to the end.": "Sigue hasta el final.",
        "Each game gives up to 3 stars. Beat your best for more.": "Cada juego da hasta 3 estrellas. Supera tu récord para ganar más.",
        "Your first three stories earn a star each. Up to six stories are kept.": "Tus tres primeros cuentos ganan una estrella cada uno. Se guardan hasta seis cuentos.",
        "Get a continent right to send a postcard home.": "Acierta un continente para mandar una postal a casa.",
        "Tip: the continents are the big pieces of land.": "Pista: los continentes son los pedazos grandes de tierra.",
        "Hoo! Which story game shall we play?": "¡Uuu! ¿A qué juego de lectura jugamos?",
        "Welcome to my shop! Let's count some coins.": "¡Bienvenido a mi tienda! Vamos a contar monedas.",
        "Scientists guess first, then test. Ready?": "Los científicos primero adivinan y luego prueban. ¿Listo?",
        "Grab a pencil! Let's write together.": "¡Toma un lápiz! Vamos a escribir juntos.",
        "Tick tock! From up here I can see every clock in the village.": "¡Tic tac! Desde aquí arriba veo todos los relojes del pueblo.",
        "Pack your bags! Let's visit all seven continents.": "¡Haz tu maleta! Vamos a visitar los siete continentes.",
        "Bzz! Let's spell some words.": "¡Bzz! Vamos a deletrear palabras.",
        "Fresh pies! Let's cut them into fair pieces.": "¡Pasteles recién hechos! Vamos a cortarlos en partes iguales.",
        "Circles, squares, cubes and cones. Let's look closely!": "Círculos, cuadrados, cubos y conos. ¡Miremos de cerca!",
        "Pick a place, a buddy and what happens. I'll read it to you!": "Elige un lugar, un amigo y lo que pasa. ¡Yo te lo leo!",
        "Hi, I'm Polly! Welcome to the Writing Desk. Pick something to write!": "¡Hola, soy Polly! Bienvenido al Escritorio de Escritura. ¡Elige algo para escribir!",
        "Hello up there! I'm Gemma. Welcome to the Clock Tower. Pick a clock game!": "¡Hola desde arriba! Soy Gemma. Bienvenido a la Torre del Reloj. ¡Elige un juego del reloj!",
        "Hi! I'm Pip. I came all the way from Antarctica! Let's go around the world!": "¡Hola! Soy Pip. ¡Vine desde la Antártida! ¡Vamos a darle la vuelta al mundo!",
        "Hoo hoo! Welcome to the Reading Nook. Pick a reading game!": "¡Uuu uuu! Bienvenido al Rincón de Lectura. ¡Elige un juego de lectura!",
        "Welcome to the Math Market! I'm Benny Banana. Let's count some money!": "¡Bienvenido al Mercado de Mate! Soy Benny Banana. ¡Vamos a contar dinero!",
        "Welcome to the Science Lab! I'm Professor Ocho. Scientists guess first, then test. Pick an experiment!": "¡Bienvenido al Laboratorio de Ciencias! Soy el Profesor Ocho. Los científicos primero adivinan y luego prueban. ¡Elige un experimento!",
        "Bzz bzz! I'm Buzzy. Welcome to the Spelling Bee!": "¡Bzz bzz! Soy Buzzy. ¡Bienvenido al Concurso de Deletreo!",
        "Hello, I'm Stella! Welcome to the Fraction Bakery. Everything here is cut into fair shares.": "¡Hola, soy Stella! Bienvenido a la Panadería de Fracciones. Aquí todo se corta en partes iguales.",
        "Hi, I'm Rocky! Welcome to Shape Studio.": "¡Hola, soy Rocky! Bienvenido al Estudio de Figuras.",
        "Pick a game!": "¡Elige un juego!",
        "Pick another game!": "¡Elige otro juego!",
        "Pick another reading game!": "¡Elige otro juego de lectura!",
        "Pick another writing game!": "¡Elige otro juego de escritura!",
        "Pick another clock game!": "¡Elige otro juego del reloj!",
        "Pick another experiment!": "¡Elige otro experimento!",
        "Where to next?": "¿A dónde vamos ahora?",
        "Welcome to Story Maker! Make your own three-page story, and I'll read it to you.": "¡Bienvenido al Creador de Cuentos! Haz tu propio cuento de tres páginas y yo te lo leo.",
        "Star Dash! Hold the left side to run left, hold the right side to run right. Tap the right side to jump, and tap again in the air to double jump!": "¡Carrera Estelar! Mantén el lado izquierdo para correr a la izquierda y el lado derecho para correr a la derecha. ¡Toca el lado derecho para saltar, y toca otra vez en el aire para un doble salto!",
        "Not quite. Try another one!": "Casi. ¡Prueba otra!",
        "Not quite. Try again!": "Casi. ¡Inténtalo otra vez!",
        "You did it! Great reading!": "¡Lo lograste! ¡Qué buena lectura!",
        "You did it! Great work!": "¡Lo lograste! ¡Buen trabajo!",
        "You did it! Lovely writing!": "¡Lo lograste! ¡Qué bonita letra!",
        "You did it! Great timing!": "¡Lo lograste! ¡Justo a tiempo!",
        "You did it! Great exploring!": "¡Lo lograste! ¡Gran exploración!",
        "Watch me first.": "Mírame primero.",
        "Nice!": "¡Bien!",
        "You got it!": "¡Lo tienes!",
        "That's right!": "¡Correcto!",
        "Super!": "¡Súper!",
        "Wonderful!": "¡Maravilloso!",
        "Great reading!": "¡Gran lectura!",
        "Beautiful writing!": "¡Qué bonita escritura!",
        "Neat!": "¡Qué ordenado!",
        "You wrote it!": "¡Lo escribiste!",
        "Super tracing!": "¡Súper trazo!",
        "Right on time!": "¡Justo a tiempo!",
        "Clock expert!": "¡Experto en relojes!",
        "Super timing!": "¡Súper puntual!",
        "Great exploring!": "¡Gran exploración!",
        "You found it!": "¡Lo encontraste!",
        "Super traveler!": "¡Súper viajero!",
        "Postcard time!": "¡Hora de la postal!",
        "Super speller!": "¡Súper deletreador!",
        "You spelled it!": "¡Lo deletreaste!",
        "Delicious!": "¡Delicioso!",
        "Yum, that's right!": "¡Mmm, correcto!",
        "Sweet!": "¡Dulce!",
        "Perfect slice!": "¡Rebanada perfecta!",
        "Shape star!": "¡Estrella de las figuras!",
        "Super spotting!": "¡Qué buen ojo!",
        "Smart shopping!": "¡Compra inteligente!",
        "Super math!": "¡Súper mate!",
        "Nice counting!": "¡Buen conteo!",
        "Great listening!": "¡Qué buen oído!",
        "Amazing ears!": "¡Qué oídos increíbles!",
        "Big Letters": "Letras Mayúsculas",
        "Small Letters": "Letras Minúsculas",
        "Numbers": "Números",
        "Write a Word": "Escribe una Palabra",
        "O'Clock": "En Punto",
        "Half Past": "Y Media",
        "Quarter Hours": "Cuartos de Hora",
        "Set the Clock": "Pon la Hora",
        "One Hour Later": "Una Hora Después",
        "Find It!": "¡Encuéntralo!",
        "Animal Homes": "Casas de Animales",
        "Famous Places": "Lugares Famosos",
        "Five Oceans": "Cinco Océanos",
        "Hear & Spell": "Escucha y Deletrea",
        "Missing Letter": "Letra Perdida",
        "Spot the Spelling": "Encuentra la Ortografía",
        "Magic E": "E Mágica",
        "Name the Slice": "Nombra la Rebanada",
        "Find the Fraction": "Encuentra la Fracción",
        "Share the Treats": "Comparte los Dulces",
        "Bigger Slice": "Rebanada Más Grande",
        "Name That Shape": "Nombra la Figura",
        "Count the Sides": "Cuenta los Lados",
        "3D Shapes": "Figuras 3D",
        "What Comes Next?": "¿Qué Sigue?",
        "First Sounds": "Primeros Sonidos",
        "Build a Word": "Arma una Palabra",
        "Word Pop": "Palabras Burbuja",
        "Rhyme Time": "Hora de Rimar",
        "Read & Match": "Lee y Une",
        "Count the Coins": "Cuenta las Monedas",
        "Pay Exactly": "Paga Exacto",
        "Make Change": "Da el Cambio",
        "Better Buy": "Mejor Compra",
        "Shopping List": "Lista de Compras",
        "Trace the big letter. Start at the green dot and follow the arrow.": "Traza la letra mayúscula. Empieza en el punto verde y sigue la flecha.",
        "Trace the small letter. Start at the green dot and follow the arrow.": "Traza la letra minúscula. Empieza en el punto verde y sigue la flecha.",
        "Trace the number. Start at the green dot and follow the arrow.": "Traza el número. Empieza en el punto verde y sigue la flecha.",
        "Write a whole word, one letter at a time!": "¡Escribe una palabra completa, letra por letra!",
        "The short hand shows the hour. When the long hand points to 12, it's o'clock!": "La manecilla corta marca la hora. ¡Cuando la larga apunta al 12, es en punto!",
        "When the long hand points to 6, it's half past. The short hand is halfway to the next number.": "Cuando la manecilla larga apunta al 6, es y media. La corta está a medio camino del siguiente número.",
        "Long hand on 3 is quarter past. On 9, it's quarter to the next hour.": "La manecilla larga en el 3 es y cuarto. En el 9, es menos cuarto de la siguiente hora.",
        "Move the hands to show the time. Drag the long hand for minutes and the short hand for hours.": "Mueve las manecillas para mostrar la hora. Arrastra la larga para los minutos y la corta para las horas.",
        "Look at the clock. What time will it be one hour later?": "Mira el reloj. ¿Qué hora será una hora después?",
        "There are seven continents. Tap the one Pip names on the map!": "Hay siete continentes. ¡Toca en el mapa el que diga Pip!",
        "Animals live all over the world. Where does this one live?": "Los animales viven en todo el mundo. ¿Dónde vive este?",
        "Let's visit famous places! Which continent is this one on?": "¡Visitemos lugares famosos! ¿En qué continente está este?",
        "Most of the Earth is covered by water. Let's learn the five oceans!": "Casi toda la Tierra está cubierta de agua. ¡Aprendamos los cinco océanos!",
        "Listen to the word, then spell it with the letter tiles.": "Escucha la palabra y deletréala con las fichas de letras.",
        "One letter is missing. Which one fits?": "Falta una letra. ¿Cuál va?",
        "Which one is spelled the right way?": "¿Cuál está bien escrita?",
        "Add a magic e and the vowel says its name! Pick the new word.": "¡Agrega una e mágica y la vocal dice su nombre! Elige la palabra nueva.",
        "How much of the pie is colored? Pick the fraction.": "¿Cuánto del pastel está coloreado? Elige la fracción.",
        "Find the picture that shows the fraction.": "Encuentra el dibujo que muestra la fracción.",
        "Share the treats fairly. How many does each friend get?": "Comparte los dulces por igual. ¿Cuántos le tocan a cada amigo?",
        "Which slice is bigger? Fewer pieces means bigger pieces!": "¿Qué rebanada es más grande? ¡Menos pedazos son pedazos más grandes!",
        "What is this shape called?": "¿Cómo se llama esta figura?",
        "Count the straight sides. Corners help!": "Cuenta los lados rectos. ¡Las esquinas ayudan!",
        "Some shapes are solid, like a ball or a box. Which shape is it?": "Algunas figuras son sólidas, como una pelota o una caja. ¿Qué figura es?",
        "Look at the pattern. What shape comes next?": "Mira el patrón. ¿Qué figura sigue?",
        "North America": "América del Norte",
        "South America": "América del Sur",
        "Europe": "Europa",
        "Africa": "África",
        "Asia": "Asia",
        "Australia": "Australia",
        "Antarctica": "Antártida",
        "Sink or Float?": "¿Se Hunde o Flota?",
        "Magnet Test": "Prueba del Imán",
        "Plant Parts": "Partes de la Planta",
        "Weather Watch": "Mira el Clima",
        "Solid, Liquid, Gas": "Sólido, Líquido, Gas",
        "Will it sink or float? Make your guess, then watch it splash!": "¿Se hundirá o flotará? ¡Adivina y mira cómo salpica!",
        "Does the magnet pull it? Guess, then test it with the magnet.": "¿El imán lo atrae? Adivina y pruébalo con el imán.",
        "Every part of a plant has a job. Which part does this one?": "Cada parte de la planta tiene un trabajo. ¿Qué parte hace esto?",
        "Look at the weather. What should you do or wear?": "Mira el clima. ¿Qué deberías hacer o ponerte?",
        "Is it a solid, a liquid, or a gas?": "¿Es un sólido, un líquido o un gas?",
        "Echo Me": "Repite Conmigo",
        "Drum Copy": "Copia el Tambor",
        "Learn a Song": "Aprende una Canción",
        "Listen to the notes, then play them back in the same order.": "Escucha las notas y tócalas en el mismo orden.",
        "Listen to the drums, then copy the beat.": "Escucha los tambores y copia el ritmo.",
        "Follow the glowing keys to play a whole song.": "Sigue las teclas que brillan para tocar una canción completa.",
        "Look at the picture and say the word. Which letter does it start with?": "Mira el dibujo y di la palabra. ¿Con qué letra empieza?",
        "Spell the word! Tap the letters in order.": "¡Deletrea la palabra! Toca las letras en orden.",
        "Listen to the word, then pop the bubble that says it.": "Escucha la palabra y revienta la burbuja que la dice.",
        "Which word rhymes? Rhyming words sound the same at the end, like cat and hat.": "¿Qué palabra rima? Las palabras que riman suenan igual al final, como cat y hat.",
        "Read the sentence, then pick the picture that matches it.": "Lee la oración y elige el dibujo que va con ella.",
        "Count the coins. How much money is it?": "Cuenta las monedas. ¿Cuánto dinero es?",
        "Tap coins to pay the exact price, then press Pay.": "Toca monedas para pagar el precio exacto y luego presiona Pagar.",
        "You pay with more money than it costs. How much change do you get back?": "Pagas con más dinero de lo que cuesta. ¿Cuánto cambio te devuelven?",
        "Look at the prices and pick the right one.": "Mira los precios y elige el correcto.",
        "Add up the shopping list. How much is it all together?": "Suma la lista de compras. ¿Cuánto es en total?",
        "Pick another game": "Elige otro juego",
        "Hold to run ": "Mantén para correr",
    ]
}
