# VocabiOSApp

VocabiOSApp is a local SwiftUI flashcard app for vocabulary practice on iPhone. It has no backend, no login, no network dependency, and stores study progress locally with `UserDefaults`.

The app source is in `GREVocabularyFlashcards/`. The bundled `vocabulary.json` contains `5005` vocabulary entries extracted from the provided PDF, randomized into `167` study days with up to `30` words per day.

## Features

- Day-wise study list with completion progress
- Tap-to-flip flashcards with smooth animation
- Meaning and example sentences on the back of each card
- `I Know This` and `Need Practice` actions
- Review tab for weak words from every day
- Multiple-choice quiz mode with instant feedback
- Ask tab for English-only local assistant questions
- Local progress persistence with `UserDefaults`
- Offline-first bundled JSON vocabulary data
- 1024 x 1024 app icon asset

## Architecture

```text
VocabiOSApp
├── README.md
└── GREVocabularyFlashcards
    ├── FlashcardApp.swift        App entry point and shared store injection
    ├── ContentView.swift         Main tab shell and shared UI styling
    ├── Models.swift              WordItem and saved progress models
    ├── VocabularyStore.swift     Data loading, filtering, progress, review state
    ├── DayListView.swift         Home screen with all study days
    ├── FlashcardView.swift       Day-specific flashcard study experience
    ├── ReviewView.swift          Weak-word review flow
    ├── QuizView.swift            Multiple-choice quiz flow
    ├── EnglishAssistantView.swift Ask tab chat interface
    ├── EnglishAssistantService.swift English-only guard and assistant state
    ├── LocalLLMService.swift     Optional local GGUF model adapter
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

`id` should stay stable because progress is saved by `id`.

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

Owns vocabulary loading, day filtering, progress calculation, review filtering, and local persistence.

`EnglishAssistantView`

Adds an Ask tab where users can ask about meanings, examples, grammar, usage, synonyms, antonyms, and sentence correction.

`EnglishAssistantService`

Keeps chat state, blocks non-English-learning topics, builds the model prompt, and falls back to bundled vocabulary/basic grammar until a local model is installed.

`LocalLLMService`

Looks for a bundled `english-assistant.gguf` model and uses the optional `SwiftLlama` package when available. The app still builds without the package or model, but it will show setup guidance in the Ask tab.

## Persistence

Only progress is saved locally. The app does not rewrite `vocabulary.json`.

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

## Add Files In Xcode

1. Open Xcode and choose **File > New > Project...**.
2. Pick **iOS > App**.
3. Product name: `VocabiOSApp` or your preferred app name.
4. Interface: **SwiftUI**.
5. Language: **Swift**.
6. Delete the default `ContentView.swift`.
7. Keep only one `@main` app file. Either use `FlashcardApp.swift`, or paste its contents into Xcode’s generated app file.
8. Drag the files from `GREVocabularyFlashcards/` into the Xcode project navigator.
9. In the import dialog, check **Copy items if needed** and make sure the app target is checked.
10. Select `vocabulary.json` and confirm it is included under **Target Membership**.
11. Open `Assets.xcassets > AppIcon` and drag `AppIcon-1024.png` into the 1024 x 1024 app icon slot.
12. Build and run on an iPhone simulator or connected iPhone.

## Free Local Hugging Face LLM Setup

The Ask tab is wired for a free local Hugging Face GGUF model. The model file is intentionally not committed because even small models are hundreds of MB.

Recommended small free model:

- `Qwen/Qwen2-0.5B-Instruct-GGUF`
- Use a 4-bit file such as `qwen2-0_5b-instruct-q4_k_m.gguf` if available
- Approximate size: about `398 MB`

Smaller alternative:

- `jc-builds/SmolLM2-360M-Instruct-Q4_K_M-GGUF`
- Approximate size: about `271 MB`

In Xcode:

1. Choose **File > Add Package Dependencies...**.
2. Add `https://github.com/pgorzelany/swift-llama-cpp`.
3. Add the `SwiftLlama` product to your app target.
4. Download a `.gguf` model from Hugging Face.
5. Rename the downloaded file to `english-assistant.gguf`.
6. Drag `english-assistant.gguf` into Xcode.
7. Check **Copy items if needed**.
8. Make sure the app target is checked under **Target Membership**.
9. Build and run on your iPhone.

After this, the Ask tab runs the model locally on the device. No backend or paid API is needed.

## Signing For iPhone

1. Select the app target in Xcode.
2. Open **Signing & Capabilities**.
3. Check **Automatically manage signing**.
4. Choose your Apple ID or Personal Team.
5. Use a unique Bundle Identifier, for example `com.yourname.VocabiOSApp`.
6. Select your iPhone as the run destination.
7. Press **Run**.

## Replace Vocabulary Later

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
