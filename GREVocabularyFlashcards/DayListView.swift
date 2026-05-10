import SwiftUI

struct DayListView: View {
    @EnvironmentObject private var store: VocabularyStore

    var body: some View {
        ScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if store.days.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.days, id: \.self) { day in
                            NavigationLink {
                                FlashcardView(day: day)
                            } label: {
                                DayRow(day: day)
                                    .environmentObject(store)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("GRE Vocabulary")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Flashcards")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)

            Text("Choose a day, flip each card, then mark what you know or want to practice again.")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColors.muted)
            Text("No vocabulary found")
                .font(.title3.bold())
                .foregroundStyle(AppColors.ink)
            Text("Make sure vocabulary.json is added to the app target.")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DayRow: View {
    @EnvironmentObject private var store: VocabularyStore
    let day: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(day)")
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.ink)

                    Text("\(store.wordCount(for: day)) words")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppColors.teal)
            }

            ProgressView(value: store.progressValue(for: day))
                .tint(AppColors.teal)

            HStack {
                Label("\(store.progressText(for: day)) completed", systemImage: "chart.bar.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.muted)

                Spacer()

                Text(progressLabel)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppColors.teal)
            }
        }
        .padding(16)
        .background(AppColors.card)
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColors.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var progressLabel: String {
        store.progressValue(for: day) >= 1 ? "Done" : "Study"
    }
}
