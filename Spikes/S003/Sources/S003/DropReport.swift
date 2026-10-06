import AppKit

/// Summarises a drop by type identifiers and counts only, and keeps bookmarks in memory.
/// Never prints names, paths or content, and never reads file contents.
@MainActor
final class DropReport {
    private var bookmarks: [Data] = []

    func describe(_ info: NSDraggingInfo) -> String {
        let pasteboard = info.draggingPasteboard
        let items = pasteboard.pasteboardItems ?? []
        var typeCounts: [String: Int] = [:]
        for item in items {
            for type in item.types { typeCounts[type.rawValue, default: 0] += 1 }
        }
        let types = typeCounts.sorted { $0.key < $1.key }.map { "\($0.key)x\($0.value)" }.joined(separator: " ")

        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        var files = 0
        var folders = 0
        for url in urls {
            let isFolder = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isFolder { folders += 1 } else { files += 1 }
        }
        return "items=\(items.count) fileURLs=\(urls.count) files=\(files) folders=\(folders) types=[\(types)]"
    }

    /// Creates bookmark data for each dropped file URL. Prints success and byte size only.
    func storeBookmarks(_ info: NSDraggingInfo) {
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        for url in urls {
            do {
                let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
                bookmarks.append(data)
                Log.line("bookmark #\(bookmarks.count - 1) created: \(data.count) bytes")
            } catch {
                Log.line("bookmark create failed: \((error as NSError).code)")
            }
        }
    }

    /// Resolves every stored bookmark. Prints index, ok or failure, and the stale flag only.
    func resolveAll() {
        Log.line("resolving \(bookmarks.count) bookmarks")
        for (index, data) in bookmarks.enumerated() {
            var stale = false
            do {
                let url = try URL(resolvingBookmarkData: data, options: [.withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
                let exists = FileManager.default.fileExists(atPath: url.path)
                Log.line("bookmark #\(index): resolved, stale=\(stale), target exists=\(exists)")
            } catch {
                Log.line("bookmark #\(index): resolve failed, error code \((error as NSError).code)")
            }
        }
    }
}
