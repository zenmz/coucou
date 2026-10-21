import Foundation

// MARK: - Test Stubs for Standalone Execution

#if !NOTCHBUDDY_APP
enum HookServer {
    static var supportDir: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("NotchBuddyTest")
    }
}

enum FlowPaste {
    @MainActor static func insert(_ text: String) -> Bool {
        return true
    }
}

extension Notification.Name {
    static let islandCollapse = Notification.Name("notchBuddy.islandCollapse")
}
#endif

// MARK: - ClipboardTests

@main
enum ClipboardTests {
    @MainActor
    static func main() {
        testItemModel()
        testItemPreviewAndMetrics()
        testTimeAgoCalculations()
        testStoreAddAndDeduplicate()
        testStorePinning()
        testStoreFiltering()
        testStoreClearAll()
        print("ClipboardManager: all unit tests passed successfully!")
    }

    static func testItemModel() {
        let id = UUID()
        let now = Date()
        let item = ClipboardItem(id: id, text: "Hello World", copiedAt: now, sourceApp: "Xcode", isPinned: false)
        precondition(item.id == id)
        precondition(item.text == "Hello World")
        precondition(item.sourceApp == "Xcode")
        precondition(!item.isPinned)
    }

    static func testItemPreviewAndMetrics() {
        let multiline = "Line 1\nLine 2\nLine 3"
        let item = ClipboardItem(text: multiline)
        precondition(item.charCount == multiline.count)
        precondition(item.lineCount == 3)
        precondition(item.previewText == "Line 1 Line 2")
    }

    static func testTimeAgoCalculations() {
        let justNow = ClipboardItem(text: "Test", copiedAt: Date())
        precondition(justNow.timeAgo == "just now" || justNow.timeAgo.hasSuffix("s ago"))

        let tenMinsAgo = ClipboardItem(text: "Test", copiedAt: Date().addingTimeInterval(-600))
        precondition(tenMinsAgo.timeAgo == "10m ago")

        let twoHoursAgo = ClipboardItem(text: "Test", copiedAt: Date().addingTimeInterval(-7200))
        precondition(twoHoursAgo.timeAgo == "2h ago")
    }

    @MainActor
    static func testStoreAddAndDeduplicate() {
        let store = ClipboardStore.shared
        store.clearAll()
        while !store.items.isEmpty {
            store.delete(id: store.items[0].id)
        }

        store.add("First text", sourceApp: "Safari")
        precondition(store.items.count == 1)
        precondition(store.items[0].text == "First text")
        precondition(store.items[0].sourceApp == "Safari")

        // Adding exact duplicate should bump it, not duplicate
        store.add("First text", sourceApp: "Safari")
        precondition(store.items.count == 1)

        // Adding a second distinct item
        store.add("Second text", sourceApp: "VS Code")
        precondition(store.items.count == 2)
        precondition(store.items[0].text == "Second text")
        precondition(store.items[1].text == "First text")
    }

    @MainActor
    static func testStorePinning() {
        let store = ClipboardStore.shared
        store.clearAll()
        while !store.items.isEmpty {
            store.delete(id: store.items[0].id)
        }

        store.add("Item A")
        store.add("Item B")

        let itemAId = store.items.first(where: { $0.text == "Item A" })!.id
        store.togglePin(id: itemAId)

        // Filtered list should place pinned items at top
        let filtered = store.filteredItems
        precondition(filtered.first?.text == "Item A", "Pinned item must be at top of filtered list")
        precondition(filtered.first?.isPinned == true)
    }

    @MainActor
    static func testStoreFiltering() {
        let store = ClipboardStore.shared
        store.clearAll()
        while !store.items.isEmpty {
            store.delete(id: store.items[0].id)
        }

        store.add("Apple swift code")
        store.add("Banana fruit")
        store.add("Cherry cake")

        store.searchQuery = "swift"
        precondition(store.filteredItems.count == 1)
        precondition(store.filteredItems[0].text == "Apple swift code")

        store.searchQuery = "fruit"
        precondition(store.filteredItems.count == 1)
        precondition(store.filteredItems[0].text == "Banana fruit")

        store.searchQuery = "nonexistent"
        precondition(store.filteredItems.isEmpty)

        store.searchQuery = ""
        precondition(store.filteredItems.count == 3)
    }

    @MainActor
    static func testStoreClearAll() {
        let store = ClipboardStore.shared
        store.clearAll()
        while !store.items.isEmpty {
            store.delete(id: store.items[0].id)
        }

        store.add("Keep this pinned")
        store.add("Delete this unpinned")

        let pinnedId = store.items.first(where: { $0.text == "Keep this pinned" })!.id
        store.togglePin(id: pinnedId)

        store.clearAll()
        precondition(store.items.count == 1, "clearAll should retain pinned items")
        precondition(store.items[0].text == "Keep this pinned")
    }
}
