import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject private var store: VocabularyStore

    let day: Int

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var finished = false

    private var dayWords: [WordItem] {
        store.words(for: day)
    }

    private var currentWord: WordItem? {
        guard dayWords.indices.contains(currentIndex) else { return nil }
        return dayWords[currentIndex]
    }

    var body: some View {
        ScreenBackground {
            VStack(spacing: 18) {
                if dayWords.isEmpty {
                    emptyState
                } else if finished {
                    finishedState
                } else if let word = currentWord {
                    progressHeader

                    StudyCard(word: word, isFlipped: isFlipped)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.42)) {
                                isFlipped.toggle()
                            }
                        }

                    actionButtons(for: word)
                }
            }
            .padding(20)
        }
        .navigationTitle("Day \(day)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink {
                QuizView(day: day)
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .accessibilityLabel("Start day quiz")
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Card \(min(currentIndex + 1, dayWords.count)) of \(dayWords.count)")
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)

                Spacer()

                Text("\(store.progressText(for: day)) done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.teal)
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(max(dayWords.count, 1)))
                .tint(AppColors.teal)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColors.muted)
            Text("No cards for this day")
                .font(.title3.bold())
                .foregroundStyle(AppColors.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var finishedState: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(AppColors.green)

            Text("Day \(day) complete")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)

            Text("Nice work. Words marked Need Practice are waiting in the Review tab.")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .multilineTextAlignment(.center)

            Button {
                currentIndex = 0
                finished = false
                isFlipped = false
            } label: {
                Label("Study Again", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(SolidButtonStyle(color: AppColors.teal))

            Spacer()
        }
    }

    private func actionButtons(for word: WordItem) -> some View {
        VStack(spacing: 12) {
            Button {
                store.markKnown(word)
                moveToNextCard()
            } label: {
                Label("I Know This", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(SolidButtonStyle(color: AppColors.green))

            Button {
                store.markNeedsPractice(word)
                moveToNextCard()
            } label: {
                Label("Need Practice", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(OutlineButtonStyle(color: AppColors.coral))
        }
    }

    private func moveToNextCard() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isFlipped = false

            if currentIndex < dayWords.count - 1 {
                currentIndex += 1
            } else {
                finished = true
            }
        }
    }
}

private struct StudyCard: View {
    let word: WordItem
    let isFlipped: Bool

    var body: some View {
        ZStack {
            CardFace {
                VStack(spacing: 18) {
                    Text(word.word)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.ink)
                        .minimumScaleFactor(0.55)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text("Tap to reveal meaning")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.muted)
                }
                .padding(24)
            }
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))

            CardFace {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(word.word)
                            .font(.title.bold())
                            .foregroundStyle(AppColors.teal)

                        Text(word.meaning)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppColors.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Examples")
                                .font(.headline)
                                .foregroundStyle(AppColors.ink)

                            ForEach(Array(word.displayExamples.prefix(3).enumerated()), id: \.offset) { _, example in
                                Text("- \(example)")
                                    .font(.body)
                                    .foregroundStyle(AppColors.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
            }
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -90), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 430)
        .animation(.easeInOut(duration: 0.42), value: isFlipped)
        .accessibilityAddTraits(.isButton)
    }
}

private struct CardFace<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.card)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
}
