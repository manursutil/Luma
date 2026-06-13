//
//  ContentView.swift
//  Luma
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var answer: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Ask Luma...", text: $prompt)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit {
                        askLuma()
                    }

                Button("Ask") {
                    askLuma()
                }
                .disabled(isLoading)
            }

            if isLoading {
                ProgressView()
            }

            if !answer.isEmpty {
                Divider()
                Text(answer)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(width: 700)
    }
    
    private func askLuma() {
        let submittedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPrompt.isEmpty else { return }

        Task {
            isLoading = true
            answer = ""
            
            do {
                let stream = OllamaService.shared.generateStream(prompt: submittedPrompt)

                for try await chunk in stream {
                    answer += chunk
                }
            } catch {
                answer = "Error \(error)"
            }
            
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
