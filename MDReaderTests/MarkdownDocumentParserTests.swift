import XCTest
@testable import MDReader

final class MarkdownDocumentParserTests: XCTestCase {
    private let parser = MarkdownDocumentParser()

    func testParsesATXHeadingsAndKeepsSectionMarkdown() {
        let source = """
        Intro

        # Overview
        Body

        ### Details ###
        More
        """

        let parsed = parser.parse(source)

        XCTAssertEqual(parsed.preamble, "Intro\n")
        XCTAssertEqual(parsed.headings.map(\.title), ["Overview", "Details"])
        XCTAssertEqual(parsed.headings.map(\.level), [1, 3])
        XCTAssertEqual(parsed.sections.map(\.id), ["overview", "details"])
        XCTAssertEqual(parsed.sections[0].markdown, "# Overview\nBody\n")
        XCTAssertEqual(parsed.sections[1].markdown, "### Details ###\nMore")
    }

    func testParsesSetextHeadings() {
        let parsed = parser.parse("Title\n=====\nBody\n\nSubsection\n---\nMore")

        XCTAssertEqual(parsed.headings.map(\.title), ["Title", "Subsection"])
        XCTAssertEqual(parsed.headings.map(\.level), [1, 2])
    }

    func testIgnoresHeadingSyntaxInsideFencedCodeBlocks() {
        let parsed = parser.parse("# Real\n```swift\n# Not a heading\n```\n## Also real")

        XCTAssertEqual(parsed.headings.map(\.title), ["Real", "Also real"])
    }

    func testCreatesUnicodeSlugsAndSuffixesDuplicates() {
        let parsed = parser.parse("# 快速开始\n## 快速开始\n# !!!")

        XCTAssertEqual(parsed.headings.map(\.id), ["快速开始", "快速开始-2", "section"])
    }

    func testDocumentWithoutHeadingsRemainsInPreamble() {
        let source = "Paragraph only.\n\n- Item"

        let parsed = parser.parse(source)

        XCTAssertEqual(parsed.preamble, source)
        XCTAssertTrue(parsed.headings.isEmpty)
        XCTAssertTrue(parsed.sections.isEmpty)
    }

    func testExtractsUniqueRelativeImagesOnly() {
        let source = """
        ![Local](images/cover.png)
        ![Remote](https://example.com/cover.png)
        ![Local again](images/cover.png)
        ![Absolute](/tmp/cover.png)
        """

        let parsed = parser.parse(source)

        XCTAssertEqual(parsed.relativeImagePaths, ["images/cover.png"])
    }

    func testIgnoresImageSyntaxInsideFencedCodeBlocks() {
        let source = """
        ```markdown
        ![Example](images/example.png)
        ```

        ![Real](images/real.png)
        """

        let parsed = parser.parse(source)

        XCTAssertEqual(parsed.relativeImagePaths, ["images/real.png"])
    }
}
