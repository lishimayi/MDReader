import XCTest
@testable import MDReader

final class FolderAuthorizationPolicyTests: XCTestCase {
    func testAcceptsDocumentDirectory() {
        let document = URL(fileURLWithPath: "/Users/example/Notes/readme.md")
        let folder = URL(fileURLWithPath: "/Users/example/Notes", isDirectory: true)

        XCTAssertTrue(FolderAuthorizationPolicy.isValidSelection(folder, forDocumentAt: document))
    }

    func testAcceptsAncestorDirectory() {
        let document = URL(fileURLWithPath: "/Users/example/Notes/Project/readme.md")
        let folder = URL(fileURLWithPath: "/Users/example/Notes", isDirectory: true)

        XCTAssertTrue(FolderAuthorizationPolicy.isValidSelection(folder, forDocumentAt: document))
    }

    func testRejectsUnrelatedDirectoryWithSimilarPrefix() {
        let document = URL(fileURLWithPath: "/Users/example/Notes-Archive/readme.md")
        let folder = URL(fileURLWithPath: "/Users/example/Notes", isDirectory: true)

        XCTAssertFalse(FolderAuthorizationPolicy.isValidSelection(folder, forDocumentAt: document))
    }
}
