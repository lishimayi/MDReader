import MarkdownUI
import SwiftUI

struct MarkdownReaderView: View {
    @ObservedObject var viewModel: ReaderViewModel

    var body: some View {
        ScrollViewReader { proxy in
            HSplitView {
                documentScrollView
                OutlineView(
                    headings: viewModel.parsedDocument.headings,
                    activeHeadingID: viewModel.activeHeadingID
                ) { heading in
                    viewModel.activeHeadingID = heading.id
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(heading.id, anchor: .top)
                    }
                }
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 360, maxHeight: .infinity)
            }
        }
    }

    private var documentScrollView: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 0) {
                Spacer(minLength: 24)
                VStack(alignment: .leading, spacing: 0) {
                    if !viewModel.parsedDocument.preamble.isEmpty {
                        markdown(viewModel.parsedDocument.preamble)
                            .padding(.bottom, 18)
                    }

                    ForEach(viewModel.parsedDocument.sections) { section in
                        VStack(alignment: .leading, spacing: 0) {
                            markdown(section.markdown)
                                .id("render-\(section.id)-\(imageReloadToken)")
                        }
                        .id(section.id)
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: HeadingPositionsPreferenceKey.self,
                                    value: [
                                        section.id: geometry.frame(in: .named("markdownScroll")).minY
                                    ]
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: 860, alignment: .leading)
                .padding(.vertical, 36)
                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity)
        }
        .coordinateSpace(name: "markdownScroll")
        .onPreferenceChange(HeadingPositionsPreferenceKey.self) { positions in
            let resolved = ActiveHeadingResolver.resolve(
                headings: viewModel.parsedDocument.headings,
                positions: positions,
                threshold: 48
            )
            if viewModel.activeHeadingID != resolved {
                viewModel.activeHeadingID = resolved
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var imageReloadToken: String {
        viewModel.imageFolderURL?.path ?? "restricted"
    }

    private func markdown(_ source: String) -> some View {
        Markdown(source, baseURL: viewModel.imageBaseURL, imageBaseURL: viewModel.imageBaseURL)
            .markdownTheme(.gitHub)
            .markdownImageProvider(ReaderImageProvider())
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HeadingPositionsPreferenceKey: PreferenceKey {
    static var defaultValue: [MarkdownHeading.ID: CGFloat] = [:]

    static func reduce(
        value: inout [MarkdownHeading.ID: CGFloat],
        nextValue: () -> [MarkdownHeading.ID: CGFloat]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
    }
}
