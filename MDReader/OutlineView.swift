import SwiftUI

struct OutlineView: View {
    let headings: [MarkdownHeading]
    let activeHeadingID: MarkdownHeading.ID?
    let onSelect: (MarkdownHeading) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("目录")
                    .font(.headline)
                Spacer()
                if !headings.isEmpty {
                    Text("\(headings.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            if headings.isEmpty {
                ContentUnavailableView(
                    "未检测到标题",
                    systemImage: "list.bullet.indent",
                    description: Text("文档仍可正常阅读")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(headings) { heading in
                            Button {
                                onSelect(heading)
                            } label: {
                                HStack(spacing: 8) {
                                    Capsule()
                                        .fill(heading.id == activeHeadingID ? Color.accentColor : .clear)
                                        .frame(width: 3)

                                    Text(heading.title.isEmpty ? "未命名标题" : heading.title)
                                        .font(.callout)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(heading.id == activeHeadingID ? Color.accentColor : .primary)
                                .padding(.leading, CGFloat(heading.level - 1) * 12)
                                .padding(.trailing, 10)
                                .padding(.vertical, 6)
                                .background(
                                    heading.id == activeHeadingID ? Color.accentColor.opacity(0.1) : .clear,
                                    in: RoundedRectangle(cornerRadius: 7)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("H\(heading.level)，\(heading.title)")
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
