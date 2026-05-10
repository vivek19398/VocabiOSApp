import Combine
import Foundation

enum AssistantRole: String {
    case user
    case assistant
}

struct EnglishAssistantMessage: Identifiable, Hashable {
    let id = UUID()
    let role: AssistantRole
    let text: String
}

@MainActor
final class EnglishAssistantService: ObservableObject {
    @Published var messages: [EnglishAssistantMessage] = [
        EnglishAssistantMessage(
            role: .assistant,
            text: "Ask me about word meanings, grammar, example sentences, synonyms, antonyms, or sentence correction. I only answer English-learning questions."
        )
    ]
    @Published var draft = ""
    @Published var isThinking = false

    private let llm = LocalLLMService()

    func send(vocabulary: [WordItem]) async {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }

        draft = ""
        messages.append(EnglishAssistantMessage(role: .user, text: question))

        guard EnglishTopicGuard.isAllowed(question, vocabulary: vocabulary) else {
            messages.append(
                EnglishAssistantMessage(
                    role: .assistant,
                    text: "I can help only with English learning: vocabulary, meanings, grammar, examples, synonyms, antonyms, and sentence correction."
                )
            )
            return
        }

        isThinking = true
        defer { isThinking = false }

        let prompt = Self.makePrompt(question: question, vocabulary: vocabulary)

        do {
            let answer = try await llm.answer(prompt: prompt)
            messages.append(EnglishAssistantMessage(role: .assistant, text: answer))
        } catch {
            let offlineAnswer = OfflineEnglishHelper.answer(question: question, vocabulary: vocabulary)
            let setupNote = LocalLLMService.setupMessage(for: error)
            messages.append(EnglishAssistantMessage(role: .assistant, text: "\(offlineAnswer)\n\n\(setupNote)"))
        }
    }

    func useSuggestion(_ suggestion: String) {
        draft = suggestion
    }

    private static func makePrompt(question: String, vocabulary: [WordItem]) -> String {
        let matches = OfflineEnglishHelper.matchingWords(in: question, vocabulary: vocabulary)
            .prefix(4)
            .map { "- \($0.word): \($0.meaning)" }
            .joined(separator: "\n")

        let context = matches.isEmpty ? "No exact local vocabulary match." : matches

        return """
        You are VocabiOS English Tutor, an offline English-learning assistant inside a vocabulary flashcard app.

        Rules:
        - Answer only English-learning questions: vocabulary, word meaning, grammar, examples, synonyms, antonyms, sentence correction, and usage.
        - If the user asks anything outside English learning, politely refuse in one sentence.
        - Keep answers concise and beginner-friendly.
        - For word meanings, include the meaning, simple explanation, and 2 short example sentences.
        - For grammar, explain the rule and give a corrected example if useful.

        Local vocabulary context:
        \(context)

        User question:
        \(question)
        """
    }
}

enum EnglishTopicGuard {
    static func isAllowed(_ question: String, vocabulary: [WordItem]) -> Bool {
        let lowercased = question.lowercased()

        let allowedTerms = [
            "meaning", "mean", "means", "definition", "define", "word", "vocab",
            "vocabulary", "grammar", "sentence", "correct", "correction", "synonym",
            "antonym", "example", "examples", "usage", "use", "noun", "verb",
            "adjective", "adverb", "tense", "preposition", "article", "pronoun",
            "punctuation", "english", "phrase", "idiom", "spelling", "write",
            "rewrite", "explain"
        ]

        if allowedTerms.contains(where: { lowercased.contains($0) }) {
            return true
        }

        if OfflineEnglishHelper.matchingWords(in: question, vocabulary: vocabulary).isEmpty == false {
            return true
        }

        let words = lowercased
            .split { !$0.isLetter }
            .map(String.init)

        return words.count <= 2 && words.allSatisfy { $0.count > 1 }
    }
}

enum OfflineEnglishHelper {
    static func answer(question: String, vocabulary: [WordItem]) -> String {
        if let word = matchingWords(in: question, vocabulary: vocabulary).first {
            let examples = word.displayExamples.prefix(2).map { "- \($0)" }.joined(separator: "\n")
            return """
            \(word.word)

            Meaning: \(word.meaning)

            Examples:
            \(examples)
            """
        }

        let lowercased = question.lowercased()

        if lowercased.contains("noun") {
            return "A noun names a person, place, thing, or idea. Example: In “The student reads,” “student” is a noun."
        }

        if lowercased.contains("verb") {
            return "A verb shows an action or state. Example: In “She studies daily,” “studies” is the verb."
        }

        if lowercased.contains("adjective") {
            return "An adjective describes a noun. Example: In “a difficult question,” “difficult” describes “question.”"
        }

        if lowercased.contains("adverb") {
            return "An adverb describes a verb, adjective, or another adverb. Example: In “He answered quickly,” “quickly” describes how he answered."
        }

        if lowercased.contains("tense") {
            return "Tense shows when an action happens. Example: “I study” is present, “I studied” is past, and “I will study” is future."
        }

        return "The local LLM is not installed yet, so I can only answer from bundled vocabulary and basic grammar rules right now."
    }

    static func matchingWords(in question: String, vocabulary: [WordItem]) -> [WordItem] {
        let tokens = Set(
            question
                .lowercased()
                .split { !$0.isLetter && !$0.isNumber && $0 != "-" }
                .map(String.init)
        )

        guard !tokens.isEmpty else { return [] }

        return vocabulary.filter { item in
            tokens.contains(item.word.lowercased())
        }
    }
}
