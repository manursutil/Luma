//
//  JameoViewModel.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Combine
import Foundation

@MainActor
final class JameoViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var answer: String = ""
    @Published var isLoading: Bool = false
    @Published var focusRequest = UUID()
    @Published var screenContextEnabled: Bool = false
    @Published private(set) var screenContextAvailable: Bool = false
    @Published private(set) var isCheckingScreenContextAvailability: Bool = false
    @Published private(set) var didSubmitWithScreenContext: Bool = false

    private var generationTask: Task<Void, Never>?
    private var availabilityTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    private let submitterOverride: OneShotQuestionSubmitter?
    private lazy var submitter: OneShotQuestionSubmitter = {
        submitterOverride ?? OneShotQuestionSubmitter(
            selectedModelSupportsVision: {
                try await OllamaService.shared.selectedModelSupportsVision()
            },
            captureScreenImage: { [weak self] in
                try await self?.screenContextImageProvider?()
            },
            generateStream: { prompt, images in
                OllamaService.shared.generateStream(prompt: prompt, images: images)
            }
        )
    }()

    var screenContextImageProvider: (() async throws -> Data?)?

    init(submitter: OneShotQuestionSubmitter? = nil) {
        self.submitterOverride = submitter

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshScreenContextAvailability()
            }
            .store(in: &cancellables)

        refreshScreenContextAvailability()
    }

    var canSubmit: Bool {
        !isLoading && (!prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || screenContextEnabled)
    }

    var canToggleScreenContext: Bool {
        !isLoading && !isCheckingScreenContextAvailability && screenContextAvailable
    }

    func requestFocus() {
        focusRequest = UUID()
    }

    func reset() {
        generationTask?.cancel()
        generationTask = nil
        prompt = ""
        answer = ""
        isLoading = false
        didSubmitWithScreenContext = false
    }

    func askJameo() {
        guard canSubmit else { return }

        generationTask = Task {
            isLoading = true
            answer = ""
            didSubmitWithScreenContext = false

            let response: OneShotQuestionResponse

            do {
                guard let preparedResponse = try await submitter.submit(
                    prompt: prompt,
                    includeScreenContext: screenContextEnabled
                ) else {
                    isLoading = false
                    generationTask = nil
                    return
                }

                response = preparedResponse
            } catch OneShotQuestionSubmissionError.selectedModelDoesNotSupportScreenContext {
                guard !Task.isCancelled else { return }
                screenContextAvailable = false
                screenContextEnabled = false
                answer = OneShotQuestionSubmissionError.selectedModelDoesNotSupportScreenContext.localizedDescription
                isLoading = false
                generationTask = nil
                return
            } catch let error as LocalizedError {
                guard !Task.isCancelled else { return }
                answer = error.localizedDescription
                isLoading = false
                generationTask = nil
                return
            } catch {
                guard !Task.isCancelled else { return }
                answer = "Error: \(error)"
                isLoading = false
                generationTask = nil
                return
            }

            do {
                didSubmitWithScreenContext = response.includedScreenContext

                for try await chunk in response.stream {
                    guard !Task.isCancelled else { return }
                    answer += chunk
                }

                if response.includedScreenContext {
                    screenContextEnabled = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                answer = "Error: \(error)"
            }

            isLoading = false
            generationTask = nil
        }
    }

    func refreshScreenContextAvailability() {
        availabilityTask?.cancel()

        availabilityTask = Task {
            isCheckingScreenContextAvailability = true

            do {
                screenContextAvailable = try await OllamaService.shared.selectedModelSupportsVision()
            } catch {
                guard !Task.isCancelled else { return }
                screenContextAvailable = false
            }

            if !screenContextAvailable {
                screenContextEnabled = false
            }

            isCheckingScreenContextAvailability = false
            availabilityTask = nil
        }
    }
}
