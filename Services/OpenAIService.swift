import Foundation

enum OpenAIServiceError: LocalizedError {
    case missingAPIKey
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Chưa điền OpenAI API key trong Services/Secrets.swift."
        case .http(let code): "OpenAI trả lỗi HTTP \(code)."
        }
    }
}

struct OpenAIService {
    private struct StreamChunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta
        }
        let choices: [Choice]
    }

    /// Gọi /v1/chat/completions với stream: true, trả về từng token qua SSE.
    func streamReply(history: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error> {
        guard !Secrets.openAIAPIKey.isEmpty else { throw OpenAIServiceError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://models.github.ai/inference/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages: [[String: String]] =
            [["role": "system",
              "content": "You are P-AI, a warm, helpful creative assistant. Answer concisely."]]
            + history.map {
                ["role": $0.role == .user ? "user" : "assistant", "content": $0.text]
            }
        let body: [String: Any] = ["model": "openai/gpt-4o-mini", "stream": true, "messages": messages]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenAIServiceError.http((response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        if let data = payload.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                           let token = chunk.choices.first?.delta.content {
                            continuation.yield(token)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
