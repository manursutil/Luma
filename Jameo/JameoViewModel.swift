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

    private var generationTask: Task<Void, Never>?

    func requestFocus() {
        focusRequest = UUID()
    }

    func reset() {
        generationTask?.cancel()
        generationTask = nil
        prompt = ""
        answer = ""
        isLoading = false
    }

    func askJameo() {
        let submittedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPrompt.isEmpty, !isLoading else { return }

        generationTask = Task {
            isLoading = true
            answer = ""

            do {
                let stream = OllamaService.shared.generateStream(prompt: submittedPrompt)

                for try await chunk in stream {
                    guard !Task.isCancelled else { return }
                    answer += chunk
                }
            } catch {
                guard !Task.isCancelled else { return }
                answer = "Error: \(error)"
            }

            isLoading = false
            generationTask = nil
        }
    }
}
