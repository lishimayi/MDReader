import CoreGraphics

enum ActiveHeadingResolver {
    static func resolve(
        headings: [MarkdownHeading],
        positions: [MarkdownHeading.ID: CGFloat],
        threshold: CGFloat
    ) -> MarkdownHeading.ID? {
        guard let first = headings.first else { return nil }

        return headings
            .compactMap { heading -> (MarkdownHeading.ID, CGFloat)? in
                guard let position = positions[heading.id], position <= threshold else { return nil }
                return (heading.id, position)
            }
            .max(by: { $0.1 < $1.1 })?
            .0 ?? first.id
    }
}
