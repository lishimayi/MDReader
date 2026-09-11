import Foundation

enum MarkdownTextDecodingError: LocalizedError {
    case unsupportedEncoding

    var errorDescription: String? {
        "无法识别文档编码。请将文件保存为 UTF-8 或 UTF-16。"
    }
}

enum MarkdownTextDecoder {
    static func decode(_ data: Data) throws -> String {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            let content = data.dropFirst(3)
            guard let string = String(data: content, encoding: .utf8) else {
                throw MarkdownTextDecodingError.unsupportedEncoding
            }
            return string
        }

        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
            guard let string = String(data: data, encoding: .utf16) else {
                throw MarkdownTextDecodingError.unsupportedEncoding
            }
            return string
        }

        guard let string = String(data: data, encoding: .utf8) else {
            throw MarkdownTextDecodingError.unsupportedEncoding
        }
        return string
    }
}

struct MarkdownFileLoader {
    func load(from url: URL) throws -> String {
        try MarkdownTextDecoder.decode(Data(contentsOf: url))
    }
}
