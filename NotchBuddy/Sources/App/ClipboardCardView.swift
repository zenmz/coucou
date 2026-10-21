import SwiftUI
import AppKit

// MARK: - ClipboardCardView

struct ClipboardCardView: View {
    @ObservedObject private var store = ClipboardStore.shared
    @State private var hoveredItemId: UUID? = nil
    @State private var copiedItemId: UUID? = nil

    private let accentColor = Color(hex: "#38BDF8")

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 7, height: 7)
                Text(verbatim: "Clipboard")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#F5F6F8"))
                Text(verbatim: "\(store.items.count) clips")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#8E939C"))

                Spacer(minLength: 4)

                if !store.items.isEmpty {
                    Button(action: {
                        withAnimation { store.clearAll() }
                    }) {
                        Text(verbatim: "Clear")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#9398A1"))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                }
            }
            .padding(.top, 6)
            .padding(.leading, 108)
            .padding(.trailing, 36)

            // Search Bar
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#6B7079"))
                TextField(text: $store.searchQuery, prompt: Text(verbatim: "Search history…"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#E5E7EB"))
                if !store.searchQuery.isEmpty {
                    Button(action: { store.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#6B7079"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.leading, 108)
            .padding(.trailing, 36)

            // List of clips
            if store.filteredItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: store.searchQuery.isEmpty ? "No clips yet. Copy something with ⌘C." : "No clips matching '\(store.searchQuery)'.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#6B7079"))
                }
                .padding(.top, 4)
                .padding(.leading, 108)
                .padding(.trailing, 36)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.filteredItems) { item in
                            clipRow(for: item)
                        }
                    }
                    .padding(.leading, 108)
                    .padding(.trailing, 36)
                    .padding(.bottom, 6)
                }
                .frame(maxHeight: 180)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Row View

    @ViewBuilder
    private func clipRow(for item: ClipboardItem) -> some View {
        let isHovered = hoveredItemId == item.id
        let isCopied = copiedItemId == item.id

        VStack(alignment: .leading, spacing: 2) {
            // Meta bar: App + Time + Actions
            HStack(spacing: 4) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#FACC15"))
                }

                if let app = item.sourceApp {
                    Text(verbatim: app)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(Color(hex: "#9398A1"))
                        .lineLimit(1)
                }

                Text(verbatim: "· \(item.timeAgo)")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "#6B7079"))

                Spacer()

                // Actions (visible when hovered or on copy)
                if isCopied {
                    Text(verbatim: "Copied!")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: "#34D399"))
                } else if isHovered {
                    HStack(spacing: 6) {
                        // Toggle Pin
                        Button(action: {
                            withAnimation { store.togglePin(id: item.id) }
                        }) {
                            Image(systemName: item.isPinned ? "pin.slash" : "pin")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#9398A1"))
                        }
                        .buttonStyle(.plain)

                        // Copy only
                        Button(action: {
                            store.copyToClipboard(item)
                            copiedItemId = item.id
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                if copiedItemId == item.id { copiedItemId = nil }
                            }
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#9398A1"))
                        }
                        .buttonStyle(.plain)

                        // Delete
                        Button(action: {
                            withAnimation { store.delete(id: item.id) }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "#EF4444"))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Preview Text
            Text(verbatim: item.previewText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "#E5E7EB"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(item.isPinned ? Color(hex: "#FACC15").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { inside in
            hoveredItemId = inside ? item.id : nil
        }
        .onTapGesture {
            store.pasteDirectly(item)
        }
    }
}
