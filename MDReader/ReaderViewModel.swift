import AppKit
import Combine
import UniformTypeIdentifiers

struct ReaderAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var documentURL: URL?
    @Published private(set) var parsedDocument = ParsedMarkdown.empty
    @Published private(set) var imageFolderURL: URL?
    @Published var activeHeadingID: MarkdownHeading.ID?
    @Published var alert: ReaderAlert?
    @Published var isImagePermissionBannerDismissed = false

    private let parser: MarkdownDocumentParser
    private let fileLoader: MarkdownFileLoader
    private let folderStore: SecurityScopedFolderStore
    private var didStartImageFolderAccess = false

    init(
        parser: MarkdownDocumentParser = MarkdownDocumentParser(),
        fileLoader: MarkdownFileLoader = MarkdownFileLoader(),
        folderStore: SecurityScopedFolderStore = SecurityScopedFolderStore()
    ) {
        self.parser = parser
        self.fileLoader = fileLoader
        self.folderStore = folderStore
    }

    var hasDocument: Bool { documentURL != nil }

    var documentTitle: String {
        documentURL?.lastPathComponent ?? "MDReader"
    }

    var imageBaseURL: URL? {
        documentURL?.deletingLastPathComponent()
    }

    var shouldShowImagePermissionBanner: Bool {
        hasDocument
            && !parsedDocument.relativeImagePaths.isEmpty
            && imageFolderURL == nil
            && !isImagePermissionBannerDismissed
    }

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "打开 Markdown 文档"
        panel.prompt = "打开"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = markdownContentTypes

        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadDocument(at: url)
    }

    func loadDocument(at url: URL) {
        let didStartDocumentAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartDocumentAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let source = try fileLoader.load(from: url)
            let parsed = parser.parse(source)

            stopImageFolderAccess()
            documentURL = url
            parsedDocument = parsed
            activeHeadingID = parsed.headings.first?.id
            isImagePermissionBannerDismissed = false
            alert = nil

            if let savedFolder = folderStore.authorizedFolder(for: url) {
                activateImageFolder(savedFolder)
            }
        } catch {
            alert = ReaderAlert(
                title: "无法打开文档",
                message: error.localizedDescription
            )
        }
    }

    func grantImageFolderAccess() {
        guard let documentURL else { return }

        let panel = NSOpenPanel()
        panel.title = "授权图片所在文件夹"
        panel.message = "请选择包含当前 Markdown 文档的文件夹或其父文件夹。"
        panel.prompt = "授权"
        panel.directoryURL = documentURL.deletingLastPathComponent()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let folderURL = panel.url else { return }
        guard FolderAuthorizationPolicy.isValidSelection(folderURL, forDocumentAt: documentURL) else {
            alert = ReaderAlert(
                title: "文件夹不匹配",
                message: "请选择包含 \(documentURL.lastPathComponent) 的文件夹或其父文件夹。"
            )
            return
        }

        do {
            try folderStore.save(folderURL)
            stopImageFolderAccess()
            activateImageFolder(folderURL)
            isImagePermissionBannerDismissed = false
        } catch {
            alert = ReaderAlert(title: "无法保存授权", message: error.localizedDescription)
        }
    }

    func dismissImagePermissionBanner() {
        isImagePermissionBannerDismissed = true
    }

    func clearAlert() {
        alert = nil
    }

    private var markdownContentTypes: [UTType] {
        ["md", "markdown"].compactMap { UTType(filenameExtension: $0) }
    }

    private func activateImageFolder(_ url: URL) {
        let started = url.startAccessingSecurityScopedResource()
        let isReadable = FileManager.default.isReadableFile(atPath: url.path)
        guard started || isReadable else { return }

        imageFolderURL = url
        didStartImageFolderAccess = started
    }

    private func stopImageFolderAccess() {
        if didStartImageFolderAccess {
            imageFolderURL?.stopAccessingSecurityScopedResource()
        }
        imageFolderURL = nil
        didStartImageFolderAccess = false
    }
}
