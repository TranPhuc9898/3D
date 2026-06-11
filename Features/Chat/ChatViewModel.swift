import Foundation

@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Let me know what you want to create today."),
    ]
    private(set) var credits = 74
    private(set) var isStreaming = false
    var draft = ""

    private let openAI = OpenAIService()

    func send() {
        guard !draft.isEmpty, !isStreaming else { return }
        messages.append(ChatMessage(role: .user, text: draft))
        draft = ""
        credits -= 1
        Task { await streamReply() }
    }

    @MainActor
    private func streamReply() async {
        isStreaming = true
        let history = messages
        messages.append(ChatMessage(role: .assistant, text: ""))
        let index = messages.count - 1
        do {
            for try await token in try await openAI.streamReply(history: history) {
                messages[index].text += token
            }
        } catch {
            messages[index].text = "Sorry — I couldn't reach the model. \(error.localizedDescription)"
        }
        isStreaming = false
    }
}
