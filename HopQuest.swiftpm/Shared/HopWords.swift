import Foundation

// The widgets' words in Spanish (v8.1). The app tells the widget which language to use in its snapshot;
// the widget can't see the app's own translation table, so the words it shows live here.

enum HopWords {
    static func tr(_ s: String, _ spanish: Bool) -> String {
        guard spanish, !s.isEmpty else { return s }
        if let hit = table[s] { return hit }
        if s.hasPrefix("New game! ") { return "¡Juego nuevo! " + tr(String(s.dropFirst(10)), true) }
        let range = NSRange(s.startIndex..., in: s)
        for (re, template) in patterns {
            if let m = re.firstMatch(in: s, range: range) {
                var out = template
                for g in stride(from: m.numberOfRanges - 1, through: 1, by: -1) {
                    if let r = Range(m.range(at: g), in: s) {
                        // level titles inside a pattern ("Next: Breezy Beach") get translated too
                        let piece = String(s[r])
                        out = out.replacingOccurrences(of: "$\(g)", with: table[piece] ?? piece)
                    }
                }
                return out
            }
        }
        return s
    }

    static let table: [String: String] = [
        "Practising": "Practicando", "Up next": "Lo siguiente", "Got it": "¡Aprendido!", "Star Hop": "Salto Estelar",
        "Step": "Paso", "Jump": "Saltar", "Double jump": "Doble salto", "Next level": "Siguiente nivel", "Try again": "Intenta otra vez",
        "Play again": "Jugar otra vez", "Out of hearts!": "¡Sin corazones!", "The puff clouds got you. You can do it!": "Las nubes te atraparon. ¡Tú puedes!",
        "✓ Finished": "✓ Terminado", "✓ No bumps": "✓ Sin choques", "· No bumps": "· Sin choques", "✓ Quick feet": "✓ Pies rápidos",
        "· Quick feet": "· Pies rápidos", "Next": "Sigue", "Hop Village": "Pueblo Salto",
        "Jump!": "¡Salta!", "Double jump!": "¡Doble salto!", "Glide!": "¡Planea!", "Step!": "¡Paso!", "Whee!": "¡Yupi!",
        "Got it! ⭐": "¡Atrapada! ⭐", "Golden star! +2": "¡Estrella dorada! +2", "Boing!": "¡Boing!", "Bubble shield! 🫧": "¡Escudo de burbuja! 🫧",
        "Pop! Your bubble saved you.": "¡Pop! Tu burbuja te salvó.", "Bonk! A puff cloud. 💨": "¡Bonk! Una nube. 💨",
        "You finished every level!": "¡Terminaste todos los niveles!", "Tap to play!": "¡Toca para jugar!",
        "Brain Bubble": "Burbuja Cerebral", "You caught every star!": "¡Atrapaste todas las estrellas!", "Catch every star!": "¡Atrapa todas las estrellas!", "Next question": "Otra pregunta", "Yes!": "¡Sí!", "Not quite.": "Casi.",
        // levels
        "Sunny Meadow": "Prado Soleado", "Breezy Beach": "Playa Ventosa", "Counting Hill": "Colina de Contar", "Snowy Peaks": "Picos Nevados",
        "Spelling Sky": "Cielo de Letras", "Starry Night": "Noche Estrellada", "ABC Garden": "Jardín ABC", "Rocket Launch": "Despegue",
        "Adding Bay": "Bahía de Sumas", "Tens Tower": "Torre de Decenas", "Take-Away Tundra": "Tundra de Restas", "Rainbow Castle": "Castillo Arcoíris",
        "Catch 8 stars!": "¡Atrapa 8 estrellas!", "Hop over the puff cloud!": "¡Salta sobre la nube!",
        "Catch the stars in order: 1, 2, 3…": "Atrapa las estrellas en orden: 1, 2, 3…",
        "Two clouds! Grab a bubble to stay safe.": "¡Dos nubes! Toma una burbuja para protegerte.",
        "Catch the letters to spell the word!": "¡Atrapa las letras para formar la palabra!", "Count by twos: 2, 4, 6…": "Cuenta de dos en dos: 2, 4, 6…",
        "Catch the letters in ABC order!": "¡Atrapa las letras en orden ABC!", "Count down to blast off: 6, 5, 4…": "Cuenta hacia atrás para despegar: 6, 5, 4…",
        "Catch the answer to each sum!": "¡Atrapa la respuesta de cada suma!", "Count by tens: 10, 20, 30…": "Cuenta de diez en diez: 10, 20, 30…",
        "Catch the answer to each take-away!": "¡Atrapa la respuesta de cada resta!", "The last level! Catch 12 stars.": "¡El último nivel! Atrapa 12 estrellas.",
    ]

    static let patterns: [(NSRegularExpression, String)] = [
        ("^Hi, (.+)!$", "¡Hola, $1!"),
        ("^Level (\\d+) done!$", "¡Nivel $1 terminado!"),
        ("^You beat all (\\d+) levels! 🏆$", "¡Superaste los $1 niveles! 🏆"),
        ("^(\\d+) of (\\d+) stars$", "$1 de $2 estrellas"),
        ("^Next: (.+)$", "Siguiente: $1"),
        ("^Best on this level: (\\d+) moves$", "Récord en este nivel: $1 movimientos"),
        ("^(.+) = (.+)! ✓$", "¡$1 = $2! ✓"),
        ("^Not (.+)\\. (.+) = \\?$", "No es $1. $2 = ?"),
        ("^That's (.+)\\. Find (.+) first!$", "Ese es $1. ¡Primero busca $2!"),
        ("^(.+)! Now find (.+)\\.$", "¡$1! Ahora busca $2."),
        ("^It's (.+)\\.$", "Es $1."),
        ("^(\\d+) right$", "$1 correctas"),
    ].compactMap { p in (try? NSRegularExpression(pattern: p.0)).map { ($0, p.1) } }
}
