# VocabiOSApp

VocabiOSApp is a local SwiftUI flashcard app for vocabulary practice on iPhone. It has no backend, no login, no network dependency, and stores study progress locally with `UserDefaults`.

The bundled `vocabulary.json` currently contains `5005` vocabulary entries extracted from the provided PDF, randomized into `167` study days with up to `30` words per day.

## Features

- Day-wise study list with progress such as `5 / 30 completed`
- Tap-to-flip flashcards with smooth animation
- Front of card: word
- Back of card: meaning and example sentences
- `I Know This` and `Need Practice` actions
- Review tab for weak words from every day
- Multiple-choice quiz mode with instant correct/wrong feedback
- Local persistence through `UserDefaults`
- Offline-first JSON vocabulary data
- 1024 x 1024 app icon asset included as `AppIcon-1024.png`

## App Architecture

```text
VocabiOSApp
├── FlashcardApp.swift        App entry point and shared store injection
├── ContentView.swift         Main tab shell and shared UI styling
├── Models.swift              WordItem and saved progress models
├── VocabularyStore.swift     Data loading, filtering, progress, review state
├── DayListView.swift         Home screen with all study days
├── FlashcardView.swift       Day-specific flashcard study experience
├── ReviewView.swift          Weak-word review flow
├── QuizView.swift            Multiple-choice quiz flow
├── vocabulary.json           Bundled local vocabulary dataset
└── AppIcon-1024.png          iOS app icon source image
```

## Data Flow

1. `FlashcardApp` creates one `VocabularyStore` as a `@StateObject`.
2. `ContentView` injects that store into all tabs with `.environmentObject(store)`.
3. `VocabularyStore` loads `vocabulary.json` from the app bundle.
4. The store overlays saved progress from `UserDefaults`.
5. `DayListView`, `FlashcardView`, `ReviewView`, and `QuizView` read and update the same store.
6. Every `I Know This`, `Need Practice`, or `Remove From Review` action saves progress locally.

## Local Data Model

Each vocabulary entry uses this shape:

```json
{
  "id": "vocab-abate",
  "day": 1,
  "word": "abate",
  "meaning": "v. To become less intense or widespread.",
  "examples": [
    "The speaker tried to abate the problem before the meeting ended.",
    "In context, to abate means to become less intense or widespread.",
    "The passage suggests that leaders sometimes abate when pressure increases."
  ]
}
```

`id` should stay stable. Progress is saved by `id`, so changing IDs resets saved progress for those words.

## Screen Responsibilities

`DayListView`

Shows all available study days and each day’s completion progress.

`FlashcardView`

Displays one card at a time for the selected day. Tapping flips the card. The action buttons update `isKnown` and `needsPractice`.

`ReviewView`

Filters all words where `needsPractice == true`, lets the user revise them, and removes learned words from review.

`QuizView`

Builds multiple-choice questions from local vocabulary meanings. Incorrect answers are automatically marked for review.

`VocabularyStore`

Owns all vocabulary state, JSON loading, day filtering, progress calculation, review filtering, and local persistence.

## Persistence

The app saves only progress, not a modified copy of the whole vocabulary file.

Saved value:

```swift
WordProgress(
    isKnown: Bool,
    needsPractice: Bool
)
```

Storage:

```swift
UserDefaults.standard
```

Key:

```swift
gre-vocabulary-progress-v1
```

## Add These Files In Xcode

1. Open Xcode and choose **File > New > Project...**.
2. Pick **iOS > App**.
3. Product name: `VocabiOSApp` or your preferred app name.
4. Interface: **SwiftUI**.
5. Language: **Swift**.
6. Delete the default `ContentView.swift`.
7. Keep only one `@main` app file. Either use `FlashcardApp.swift`, or paste its contents into Xcode’s generated app file.
8. Drag these files into the Xcode project navigator:
   - `FlashcardApp.swift`
   - `ContentView.swift`
   - `Models.swift`
   - `VocabularyStore.swift`
   - `DayListView.swift`
   - `FlashcardView.swift`
   - `ReviewView.swift`
   - `QuizView.swift`
   - `vocabulary.json`
   - `AppIcon-1024.png`
9. In the import dialog, check **Copy items if needed** and make sure the app target is checked.
10. Select `vocabulary.json` and confirm it is included under **Target Membership**.
11. Open `Assets.xcassets > AppIcon` and drag `AppIcon-1024.png` into the 1024 x 1024 app icon slot.
12. Build and run on an iPhone simulator or a connected iPhone.

## Signing For iPhone

To run locally on your iPhone:

1. Select the app target in Xcode.
2. Open **Signing & Capabilities**.
3. Check **Automatically manage signing**.
4. Choose your Apple ID or Personal Team.
5. Use a unique Bundle Identifier, for example `com.yourname.VocabiOSApp`.
6. Select your iPhone as the run destination.
7. Press **Run**.

## Replace Vocabulary Later

The app reads `vocabulary.json` from the app bundle. To replace the data:

1. Convert your PDF or spreadsheet into the JSON shape shown above.
2. Preserve stable `id` values where possible.
3. Replace `vocabulary.json` in Xcode.
4. Confirm Target Membership is checked.
5. Use **Product > Clean Build Folder**.
6. Delete the old app from the iPhone if cached data appears stale.
7. Build and run again.

## Troubleshooting

If only a few days appear, Xcode is probably still using an older `vocabulary.json`. Replace the file in Xcode and confirm Target Membership.

If words inside a day appear alphabetical, make sure `VocabularyStore.words(for:)` does not sort the words:

```swift
func words(for day: Int) -> [WordItem] {
    words.filter { $0.day == day }
}
```

If examples do not appear, confirm the current `vocabulary.json` has non-empty `examples` arrays and that `FlashcardView` uses `word.displayExamples`.

If Xcode reports that `@main` can only apply to one type, remove one duplicate app entry point. A SwiftUI module can only have one `@main` struct.
