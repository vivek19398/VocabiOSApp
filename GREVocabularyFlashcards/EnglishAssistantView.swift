import SwiftUI

struct EnglishAssistantView: View {
    @EnvironmentObject private var store: VocabularyStore
    @StateObject private var assistant = EnglishAssistantService()

    private let suggestions = [
        "Meaning of abate",
        "Correct this sentence: He go to school.",
        "Explain adjective vs adverb",
        "Give examples of assiduous"
    ]

    var body: some View {
        ScreenBackground {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            header

                            ForEach(assistant.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if assistant.isThinking {
                                ThinkingBubble()
                            }
                        }
                        .padding(20)
                    }
                    .onChange(of: assistant.messages.count) { _, _ in
                        if let last = assistant.messages.last {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    suggestionRow
                    inputBar
                }
                .padding(16)
                .background(AppColors.background)
            }
        }
        .navigationTitle("Ask")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("English Assistant")
                .font(.largeTitle.bold())
                .foregroundStyle(AppColors.ink)

            Text("Ask about vocabulary, meanings, grammar, examples, usage, synonyms, antonyms, or sentence correction.")
                .font(.body)
                .foregroundStyle(AppColors.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label("Offline", systemImage: "iphone")
                Label("English only", systemImage: "text.book.closed.fill")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppColors.teal)
        }
        .padding(.bottom, 4)
    }

    private var suggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        assistant.useSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(AppColors.teal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.card)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppColors.line, lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask an English question", text: $assistant.draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(12)
                .background(AppColors.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.line, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                Task {
                    await assistant.send(vocabulary: store.words)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(assistant.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppColors.muted : AppColors.teal)
            }
            .disabled(assistant.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || assistant.isThinking)
            .accessibilityLabel("Send question")
        }
    }
}

private struct MessageBubble: View {
    let message: EnglishAssistantMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 34)
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(isUser ? .white : AppColors.ink)
                .padding(14)
                .background(isUser ? AppColors.teal : AppColors.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isUser ? AppColors.teal : AppColors.line, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)

            if !isUser {
                Spacer(minLength: 34)
            }
        }
    }
}

private struct ThinkingBubble: View {
    var body: some View {
        HStack {
            Label("Thinking", systemImage: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.muted)
                .padding(14)
                .background(AppColors.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppColors.line, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer(minLength: 34)
        }
    }
}
