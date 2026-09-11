import XCTest
@testable import MDReader

final class ImageSourceResolverTests: XCTestCase {
    func testClassifiesFileURLAsLocal() {
        let url = URL(fileURLWithPath: "/tmp/image.png")

        XCTAssertEqual(ImageSourceResolver.resolve(url), .local(url))
    }

    func testClassifiesHTTPSURLAsRemote() {
        let url = URL(string: "https://example.com/image.png")!

        XCTAssertEqual(ImageSourceResolver.resolve(url), .remote(url))
    }

    func testRejectsMissingAndUnsupportedURLs() {
        XCTAssertEqual(ImageSourceResolver.resolve(nil), .invalid)
        XCTAssertEqual(ImageSourceResolver.resolve(URL(string: "ftp://example.com/image.png")), .invalid)
    }
}
