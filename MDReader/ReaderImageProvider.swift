import AppKit
import MarkdownUI
import SwiftUI

enum ResolvedImageSource: Equatable {
    case local(URL)
    case remote(URL)
    case invalid
}

enum ImageSourceResolver {
    static func resolve(_ url: URL?) -> ResolvedImageSource {
        guard let url else { return .invalid }
        if url.isFileURL { return .local(url) }
        if url.scheme == "http" || url.scheme == "https" { return .remote(url) }
        return .invalid
    }
}

struct ReaderImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        ReaderImage(source: ImageSourceResolver.resolve(url))
    }
}

private struct ReaderImage: View {
    let source: ResolvedImageSource

    @ViewBuilder
    var body: some View {
        switch source {
        case .local(let url):
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ImageFailurePlaceholder()
            }
        case .remote(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, minHeight: 72)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    ImageFailurePlaceholder()
                @unknown default:
                    ImageFailurePlaceholder()
                }
            }
        case .invalid:
            ImageFailurePlaceholder()
        }
    }
}

private struct ImageFailurePlaceholder: View {
    var body: some View {
        Label("图片无法加载", systemImage: "photo.badge.exclamationmark")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("图片无法加载")
    }
}
