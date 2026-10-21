import Foundation

// MARK: - ClipboardItem

struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var text: String
    var copiedAt: Date
    var sourceApp: String?
    var isPinned: Bool

    init(id: UUID = UUID(), text: String, copiedAt: Date = Date(), sourceApp: String? = nil, isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.sourceApp = sourceApp
        self.isPinned = isPinned
    }

    var previewText: String {
        let lines = text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
        return lines.prefix(2).joined(separator: " ")
    }

    var charCount: Int {
        text.count
    }

    var lineCount: Int {
        text.split(whereSeparator: \.isNewline).count
    }

    var timeAgo: String {
        let diff = Date().timeIntervalSince(copiedAt)
        if diff < 10 { return String(localized: "just now") }
        if diff < 60 { return "\(Int(diff))s ago" }
        let mins = Int(diff / 60)
        if mins < 60 { return "\(mins)m ago" }
        let hours = Int(mins / 60)
        if hours < 24 { return "\(hours)h ago" }
        let days = Int(hours / 24)
        return "\(days)d ago"
    }
}
