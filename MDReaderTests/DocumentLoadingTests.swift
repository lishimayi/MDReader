import XCTest
@testable import MDReader

final class DocumentLoadingTests: XCTestCase {
    func testDecodesUTF8WithByteOrderMark() throws {
        let data = Data([0xEF, 0xBB, 0xBF]) + Data("# Hello".utf8)

        XCTAssertEqual(try MarkdownTextDecoder.decode(data), "# Hello")
    }

    func testDecodesUTF16LittleEndianWithByteOrderMark() throws {
        let body = "# 你好".data(using: .utf16LittleEndian)!
        let data = Data([0xFF, 0xFE]) + body

        XCTAssertEqual(try MarkdownTextDecoder.decode(data), "# 你好")
    }

    func testRejectsUnsupportedBytes() {
        XCTAssertThrowsError(try MarkdownTextDecoder.decode(Data([0xFF, 0xFF, 0xFF])))
    }

    @MainActor
    func testFailedLoadKeepsPreviouslyLoadedDocument() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let validURL = directory.appendingPathComponent("valid.md")
        try Data("# Loaded".utf8).write(to: validURL)
        let missingURL = directory.appendingPathComponent("missing.md")
        let viewModel = ReaderViewModel(folderStore: SecurityScopedFolderStore(defaults: nil))

        viewModel.loadDocument(at: validURL)
        viewModel.loadDocument(at: missingURL)

        XCTAssertEqual(viewModel.documentURL, validURL)
        XCTAssertEqual(viewModel.parsedDocument.headings.first?.title, "Loaded")
        XCTAssertNotNil(viewModel.alert)
    }
}
