//
//  Ollama.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Ollama
import Foundation

class OllamaService {
    static let shared = OllamaService()
    
    private let client = Client(
        host: URL(string: "http://127.0.0.1:11434")!,
        userAgent: "Jameo/1.0"
    )
    
    private let model = Model.ID(rawValue: "qwen3.5:9b")!
    private let systemPrompt = """
    You are a concise assistant. Answer directly in 1-3 short paragraphs unless the user asks for detail. Avoid long explanations, preambles, summaries, and repeated caveats. Prefer bullets only when they make the answer shorter. If code is needed, provide the minimal working snippet.
    """
    
    private init() {}
    
    func generateStream(prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = try client.chatStream(
                        model: model,
                        messages: [
                            .system(systemPrompt),
                            .user(prompt),
                        ],
                        options: [
                            "temperature": 0.7,
                            "num_predict": 1024,
                        ],
                        think: false,
                        keepAlive: .minutes(10)
                    )

                    for try await chunk in stream {
                        continuation.yield(chunk.message.content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
