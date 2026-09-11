//
//  MDReaderApp.swift
//  MDReader
//
//  Created by 郎震 on 2026/9/11.
//

import SwiftUI

@main
struct MDReaderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1100, height: 760)
        .commands {
            OpenDocumentCommands()
        }
    }
}
