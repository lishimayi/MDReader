import XCTest
@testable import MDReader

final class ActiveHeadingResolverTests: XCTestCase {
    private let headings = [
        MarkdownHeading(id: "one", title: "One", level: 1, order: 0),
        MarkdownHeading(id: "two", title: "Two", level: 2, order: 1),
        MarkdownHeading(id: "three", title: "Three", level: 2, order: 2),
    ]

    func testReturnsFirstHeadingBeforeAnyHeadingCrossesThreshold() {
        let result = ActiveHeadingResolver.resolve(
            headings: headings,
            positions: ["one": 120, "two": 420, "three": 800],
            threshold: 48
        )

        XCTAssertEqual(result, "one")
    }

    func testReturnsLastHeadingThatCrossedThreshold() {
        let result = ActiveHeadingResolver.resolve(
            headings: headings,
            positions: ["one": -300, "two": 20, "three": 600],
            threshold: 48
        )

        XCTAssertEqual(result, "two")
    }

    func testReturnsNilWithoutHeadings() {
        XCTAssertNil(ActiveHeadingResolver.resolve(headings: [], positions: [:], threshold: 48))
    }
}
