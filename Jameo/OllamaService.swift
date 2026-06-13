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
    
    private let systemPrompt = """
    Eres un asistente conciso. Responde siempre en español, de forma directa, en 1-3 párrafos cortos salvo que el usuario pida más detalle. Evita explicaciones largas, preámbulos, resúmenes y advertencias repetidas. Usa listas solo cuando hagan la respuesta más breve. Si hace falta código, proporciona el fragmento mínimo funcional.
    """
    
    private init() {}
    
    func generateStream(prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = try client.chatStream(
                        model: selectedModel,
                        messages: [
                            .system(systemPrompt),
                            .user(prompt),
                        ],
                        options: [
                            "temperature": 0.7,
                            "num_predict": 1024,
                        ],
                        think: JameoSettings.reasoningEnabled,
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

    private var selectedModel: Model.ID {
        Model.ID(rawValue: JameoSettings.model) ?? Model.ID(rawValue: JameoSettings.defaultModel)!
    }
}
