import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: VocabularyStore

    @State private var currentIndex = 0
    @State private var isFlipped = false

    private var reviewWords: [WordItem] {
        store.reviewWords
    }

    private var currentWord: WordItem? {
        guard reviewWords.indices.contains(currentIndex) else { return nil }
        return reviewWords[currentIndex]
    }

    var body: some View {
        ScreenBackground {
            VStack(spacing: 18) {
                if reviewWords.isEmpty {
                    emptyState
                } else if let word = currentWord {
                    header

                    ReviewCard(word: word, isFlipped: isFlipped)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.42)) {
                                isFlipped.toggle()
                            }
                        }

                    VStack(spacing: 12) {
                        Button {
                            store.removeFromReview(word)
                            keepIndexInRange()
                        } label: {
                            Label("Remove From Review", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(SolidButtonStyle(color: AppColors.green))

                        Button {
                            moveToNextReviewCard()
                        } label: {
                            Label("Still Practicing", systemImage: "arrow.right.circle")
                        }
                        .buttonStyle(OutlineButtonStyle(color: AppColors.teal))
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Review")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weak Words")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.ink)

                Spacer()

                Text("\(min(currentIndex + 1, reviewWords.count)) / \(reviewWords.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.teal)
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(max(reviewWords.count, 1)))
                .tint(AppColors.gold)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(AppColors.gold)

            Text("No review words")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)

            Text("Tap Need Practice on any flashcard and it will appear here.")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func moveToNextReviewCard() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isFlipped = false
            currentIndex = (currentIndex + 1) % max(reviewWords.count, 1)
        }
    }

    private func keepIndexInRange() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isFlipped = false
            if currentIndex >= reviewWords.count {
                currentIndex = max(reviewWords.count - 1, 0)
            }
        }
    }
}

private struct ReviewCard: View {
    let word: WordItem
    let isFlipped: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Text("Day \(word.day)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.teal)

                Text(word.word)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.ink)
                    .minimumScaleFactor(0.55)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("Tap to reveal meaning")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .background(AppColors.card)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(word.word)
                        .font(.title.bold())
                        .foregroundStyle(AppColors.teal)

                    Text(word.meaning)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppColors.ink)

                    ForEach(Array(word.displayExamples.prefix(3).enumerated()), id: \.offset) { _, example in
                        Text("- \(example)")
                            .font(.body)
                            .foregroundStyle(AppColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.card)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppColors.line, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : -90), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 430)
        .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
        .animation(.easeInOut(duration: 0.42), value: isFlipped)
        .accessibilityAddTraits(.isButton)
    }
}
