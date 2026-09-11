import SwiftUI

struct ImagePermissionBanner: View {
    let grantAccess: () -> Void
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .foregroundStyle(.secondary)

            Text("此文档包含本地图片，请授权所在文件夹以显示图片。")
                .font(.callout)

            Spacer(minLength: 16)

            Button("授权文件夹", action: grantAccess)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            Button(action: dismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("关闭图片授权提示")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
