import Foundation

struct MarkdownDocumentParser {
    func parse(_ source: String) -> ParsedMarkdown {
        let lines = source.components(separatedBy: "\n")
        let candidates = findHeadings(in: lines)
        var slugCounts: [String: Int] = [:]

        let locatedHeadings = candidates.enumerated().map { order, candidate in
            let baseSlug = slug(for: candidate.title)
            let count = slugCounts[baseSlug, default: 0] + 1
            slugCounts[baseSlug] = count
            let identifier = count == 1 ? baseSlug : "\(baseSlug)-\(count)"

            return LocatedHeading(
                heading: MarkdownHeading(
                    id: identifier,
                    title: candidate.title,
                    level: candidate.level,
                    order: order
                ),
                startLine: candidate.startLine
            )
        }

        let preamble: String
        if let firstHeading = locatedHeadings.first {
            preamble = lines[..<firstHeading.startLine].joined(separator: "\n")
        } else {
            preamble = source
        }

        let sections = locatedHeadings.enumerated().map { index, located in
            let endLine = index + 1 < locatedHeadings.count
                ? locatedHeadings[index + 1].startLine
                : lines.count
            let markdown = lines[located.startLine..<endLine].joined(separator: "\n")
            return MarkdownSection(id: located.heading.id, heading: located.heading, markdown: markdown)
        }

        return ParsedMarkdown(
            preamble: preamble,
            sections: sections,
            headings: locatedHeadings.map(\.heading),
            relativeImagePaths: relativeImagePaths(in: source)
        )
    }

    private func findHeadings(in lines: [String]) -> [HeadingCandidate] {
        var headings: [HeadingCandidate] = []
        var activeFence: Fence?

        for index in lines.indices {
            let line = lines[index]

            if let fence = fenceMarker(in: line) {
                if let currentFence = activeFence {
                    if fence.character == currentFence.character, fence.length >= currentFence.length {
                        activeFence = nil
                    }
                } else {
                    activeFence = fence
                }
                continue
            }

            guard activeFence == nil else { continue }

            if let atx = atxHeading(in: line) {
                headings.append(HeadingCandidate(title: atx.title, level: atx.level, startLine: index))
                continue
            }

            guard index > 0,
                  let level = setextLevel(for: line),
                  !lines[index - 1].trimmingCharacters(in: .whitespaces).isEmpty,
                  atxHeading(in: lines[index - 1]) == nil,
                  headings.last?.startLine != index - 1
            else { continue }

            headings.append(
                HeadingCandidate(
                    title: lines[index - 1].trimmingCharacters(in: .whitespaces),
                    level: level,
                    startLine: index - 1
                )
            )
        }

        return headings.sorted { $0.startLine < $1.startLine }
    }

    private func atxHeading(in line: String) -> (title: String, level: Int)? {
        let trimmed = line.drop(while: { $0 == " " })
        guard line.count - trimmed.count <= 3 else { return nil }

        let markerCount = trimmed.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(markerCount) else { return nil }

        let contentStart = trimmed.index(trimmed.startIndex, offsetBy: markerCount)
        let remainder = trimmed[contentStart...]
        guard remainder.isEmpty || remainder.first?.isWhitespace == true else { return nil }

        var title = remainder.trimmingCharacters(in: .whitespaces)
        if let closingRange = title.range(of: #"\s+#+\s*$"#, options: .regularExpression) {
            title.removeSubrange(closingRange)
        }
        return (title.trimmingCharacters(in: .whitespaces), markerCount)
    }

    private func setextLevel(for line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.allSatisfy({ $0 == "=" }) { return 1 }
        if trimmed.allSatisfy({ $0 == "-" }) { return 2 }
        return nil
    }

    private func fenceMarker(in line: String) -> Fence? {
        let trimmed = line.drop(while: { $0 == " " })
        guard line.count - trimmed.count <= 3, let character = trimmed.first,
              character == "`" || character == "~"
        else { return nil }

        let length = trimmed.prefix(while: { $0 == character }).count
        guard length >= 3 else { return nil }
        return Fence(character: character, length: length)
    }

    private func slug(for title: String) -> String {
        var result = ""
        var needsSeparator = false

        for scalar in title.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                if needsSeparator, !result.isEmpty { result.append("-") }
                result.unicodeScalars.append(scalar)
                needsSeparator = false
            } else if CharacterSet.whitespacesAndNewlines.contains(scalar) || scalar == "-" || scalar == "_" {
                needsSeparator = true
            }
        }

        return result.isEmpty ? "section" : result
    }

    private func relativeImagePaths(in source: String) -> [String] {
        let pattern = #"!\[[^\]]*\]\(\s*(?:<([^>]+)>|([^\s\)]+))"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let searchableSource = removingFencedCode(from: source)
        let nsSource = searchableSource as NSString
        let range = NSRange(location: 0, length: nsSource.length)
        var seen = Set<String>()
        var paths: [String] = []

        for match in regex.matches(in: searchableSource, range: range) {
            let capture = match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range(at: 2)
            guard capture.location != NSNotFound else { continue }
            let value = nsSource.substring(with: capture)
            guard isRelativeImagePath(value), seen.insert(value).inserted else { continue }
            paths.append(value)
        }

        return paths
    }

    private func removingFencedCode(from source: String) -> String {
        var activeFence: Fence?

        return source.components(separatedBy: "\n").map { line in
            if let fence = fenceMarker(in: line) {
                if let currentFence = activeFence {
                    if fence.character == currentFence.character, fence.length >= currentFence.length {
                        activeFence = nil
                    }
                } else {
                    activeFence = fence
                }
                return ""
            }
            return activeFence == nil ? line : ""
        }
        .joined(separator: "\n")
    }

    private func isRelativeImagePath(_ value: String) -> Bool {
        guard !value.hasPrefix("/"), !value.hasPrefix("#"),
              let components = URLComponents(string: value), components.scheme == nil
        else { return false }
        return true
    }
}

private struct HeadingCandidate {
    let title: String
    let level: Int
    let startLine: Int
}

private struct LocatedHeading {
    let heading: MarkdownHeading
    let startLine: Int
}

private struct Fence {
    let character: Character
    let length: Int
}
