import Foundation

struct WordItem: Identifiable, Codable, Hashable {
    let id: String
    let day: Int
    let word: String
    let meaning: String
    let examples: [String]
    var isKnown: Bool
    var needsPractice: Bool

    init(
        id: String = UUID().uuidString,
        day: Int,
        word: String,
        meaning: String,
        examples: [String],
        isKnown: Bool = false,
        needsPractice: Bool = false
    ) {
        self.id = id
        self.day = day
        self.word = word
        self.meaning = meaning
        self.examples = examples
        self.isKnown = isKnown
        self.needsPractice = needsPractice
    }

    enum CodingKeys: String, CodingKey {
        case id
        case day
        case word
        case meaning
        case examples
        case isKnown
        case needsPractice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(Int.self, forKey: .day)
        word = try container.decode(String.self, forKey: .word)
        meaning = try container.decode(String.self, forKey: .meaning)
        examples = try container.decodeIfPresent([String].self, forKey: .examples) ?? []
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? WordItem.makeID(day: day, word: word)
        isKnown = try container.decodeIfPresent(Bool.self, forKey: .isKnown) ?? false
        needsPractice = try container.decodeIfPresent(Bool.self, forKey: .needsPractice) ?? false
    }

    private static func makeID(day: Int, word: String) -> String {
        let cleanedWord = word
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
        return "day-\(day)-\(cleanedWord)"
    }

    var displayExamples: [String] {
        let savedExamples = examples
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !savedExamples.isEmpty {
            return savedExamples
        }

        return Self.generatedExamples(word: word, meaning: meaning)
    }

    private static func generatedExamples(word: String, meaning: String) -> [String] {
        let lowercasedWord = word.lowercased()
        let part = meaning.split(separator: " ").first.map(String.init) ?? ""
        let definition = meaning
            .replacingOccurrences(of: part, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()

        switch part {
        case "v.":
            return [
                "The speaker tried to \(lowercasedWord) the problem before the meeting ended.",
                "In context, to \(lowercasedWord) means to \(definition).",
                "The passage suggests that leaders sometimes \(lowercasedWord) when pressure increases."
            ]
        case "n.":
            return [
                "The passage describes \(article(for: lowercasedWord)) \(lowercasedWord) that shapes the main argument.",
                "In context, \(lowercasedWord) refers to \(definition).",
                "The professor used \(article(for: lowercasedWord)) \(lowercasedWord) as an example during the lecture."
            ]
        case "adj.":
            return [
                "The passage describes \(article(for: lowercasedWord)) \(lowercasedWord) decision that affects everyone involved.",
                "In context, \(lowercasedWord) means \(definition).",
                "The reviewer called the proposal \(lowercasedWord) after reading the evidence."
            ]
        case "adv.":
            return [
                "The witness answered \(lowercasedWord), which changed the tone of the hearing.",
                "In context, \(lowercasedWord) means in a way that is \(definition).",
                "The instructions were followed \(lowercasedWord) during the experiment."
            ]
        default:
            return [
                "A GRE passage may test whether you recognize \(lowercasedWord) in context.",
                "The clue in the sentence points to \(lowercasedWord) as the best word choice.",
                "\(word) is useful to remember when reading formal academic prose."
            ]
        }
    }

    private static func article(for word: String) -> String {
        guard let first = word.first else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }
}

struct WordProgress: Codable {
    var isKnown: Bool
    var needsPractice: Bool
}
