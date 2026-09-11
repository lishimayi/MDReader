//
//  ContentView.swift
//  MDReader
//
//  Created by 郎震 on 2026/9/11.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReaderViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.shouldShowImagePermissionBanner {
                ImagePermissionBanner(
                    grantAccess: viewModel.grantImageFolderAccess,
                    dismiss: viewModel.dismissImagePermissionBanner
                )
            }

            if viewModel.hasDocument {
                MarkdownReaderView(viewModel: viewModel)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 760, minHeight: 500)
        .navigationTitle(viewModel.documentTitle)
        .toolbar {
            ToolbarItem {
                Button(action: viewModel.presentOpenPanel) {
                    Label("打开 Markdown", systemImage: "folder")
                }
                .help("打开 Markdown 文档 (⌘O)")
            }
        }
        .focusedSceneValue(
            \.openMarkdownDocument,
            OpenMarkdownAction(perform: viewModel.presentOpenPanel)
        )
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("好"), action: viewModel.clearAlert)
            )
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Markdown 阅读器", systemImage: "doc.richtext")
        } description: {
            Text("打开本地 Markdown 文档，使用右侧目录快速浏览章节。")
        } actions: {
            Button("打开 Markdown…", action: viewModel.presentOpenPanel)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
