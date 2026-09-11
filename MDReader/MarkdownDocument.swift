import Foundation

struct MarkdownHeading: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let level: Int
    let order: Int
}

struct MarkdownSection: Identifiable, Equatable, Sendable {
    let id: String
    let heading: MarkdownHeading
    let markdown: String
}

struct ParsedMarkdown: Equatable, Sendable {
    let preamble: String
    let sections: [MarkdownSection]
    let headings: [MarkdownHeading]
    let relativeImagePaths: [String]

    static let empty = ParsedMarkdown(
        preamble: "",
        sections: [],
        headings: [],
        relativeImagePaths: []
    )
}
