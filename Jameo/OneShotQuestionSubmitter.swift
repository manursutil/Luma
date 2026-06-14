import Foundation

enum OneShotQuestionSubmissionError: LocalizedError {
    case selectedModelDoesNotSupportScreenContext
    case screenCaptureUnavailable

    var errorDescription: String? {
        switch self {
        case .selectedModelDoesNotSupportScreenContext:
            String(localized: "The selected model does not support screen context.")
        case .screenCaptureUnavailable:
            String(localized: "Could not capture the current screen.")
        }
    }
}

struct OneShotQuestionResponse {
    let stream: AsyncThrowingStream<String, Error>
    let includedScreenContext: Bool
}

@MainActor
struct OneShotQuestionSubmitter {
    var selectedModelSupportsVision: () async throws -> Bool
    var captureScreenImage: () async throws -> Data?
    var generateStream: (_ prompt: String, _ images: [Data]?) -> AsyncThrowingStream<String, Error>

    func submit(prompt rawPrompt: String, includeScreenContext: Bool) async throws -> OneShotQuestionResponse? {
        let submittedPrompt = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPrompt.isEmpty || includeScreenContext else {
            return nil
        }

        var screenImages: [Data]?

        if includeScreenContext {
            guard try await selectedModelSupportsVision() else {
                throw OneShotQuestionSubmissionError.selectedModelDoesNotSupportScreenContext
            }

            guard let screenImage = try await captureScreenImage() else {
                throw OneShotQuestionSubmissionError.screenCaptureUnavailable
            }

            screenImages = [screenImage]
        }

        let prompt = submittedPrompt.isEmpty ? String(localized: "Help me understand what is on my screen.") : submittedPrompt
        return OneShotQuestionResponse(
            stream: generateStream(prompt, screenImages),
            includedScreenContext: screenImages != nil
        )
    }
}
