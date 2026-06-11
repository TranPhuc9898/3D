import Foundation

struct Conversation: Identifiable, Hashable {
    let id: UUID
    let title: String
    let preview: String
}

struct ChatMessage: Identifiable, Hashable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    var text: String
}
