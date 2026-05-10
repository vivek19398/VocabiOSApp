import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DayListView()
            }
            .tabItem {
                Label("Study", systemImage: "rectangle.stack.fill")
            }

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label("Review", systemImage: "star.fill")
            }

            NavigationStack {
                QuizView()
            }
            .tabItem {
                Label("Quiz", systemImage: "checkmark.circle.fill")
            }

            NavigationStack {
                EnglishAssistantView()
            }
            .tabItem {
                Label("Ask", systemImage: "text.bubble.fill")
            }
        }
        .tint(AppColors.teal)
    }
}

enum AppColors {
    static let background = Color(red: 0.96, green: 0.98, blue: 0.97)
    static let card = Color.white
    static let teal = Color(red: 0.02, green: 0.55, blue: 0.55)
    static let green = Color(red: 0.15, green: 0.58, blue: 0.32)
    static let coral = Color(red: 0.86, green: 0.32, blue: 0.28)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.16)
    static let muted = Color(red: 0.43, green: 0.48, blue: 0.53)
    static let line = Color(red: 0.86, green: 0.90, blue: 0.89)
    static let gold = Color(red: 0.93, green: 0.63, blue: 0.18)
}

struct ScreenBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            content
        }
    }
}

struct SolidButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct OutlineButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.card.opacity(configuration.isPressed ? 0.65 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
