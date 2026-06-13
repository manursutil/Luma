//
//  Ollama.swift
//  Luma
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Ollama
import Foundation

class OllamaService {
    static let shared = OllamaService()
    
    private let client = Client(
        host: URL(string: "http://127.0.0.1:11434")!,
        userAgent: "Luma/1.0"
    )
    
    private let model = Model.ID(rawValue: "qwen3.5:9b")!
    
    private init() {}
    
    func generateStream(prompt: String) -> AsyncThrowingStream<String, Error> {
        let promptWithoutThinking = "/no_think\n\(prompt)"

        let stream = client.generateStream(
            model: model,
            prompt: promptWithoutThinking,
            options: [
                "temperature": 0.7,
                "num_predict": 256
            ],
            think: false,
            keepAlive: .minutes(10)
        )

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await chunk in stream {
                        continuation.yield(chunk.response)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
