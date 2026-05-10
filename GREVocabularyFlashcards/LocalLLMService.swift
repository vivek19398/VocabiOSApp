import Foundation

#if canImport(SwiftLlama)
import SwiftLlama
#endif

enum LocalLLMError: Error {
    case packageMissing
    case modelMissing
    case emptyResponse
}

final class LocalLLMService {
    static let modelFileName = "english-assistant"
    static let modelFileExtension = "gguf"

    func answer(prompt: String) async throws -> String {
        #if canImport(SwiftLlama)
        guard let modelURL = Self.modelURL() else {
            throw LocalLLMError.modelMissing
        }

        let service = LlamaService(
            modelUrl: modelURL,
            config: .init(batchSize: 256, maxTokenCount: 2048, useGPU: true)
        )

        let messages = [
            LlamaChatMessage(
                role: .system,
                content: "You are VocabiOS English Tutor. Answer only English-learning questions."
            ),
            LlamaChatMessage(role: .user, content: prompt)
        ]

        let stream = try await service.streamCompletion(
            of: messages,
            samplingConfig: .init(temperature: 0.25, seed: 42)
        )

        var answer = ""
        for try await token in stream {
            answer += token
            if answer.count > 3_500 {
                break
            }
        }

        let cleaned = answer
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            throw LocalLLMError.emptyResponse
        }

        return cleaned
        #else
        throw LocalLLMError.packageMissing
        #endif
    }

    static func setupMessage(for error: Error) -> String {
        switch error {
        case LocalLLMError.packageMissing:
            return "Local LLM setup needed: add the free Swift package `https://github.com/pgorzelany/swift-llama-cpp` to Xcode, then add a GGUF Hugging Face model named `english-assistant.gguf` to the app target."
        case LocalLLMError.modelMissing:
            return "Local LLM setup needed: add a free Hugging Face GGUF model to Xcode and rename it `english-assistant.gguf`. Make sure Target Membership is checked."
        case LocalLLMError.emptyResponse:
            return "The local model returned an empty response. Try a shorter question or a smaller prompt."
        default:
            return "The local model could not answer this time. Try again with a shorter English-learning question."
        }
    }

    private static func modelURL() -> URL? {
        if let namedURL = Bundle.main.url(forResource: modelFileName, withExtension: modelFileExtension) {
            return namedURL
        }

        return Bundle.main.urls(forResourcesWithExtension: modelFileExtension, subdirectory: nil)?.first
    }
}
