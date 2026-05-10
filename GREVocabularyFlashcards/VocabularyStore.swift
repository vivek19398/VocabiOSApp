import Combine
import Foundation

final class VocabularyStore: ObservableObject {
    @Published private(set) var words: [WordItem] = []

    private let progressKey = "gre-vocabulary-progress-v1"

    init() {
        loadVocabulary()
    }

    var days: [Int] {
        Array(Set(words.map(\.day))).sorted()
    }

    var reviewWords: [WordItem] {
        words
            .filter { $0.needsPractice }
            .sorted { first, second in
                if first.day == second.day {
                    return first.word.localizedCaseInsensitiveCompare(second.word) == .orderedAscending
                }
                return first.day < second.day
            }
    }

    func words(for day: Int) -> [WordItem] {
        words.filter { $0.day == day }
    }

    func wordCount(for day: Int) -> Int {
        words(for: day).count
    }

    func completedCount(for day: Int) -> Int {
        words(for: day).filter { $0.isKnown || $0.needsPractice }.count
    }

    func progressText(for day: Int) -> String {
        "\(completedCount(for: day)) / \(wordCount(for: day))"
    }

    func progressValue(for day: Int) -> Double {
        let total = wordCount(for: day)
        guard total > 0 else { return 0 }
        return Double(completedCount(for: day)) / Double(total)
    }

    func markKnown(_ item: WordItem) {
        update(item) { word in
            word.isKnown = true
            word.needsPractice = false
        }
    }

    func markNeedsPractice(_ item: WordItem) {
        update(item) { word in
            word.isKnown = false
            word.needsPractice = true
        }
    }

    func removeFromReview(_ item: WordItem) {
        update(item) { word in
            word.isKnown = true
            word.needsPractice = false
        }
    }

    func resetProgress() {
        words = words.map { item in
            var copy = item
            copy.isKnown = false
            copy.needsPractice = false
            return copy
        }
        UserDefaults.standard.removeObject(forKey: progressKey)
    }

    private func update(_ item: WordItem, change: (inout WordItem) -> Void) {
        guard let index = words.firstIndex(where: { $0.id == item.id }) else { return }
        change(&words[index])
        saveProgress()
    }

    private func loadVocabulary() {
        let decodedWords: [WordItem]

        if let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let loaded = try? JSONDecoder().decode([WordItem].self, from: data) {
            decodedWords = loaded
        } else {
            decodedWords = Self.fallbackWords
        }

        let progress = loadProgress()
        words = decodedWords.map { item in
            var copy = item
            if let saved = progress[item.id] {
                copy.isKnown = saved.isKnown
                copy.needsPractice = saved.needsPractice
            }
            return copy
        }
    }

    private func saveProgress() {
        let progress = Dictionary(uniqueKeysWithValues: words.map {
            ($0.id, WordProgress(isKnown: $0.isKnown, needsPractice: $0.needsPractice))
        })

        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() -> [String: WordProgress] {
        guard let data = UserDefaults.standard.data(forKey: progressKey),
              let progress = try? JSONDecoder().decode([String: WordProgress].self, from: data) else {
            return [:]
        }
        return progress
    }

    private static let fallbackWords: [WordItem] = [
        WordItem(
            id: "day-1-abate",
            day: 1,
            word: "Abate",
            meaning: "To become less intense or widespread.",
            examples: [
                "The storm began to abate after midnight.",
                "Public anger did not abate until officials explained the decision.",
                "Her headache abated after a few quiet hours."
            ]
        ),
        WordItem(
            id: "day-1-aberrant",
            day: 1,
            word: "Aberrant",
            meaning: "Departing from what is normal or expected.",
            examples: [
                "The scientist ignored one aberrant result and repeated the trial.",
                "His aberrant behavior worried his usually calm teammates.",
                "An aberrant data point can distort the average."
            ]
        ),
        WordItem(
            id: "day-1-acquiesce",
            day: 1,
            word: "Acquiesce",
            meaning: "To accept something reluctantly but without protest.",
            examples: [
                "The committee acquiesced to the revised schedule.",
                "She did not agree, but she chose to acquiesce.",
                "The manager acquiesced after hearing the evidence."
            ]
        )
    ]
}
