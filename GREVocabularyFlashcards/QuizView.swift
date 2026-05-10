import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var store: VocabularyStore

    let day: Int?

    @State private var questions: [WordItem] = []
    @State private var currentIndex = 0
    @State private var options: [String] = []
    @State private var selectedOption: String?
    @State private var score = 0
    @State private var finished = false

    init(day: Int? = nil) {
        self.day = day
    }

    private var currentQuestion: WordItem? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    private var title: String {
        if let day {
            return "Day \(day) Quiz"
        }
        return "Quiz"
    }

    var body: some View {
        ScreenBackground {
            VStack(spacing: 18) {
                if availableWords.isEmpty {
                    emptyState
                } else if finished {
                    resultState
                } else if let question = currentQuestion {
                    quizHeader
                    questionCard(for: question)
                    optionsList(for: question)
                    nextButton
                }
            }
            .padding(20)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if questions.isEmpty {
                startQuiz()
            }
        }
    }

    private var availableWords: [WordItem] {
        if let day {
            return store.words(for: day)
        }
        return store.words
    }

    private var quizHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Question \(min(currentIndex + 1, questions.count)) of \(questions.count)")
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)

                Spacer()

                Text("Score \(score)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.teal)
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(max(questions.count, 1)))
                .tint(AppColors.teal)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "questionmark.circle")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(AppColors.muted)

            Text("No quiz words")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)

            Text("Add vocabulary.json to the app target to create quiz questions.")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    private var resultState: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: score >= max(questions.count / 2, 1) ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(AppColors.gold)

            Text("Quiz Complete")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)

            Text("\(score) / \(questions.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.teal)

            Button {
                startQuiz()
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(SolidButtonStyle(color: AppColors.teal))

            Spacer()
        }
    }

    private func questionCard(for question: WordItem) -> some View {
        VStack(spacing: 12) {
            Text("Choose the meaning")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColors.muted)

            Text(question.word)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.ink)
                .minimumScaleFactor(0.55)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppColors.card)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func optionsList(for question: WordItem) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    choose(option, for: question)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: iconName(for: option, question: question))
                            .font(.headline)
                            .foregroundStyle(iconColor(for: option, question: question))
                            .frame(width: 22)

                        Text(option)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppColors.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(optionBackground(for: option, question: question))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(optionBorder(for: option, question: question), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(selectedOption == nil)
            }
        }
    }

    private var nextButton: some View {
        Button {
            goToNextQuestion()
        } label: {
            Label(currentIndex == questions.count - 1 ? "Finish Quiz" : "Next Question", systemImage: "arrow.right.circle.fill")
        }
        .buttonStyle(SolidButtonStyle(color: selectedOption == nil ? AppColors.muted : AppColors.teal))
        .disabled(selectedOption == nil)
    }

    private func startQuiz() {
        let source = availableWords.shuffled()
        questions = source
        currentIndex = 0
        score = 0
        finished = false
        selectedOption = nil
        loadOptions()
    }

    private func loadOptions() {
        guard let question = currentQuestion else {
            options = []
            return
        }

        let distractors = store.words
            .filter { $0.id != question.id }
            .map(\.meaning)
            .shuffled()
            .prefix(3)

        options = ([question.meaning] + Array(distractors)).shuffled()
    }

    private func choose(_ option: String, for question: WordItem) {
        guard selectedOption == nil else { return }
        selectedOption = option

        if option == question.meaning {
            score += 1
        } else {
            store.markNeedsPractice(question)
        }
    }

    private func goToNextQuestion() {
        selectedOption = nil

        if currentIndex < questions.count - 1 {
            currentIndex += 1
            loadOptions()
        } else {
            finished = true
        }
    }

    private func optionBackground(for option: String, question: WordItem) -> Color {
        guard let selectedOption else { return AppColors.card }

        if option == question.meaning {
            return AppColors.green.opacity(0.16)
        }

        if option == selectedOption {
            return AppColors.coral.opacity(0.14)
        }

        return AppColors.card
    }

    private func optionBorder(for option: String, question: WordItem) -> Color {
        guard let selectedOption else { return AppColors.line }

        if option == question.meaning {
            return AppColors.green.opacity(0.65)
        }

        if option == selectedOption {
            return AppColors.coral.opacity(0.65)
        }

        return AppColors.line
    }

    private func iconName(for option: String, question: WordItem) -> String {
        guard let selectedOption else { return "circle" }

        if option == question.meaning {
            return "checkmark.circle.fill"
        }

        if option == selectedOption {
            return "xmark.circle.fill"
        }

        return "circle"
    }

    private func iconColor(for option: String, question: WordItem) -> Color {
        guard selectedOption != nil else { return AppColors.muted }

        if option == question.meaning {
            return AppColors.green
        }

        if option == selectedOption {
            return AppColors.coral
        }

        return AppColors.muted
    }
}
