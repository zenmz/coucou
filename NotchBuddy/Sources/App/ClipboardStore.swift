import Foundation
import AppKit

// MARK: - ClipboardStore

@MainActor
final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    static let maxItems = 100
    private static var fileURL: URL {
        HookServer.supportDir.appendingPathComponent("clipboard_history.json")
    }

    @Published private(set) var items: [ClipboardItem] = []
    @Published var searchQuery: String = ""

    private init() {
        load()
    }

    // MARK: - Computed Filtered List

    var filteredItems: [ClipboardItem] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseList: [ClipboardItem]
        if trimmed.isEmpty {
            baseList = items
        } else {
            baseList = items.filter { $0.text.localizedCaseInsensitiveContains(trimmed) }
        }

        // Pinned first, then sorted by copiedAt descending
        return baseList.sorted { a, b in
            if a.isPinned != b.isPinned {
                return a.isPinned && !b.isPinned
            }
            return a.copiedAt > b.copiedAt
        }
    }

    // MARK: - Mutations

    func add(_ text: String, sourceApp: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // If identical to the most recent unpinned clip, just bump its timestamp
        if let first = items.first, first.text == text {
            items[0].copiedAt = Date()
            save()
            return
        }

        // Remove existing identical entry if present (to avoid duplicates)
        items.removeAll { $0.text == text && !$0.isPinned }

        let newItem = ClipboardItem(text: text, copiedAt: Date(), sourceApp: sourceApp, isPinned: false)
        items.insert(newItem, at: 0)

        if items.count > Self.maxItems {
            // Keep pinned items even if over maxItems, remove oldest unpinned
            if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                items.remove(at: lastUnpinnedIndex)
            } else {
                items.removeLast()
            }
        }

        save()
    }

    func togglePin(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isPinned.toggle()
        save()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        // Keep pinned clips by default when clearing
        items.removeAll { !$0.isPinned }
        save()
    }

    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
    }

    func pasteDirectly(_ item: ClipboardItem) {
        copyToClipboard(item)
        NotificationCenter.default.post(name: .islandCollapse, object: nil)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            _ = FlowPaste.insert(item.text)
        }
    }

    // MARK: - Persistence

    private func save() {
        let url = Self.fileURL
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func load() {
        let url = Self.fileURL
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else {
            return
        }
        self.items = decoded
    }
}
