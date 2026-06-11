import Foundation

@Observable
final class HomeViewModel {
    let features: [(icon: String, title: String)] = [
        ("message.fill", "AI chat assistant"),
        ("pencil.line", "AI text writer"),
        ("photo.on.rectangle.angled", "AI image generator"),
    ]

    private(set) var conversations: [Conversation] = [
        Conversation(id: UUID(), title: "Logo ideas for a coffee brand", preview: "Here are three directions you could explore…"),
        Conversation(id: UUID(), title: "Rewrite my product intro", preview: "Sure — a tighter, friendlier version:"),
        Conversation(id: UUID(), title: "Moodboard: neon violet city", preview: "Generated 4 images in a cyber-dusk palette."),
    ]
}
