import SwiftUI

@main
struct FlashcardApp: App {
    @StateObject private var store = VocabularyStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
