import Foundation

// MiniPython: a small, safe Python interpreter for the Coding Lab. It runs real Python syntax for the things
// beginner lessons teach (print, variables, whole-number math, strings, for/range loops, if/elif/else, def with
// parameters, global, return) and nothing else: no files, no network, no imports. Every run has a step limit,
// so a mistake can never freeze the app. Errors are short and kind, written for kids.

enum PyValue: Equatable, CustomStringConvertible {
    case int(Int)
    case str(String)
    case bool(Bool)
    case none

    var description: String {
        switch self {
        case .int(let v): return String(v)
        case .str(let s): return s
        case .bool(let b): return b ? "True" : "False"
        case .none: return "None"
        }
    }

    var truthy: Bool {
        switch self {
        case .int(let v): return v != 0
        case .str(let s): return !s.isEmpty
        case .bool(let b): return b
        case .none: return false
        }
    }

    var typeName: String {
        switch self {
        case .int: return "number"
        case .str: return "text"
        case .bool: return "True/False"
        case .none: return "None"
        }
    }
}

struct PyError: Error, Equatable, CustomStringConvertible {
    let line: Int
    let message: String
    var description: String { line > 0 ? "Line \(line): \(message)" : message }
}

final class MiniPython {
    // MARK: Syntax tree

    indirect enum Expr: Equatable {
        case int(Int)
        case str(String)
        case bool(Bool)
        case none
        case name(String)
        case binary(String, Expr, Expr)
        case unary(String, Expr)
        case call(String, [Expr])
    }

    struct IfBranch: Equatable {
        let condition: Expr?        // nil = else
        let body: [Stmt]
    }

    indirect enum Stmt: Equatable {
        case expr(Expr, Int)
        case assign(String, Expr, Int)
        case augAssign(String, String, Expr, Int)
        case forRange(String, [Expr], [Stmt], Int)
        case ifChain([IfBranch], Int)
        case def(String, [String], [Stmt], Int)
        case global([String], Int)
        case pass(Int)
        case ret(Expr?, Int)
    }

    // MARK: State

    private(set) var globals: [String: PyValue] = [:]
    private(set) var functions: [String: (params: [String], body: [Stmt])] = [:]
    private(set) var output: [String] = []
    /// Game and lesson commands (set_background, jump, add_star, say...). Checked before built-ins.
    var host: [String: ([PyValue]) throws -> PyValue] = [:]
    var stepLimit = 50_000
    private var steps = 0
    private var depth = 0

    static let maxOutputLines = 500
    static let maxRange = 1_000
    static let maxStringLength = 2_000

    init() {}

    // MARK: Running

    /// Parses and runs a whole program. Output collects in `output`.
    func run(_ source: String) throws {
        let program = try Self.parse(source)
        steps = 0
        try exec(program, locals: nil)
    }

    /// Calls a function the program defined (used for events like on_tap). Returns nil if it doesn't exist.
    @discardableResult
    func call(_ name: String, _ args: [PyValue] = []) throws -> PyValue? {
        guard functions[name] != nil else { return nil }
        steps = 0
        return try invoke(name, args, line: 0)
    }

    func hasFunction(_ name: String) -> Bool { functions[name] != nil }
    func value(of name: String) -> PyValue? { globals[name] }
    func clearOutput() { output = [] }

    // MARK: Parser

    private struct Line {
        let number: Int
        let indent: Int
        let text: String
    }

    static func parse(_ source: String) throws -> [Stmt] {
        var lines: [Line] = []
        for (i, raw) in source.components(separatedBy: "\n").enumerated() {
            let expanded = raw.replacingOccurrences(of: "\t", with: "    ")
            let stripped = stripComment(expanded)
            let text = stripped.trimmingCharacters(in: .whitespaces)
            if text.isEmpty { continue }
            let indent = expanded.prefix { $0 == " " }.count
            lines.append(Line(number: i + 1, indent: indent, text: text))
        }
        var index = 0
        let block = try parseBlock(lines, &index, indent: lines.first?.indent ?? 0)
        if index < lines.count {
            throw PyError(line: lines[index].number, message: "This line is indented in a way Python doesn't expect.")
        }
        return block
    }

    private static func stripComment(_ s: String) -> String {
        var inString: Character?
        var out = ""
        for ch in s {
            if let q = inString {
                if ch == q { inString = nil }
            } else if ch == "\"" || ch == "'" {
                inString = ch
            } else if ch == "#" {
                break
            }
            out.append(ch)
        }
        return out
    }

    private static func parseBlock(_ lines: [Line], _ i: inout Int, indent: Int) throws -> [Stmt] {
        var out: [Stmt] = []
        while i < lines.count {
            let line = lines[i]
            if line.indent < indent { break }
            if line.indent > indent {
                throw PyError(line: line.number, message: "This line has too many spaces in front. Only lines inside a loop, if or def are pushed in.")
            }
            let toks = try tokenize(line.text, line: line.number)
            i += 1
            out.append(try parseStatement(toks, line, lines, &i))
        }
        return out
    }

    private static func body(after header: Line, _ lines: [Line], _ i: inout Int) throws -> [Stmt] {
        guard i < lines.count, lines[i].indent > header.indent else {
            throw PyError(line: header.number, message: "After a line ending in ':' the next lines need to be pushed in (indented).")
        }
        return try parseBlock(lines, &i, indent: lines[i].indent)
    }

    private static func parseStatement(_ t: [Tok], _ line: Line, _ lines: [Line], _ i: inout Int) throws -> Stmt {
        let n = line.number
        guard let first = t.first else { return .pass(n) }

        if case .name(let kw) = first {
            switch kw {
            case "pass":
                return .pass(n)
            case "import", "from":
                throw PyError(line: n, message: "No import needed here: everything you need is already built in!")
            case "while":
                throw PyError(line: n, message: "In the Coding Lab we loop with for, like: for i in range(3):")
            case "global":
                let names = t.dropFirst().compactMap { tok -> String? in if case .name(let s) = tok { return s }; return nil }
                guard !names.isEmpty else { throw PyError(line: n, message: "global needs a variable name, like: global score") }
                return .global(names, n)
            case "return":
                if t.count == 1 { return .ret(nil, n) }
                var p = Parser(Array(t.dropFirst()), line: n)
                let e = try p.expression()
                try p.end()
                return .ret(e, n)
            case "for":
                // for NAME in range(...):
                guard t.count >= 6, case .name(let v) = t[1], t[2] == .name("in"), t[3] == .name("range"), t.last == .colon else {
                    throw PyError(line: n, message: "A loop looks like: for i in range(3):")
                }
                var p = Parser(Array(t[4..<(t.count - 1)]), line: n)
                let args = try p.callArgs()
                try p.end()
                guard (1...3).contains(args.count) else { throw PyError(line: n, message: "range() needs 1 to 3 numbers.") }
                return .forRange(v, args, try body(after: line, lines, &i), n)
            case "if":
                var branches: [IfBranch] = []
                branches.append(IfBranch(condition: try condition(t, n), body: try body(after: line, lines, &i)))
                while i < lines.count, lines[i].indent == line.indent {
                    let next = try tokenize(lines[i].text, line: lines[i].number)
                    if next.first == .name("elif") {
                        let header = lines[i]
                        i += 1
                        branches.append(IfBranch(condition: try condition(next, header.number), body: try body(after: header, lines, &i)))
                    } else if next.first == .name("else") {
                        let header = lines[i]
                        guard next.count == 2, next.last == .colon else { throw PyError(line: header.number, message: "else needs a colon: else:") }
                        i += 1
                        branches.append(IfBranch(condition: nil, body: try body(after: header, lines, &i)))
                        break
                    } else {
                        break
                    }
                }
                return .ifChain(branches, n)
            case "elif", "else":
                throw PyError(line: n, message: "\(kw) has to come right after an if.")
            case "def":
                guard t.count >= 5, case .name(let fname) = t[1], t[2] == .lparen, t.last == .colon, t[t.count - 2] == .rparen else {
                    throw PyError(line: n, message: "A function looks like: def jump():")
                }
                var params: [String] = []
                for tok in t[3..<(t.count - 2)] {
                    switch tok {
                    case .name(let s): params.append(s)
                    case .comma: continue
                    default: throw PyError(line: n, message: "Function inputs must be names, like def move(steps):")
                    }
                }
                return .def(fname, params, try body(after: line, lines, &i), n)
            default:
                break
            }
            // assignment?
            if t.count >= 3, case .op(let op) = t[1], ["=", "+=", "-=", "*="].contains(op) {
                var p = Parser(Array(t.dropFirst(2)), line: n)
                let e = try p.expression()
                try p.end()
                if Self.reserved.contains(kw) { throw PyError(line: n, message: "'\(kw)' is a special Python word, so it can't be a variable name.") }
                return op == "=" ? .assign(kw, e, n) : .augAssign(kw, String(op.dropLast()), e, n)
            }
        }
        if t.last == .colon {
            throw PyError(line: n, message: "Lines ending in ':' must start with if, elif, else, for or def.")
        }
        var p = Parser(t, line: n)
        let e = try p.expression()
        try p.end()
        return .expr(e, n)
    }

    private static func condition(_ t: [Tok], _ n: Int) throws -> Expr {
        guard t.count >= 3, t.last == .colon else { throw PyError(line: n, message: "if needs a question and a colon, like: if score > 5:") }
        var p = Parser(Array(t[1..<(t.count - 1)]), line: n)
        let e = try p.expression()
        try p.end()
        return e
    }

    static let reserved: Set<String> = ["if", "elif", "else", "for", "in", "def", "return", "global", "pass", "and", "or", "not",
                                        "True", "False", "None", "while", "import", "class"]

    // MARK: Tokens

    enum Tok: Equatable {
        case name(String)
        case int(Int)
        case str(String)
        case op(String)
        case lparen, rparen, comma, colon
    }

    static func tokenize(_ s: String, line: Int) throws -> [Tok] {
        var out: [Tok] = []
        let chars = Array(s)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == " " { i += 1; continue }
            if c.isLetter || c == "_" {
                var j = i
                while j < chars.count, chars[j].isLetter || chars[j].isNumber || chars[j] == "_" { j += 1 }
                out.append(.name(String(chars[i..<j])))
                i = j
                continue
            }
            if c.isNumber {
                var j = i
                while j < chars.count, chars[j].isNumber { j += 1 }
                if j < chars.count, chars[j] == "." {
                    throw PyError(line: line, message: "HopQuest Python uses whole numbers only (like 3, not 3.5).")
                }
                guard let v = Int(String(chars[i..<j])), v < 1_000_000_000 else {
                    throw PyError(line: line, message: "That number is too big!")
                }
                out.append(.int(v))
                i = j
                continue
            }
            if c == "\"" || c == "'" {
                var j = i + 1
                var text = ""
                while j < chars.count, chars[j] != c {
                    if chars[j] == "\\", j + 1 < chars.count {
                        let e = chars[j + 1]
                        text.append(e == "n" ? "\n" : e)
                        j += 2
                        continue
                    }
                    text.append(chars[j])
                    j += 1
                }
                guard j < chars.count else { throw PyError(line: line, message: "A string needs a closing \(c) mark.") }
                out.append(.str(text))
                i = j + 1
                continue
            }
            switch c {
            case "(": out.append(.lparen); i += 1; continue
            case ")": out.append(.rparen); i += 1; continue
            case ",": out.append(.comma); i += 1; continue
            case ":": out.append(.colon); i += 1; continue
            default: break
            }
            let two = i + 1 < chars.count ? String(chars[i...(i + 1)]) : ""
            if ["==", "!=", "<=", ">=", "+=", "-=", "*=", "//"].contains(two) {
                out.append(.op(two))
                i += 2
                continue
            }
            if "+-*/%<>=".contains(c) {
                out.append(.op(String(c)))
                i += 1
                continue
            }
            throw PyError(line: line, message: "Python doesn't know the symbol '\(c)'.")
        }
        return out
    }

    // MARK: Expression parser (precedence climbing)

    struct Parser {
        let toks: [Tok]
        let line: Int
        var i = 0

        init(_ toks: [Tok], line: Int) {
            self.toks = toks
            self.line = line
        }

        var peek: Tok? { i < toks.count ? toks[i] : nil }

        mutating func end() throws {
            if i < toks.count { throw PyError(line: line, message: "Something extra is at the end of this line.") }
        }

        mutating func expression() throws -> Expr { try orExpr() }

        mutating func orExpr() throws -> Expr {
            var left = try andExpr()
            while peek == .name("or") { i += 1; left = .binary("or", left, try andExpr()) }
            return left
        }

        mutating func andExpr() throws -> Expr {
            var left = try notExpr()
            while peek == .name("and") { i += 1; left = .binary("and", left, try notExpr()) }
            return left
        }

        mutating func notExpr() throws -> Expr {
            if peek == .name("not") { i += 1; return .unary("not", try notExpr()) }
            return try comparison()
        }

        mutating func comparison() throws -> Expr {
            var left = try additive()
            while case .op(let o)? = peek, ["==", "!=", "<", ">", "<=", ">="].contains(o) {
                i += 1
                left = .binary(o, left, try additive())
            }
            if case .op("=")? = peek {
                throw PyError(line: line, message: "To check if two things are equal, use == (two equal signs).")
            }
            return left
        }

        mutating func additive() throws -> Expr {
            var left = try multiplicative()
            while case .op(let o)? = peek, o == "+" || o == "-" {
                i += 1
                left = .binary(o, left, try multiplicative())
            }
            return left
        }

        mutating func multiplicative() throws -> Expr {
            var left = try unary()
            while case .op(let o)? = peek, ["*", "/", "//", "%"].contains(o) {
                i += 1
                left = .binary(o, left, try unary())
            }
            return left
        }

        mutating func unary() throws -> Expr {
            if case .op("-")? = peek { i += 1; return .unary("-", try unary()) }
            return try primary()
        }

        mutating func primary() throws -> Expr {
            guard let t = peek else { throw PyError(line: line, message: "This line stops too early. Is something missing?") }
            i += 1
            switch t {
            case .int(let v): return .int(v)
            case .str(let s): return .str(s)
            case .lparen:
                let e = try expression()
                guard peek == .rparen else { throw PyError(line: line, message: "A '(' needs a matching ')'.") }
                i += 1
                return e
            case .name(let n):
                switch n {
                case "True": return .bool(true)
                case "False": return .bool(false)
                case "None": return .none
                default: break
                }
                if peek == .lparen {
                    i += 1
                    return .call(n, try callArgsAfterParen())
                }
                return .name(n)
            default:
                throw PyError(line: line, message: "Python didn't expect that here.")
            }
        }

        /// For `range(...)`: expects "( args )".
        mutating func callArgs() throws -> [Expr] {
            guard peek == .lparen else { throw PyError(line: line, message: "range needs parentheses, like range(3).") }
            i += 1
            return try callArgsAfterParen()
        }

        mutating func callArgsAfterParen() throws -> [Expr] {
            var args: [Expr] = []
            if peek == .rparen { i += 1; return args }
            while true {
                args.append(try expression())
                if peek == .comma { i += 1; continue }
                if peek == .rparen { i += 1; return args }
                throw PyError(line: line, message: "A function call needs a closing ')'.")
            }
        }
    }

    // MARK: Interpreter

    private struct ReturnSignal: Error { let value: PyValue }

    private final class Frame {
        var vars: [String: PyValue] = [:]
        var globalNames: Set<String> = []
    }

    private func tick(_ line: Int) throws {
        steps += 1
        if steps > stepLimit {
            throw PyError(line: line, message: "Your program ran for too long! Check that your loops can finish.")
        }
    }

    private func exec(_ stmts: [Stmt], locals: Frame?) throws {
        for s in stmts { try exec(s, locals) }
    }

    private func exec(_ s: Stmt, _ f: Frame?) throws {
        switch s {
        case .pass(let n):
            try tick(n)
        case .expr(let e, let n):
            try tick(n)
            _ = try eval(e, f, n)
        case .assign(let name, let e, let n):
            try tick(n)
            set(name, try eval(e, f, n), f)
        case .augAssign(let name, let op, let e, let n):
            try tick(n)
            guard let current = lookup(name, f) else {
                throw PyError(line: n, message: "'\(name)' needs a starting value before you can change it (like \(name) = 0).")
            }
            set(name, try binary(op, current, try eval(e, f, n), n), f)
        case .forRange(let v, let args, let body, let n):
            try tick(n)
            let nums = try args.map { a -> Int in
                guard case .int(let x) = try eval(a, f, n) else { throw PyError(line: n, message: "range() needs whole numbers.") }
                return x
            }
            let (start, stop, step): (Int, Int, Int)
            switch nums.count {
            case 1: (start, stop, step) = (0, nums[0], 1)
            case 2: (start, stop, step) = (nums[0], nums[1], 1)
            default: (start, stop, step) = (nums[0], nums[1], nums[2])
            }
            guard step != 0 else { throw PyError(line: n, message: "range() can't count by 0.") }
            let count = step > 0 ? max(0, (stop - start + step - 1) / step) : max(0, (start - stop - step - 1) / -step)
            guard count <= Self.maxRange else { throw PyError(line: n, message: "That loop is huge! Try a number under \(Self.maxRange).") }
            var x = start
            for _ in 0..<count {
                set(v, .int(x), f)
                try exec(body, locals: f)
                x += step
            }
        case .ifChain(let branches, let n):
            try tick(n)
            for b in branches {
                if let c = b.condition {
                    if try eval(c, f, n).truthy {
                        try exec(b.body, locals: f)
                        return
                    }
                } else {
                    try exec(b.body, locals: f)
                    return
                }
            }
        case .def(let name, let params, let body, let n):
            try tick(n)
            functions[name] = (params, body)
        case .global(let names, let n):
            try tick(n)
            if let f { f.globalNames.formUnion(names) }
        case .ret(let e, let n):
            try tick(n)
            guard f != nil else { throw PyError(line: n, message: "return only works inside a def function.") }
            throw ReturnSignal(value: try e.map { try eval($0, f, n) } ?? .none)
        }
    }

    private func lookup(_ name: String, _ f: Frame?) -> PyValue? {
        if let f, !f.globalNames.contains(name), let v = f.vars[name] { return v }
        return globals[name]
    }

    private func set(_ name: String, _ v: PyValue, _ f: Frame?) {
        if let f, !f.globalNames.contains(name) { f.vars[name] = v } else { globals[name] = v }
    }

    private func eval(_ e: Expr, _ f: Frame?, _ n: Int) throws -> PyValue {
        switch e {
        case .int(let v): return .int(v)
        case .str(let s): return .str(s)
        case .bool(let b): return .bool(b)
        case .none: return .none
        case .name(let name):
            if let v = lookup(name, f) { return v }
            if functions[name] != nil || host[name] != nil {
                throw PyError(line: n, message: "\(name) is a function. Add () to use it: \(name)()")
            }
            throw PyError(line: n, message: "Python doesn't know '\(name)' yet. Did you give it a value first?")
        case .unary(let op, let x):
            let v = try eval(x, f, n)
            if op == "not" { return .bool(!v.truthy) }
            guard case .int(let i) = v else { throw PyError(line: n, message: "Only numbers can be negative.") }
            return .int(-i)
        case .binary(let op, let a, let b):
            if op == "and" {
                let l = try eval(a, f, n)
                return l.truthy ? try eval(b, f, n) : l
            }
            if op == "or" {
                let l = try eval(a, f, n)
                return l.truthy ? l : try eval(b, f, n)
            }
            return try binary(op, try eval(a, f, n), try eval(b, f, n), n)
        case .call(let name, let argExprs):
            let args = try argExprs.map { try eval($0, f, n) }
            return try invoke(name, args, line: n)
        }
    }

    private func invoke(_ name: String, _ args: [PyValue], line n: Int) throws -> PyValue {
        try tick(n)
        if let fn = functions[name] {
            guard args.count == fn.params.count else {
                throw PyError(line: n, message: "\(name)() needs \(fn.params.count) input\(fn.params.count == 1 ? "" : "s") but got \(args.count).")
            }
            depth += 1
            defer { depth -= 1 }
            guard depth < 40 else { throw PyError(line: n, message: "Too many functions calling each other!") }
            let frame = Frame()
            for (p, v) in zip(fn.params, args) { frame.vars[p] = v }
            do {
                try exec(fn.body, locals: frame)
            } catch let r as ReturnSignal {
                return r.value
            }
            return .none
        }
        if let h = host[name] {
            do { return try h(args) } catch let e as PyError { throw PyError(line: n, message: e.message) }
        }
        return try builtin(name, args, n)
    }

    private func builtin(_ name: String, _ args: [PyValue], _ n: Int) throws -> PyValue {
        switch name {
        case "print":
            guard output.count < Self.maxOutputLines else { throw PyError(line: n, message: "That's a LOT of printing! Try a smaller loop.") }
            output.append(args.map(\.description).joined(separator: " "))
            return .none
        case "str":
            guard args.count == 1 else { throw PyError(line: n, message: "str() needs one thing inside.") }
            return .str(args[0].description)
        case "int":
            guard args.count == 1 else { throw PyError(line: n, message: "int() needs one thing inside.") }
            switch args[0] {
            case .int: return args[0]
            case .bool(let b): return .int(b ? 1 : 0)
            case .str(let s):
                guard let v = Int(s.trimmingCharacters(in: .whitespaces)) else { throw PyError(line: n, message: "\"\(s)\" isn't a whole number.") }
                return .int(v)
            case .none: throw PyError(line: n, message: "None isn't a number.")
            }
        case "len":
            guard args.count == 1, case .str(let s) = args[0] else { throw PyError(line: n, message: "len() counts the letters in some text.") }
            return .int(s.count)
        case "abs":
            guard args.count == 1, case .int(let v) = args[0] else { throw PyError(line: n, message: "abs() needs a number.") }
            return .int(abs(v))
        case "max", "min":
            let nums = try args.map { v -> Int in
                guard case .int(let i) = v else { throw PyError(line: n, message: "\(name)() compares numbers.") }
                return i
            }
            guard let r = name == "max" ? nums.max() : nums.min() else { throw PyError(line: n, message: "\(name)() needs some numbers.") }
            return .int(r)
        case "range":
            throw PyError(line: n, message: "Use range() in a for loop, like: for i in range(3):")
        default:
            throw PyError(line: n, message: "Python doesn't know a function called \(name)(). Check the spelling!")
        }
    }

    private func binary(_ op: String, _ a: PyValue, _ b: PyValue, _ n: Int) throws -> PyValue {
        switch (op, a, b) {
        case ("+", .int(let x), .int(let y)): return .int(x &+ y)
        case ("-", .int(let x), .int(let y)): return .int(x &- y)
        case ("*", .int(let x), .int(let y)): return .int(x &* y)
        case ("//", .int(let x), .int(let y)):
            guard y != 0 else { throw PyError(line: n, message: "You can't divide by zero!") }
            return .int(Int((Double(x) / Double(y)).rounded(.down)))
        case ("/", .int(let x), .int(let y)):
            guard y != 0 else { throw PyError(line: n, message: "You can't divide by zero!") }
            guard x % y == 0 else { throw PyError(line: n, message: "\(x) / \(y) isn't a whole number. Try // to divide and round down.") }
            return .int(x / y)
        case ("%", .int(let x), .int(let y)):
            guard y != 0 else { throw PyError(line: n, message: "You can't divide by zero!") }
            return .int(((x % y) + y) % y)
        case ("+", .str(let x), .str(let y)):
            guard x.count + y.count <= Self.maxStringLength else { throw PyError(line: n, message: "That text got too long!") }
            return .str(x + y)
        case ("*", .str(let x), .int(let k)), ("*", .int(let k), .str(let x)):
            guard k >= 0, x.count * k <= Self.maxStringLength else { throw PyError(line: n, message: "That text got too long!") }
            return .str(String(repeating: x, count: k))
        case ("+", .str, .int), ("+", .int, .str):
            throw PyError(line: n, message: "You can't add text and a number. Turn the number into text with str(), like str(5).")
        case ("==", _, _): return .bool(a == b)
        case ("!=", _, _): return .bool(a != b)
        case ("<", .int(let x), .int(let y)): return .bool(x < y)
        case (">", .int(let x), .int(let y)): return .bool(x > y)
        case ("<=", .int(let x), .int(let y)): return .bool(x <= y)
        case (">=", .int(let x), .int(let y)): return .bool(x >= y)
        case ("<", .str(let x), .str(let y)): return .bool(x < y)
        case (">", .str(let x), .str(let y)): return .bool(x > y)
        default:
            throw PyError(line: n, message: "Python can't use \(op) with \(a.typeName) and \(b.typeName).")
        }
    }
}
