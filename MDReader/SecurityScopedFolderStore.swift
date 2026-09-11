import Foundation

enum FolderAuthorizationPolicy {
    static func isValidSelection(_ folderURL: URL, forDocumentAt documentURL: URL) -> Bool {
        let folderComponents = normalized(folderURL).pathComponents
        let documentDirectoryComponents = normalized(documentURL.deletingLastPathComponent()).pathComponents

        guard folderComponents.count <= documentDirectoryComponents.count else { return false }
        return zip(folderComponents, documentDirectoryComponents).allSatisfy(==)
    }

    private static func normalized(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }
}

final class SecurityScopedFolderStore {
    private let defaults: UserDefaults?
    private let storageKey = "authorizedMarkdownImageFolders"

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
    }

    func authorizedFolder(for documentURL: URL) -> URL? {
        guard let defaults,
              let storedBookmarks = defaults.array(forKey: storageKey) as? [Data]
        else { return nil }

        var validBookmarks: [Data] = []
        var matchingFolder: URL?

        for data in storedBookmarks {
            var isStale = false
            guard let folderURL = try? URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), !isStale else { continue }

            validBookmarks.append(data)
            if matchingFolder == nil,
               FolderAuthorizationPolicy.isValidSelection(folderURL, forDocumentAt: documentURL) {
                matchingFolder = folderURL
            }
        }

        if validBookmarks.count != storedBookmarks.count {
            defaults.set(validBookmarks, forKey: storageKey)
        }
        return matchingFolder
    }

    func save(_ folderURL: URL) throws {
        guard let defaults else { return }
        let data = try folderURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        var bookmarks = defaults.array(forKey: storageKey) as? [Data] ?? []
        if !bookmarks.contains(data) {
            bookmarks.append(data)
            defaults.set(bookmarks, forKey: storageKey)
        }
    }
}
