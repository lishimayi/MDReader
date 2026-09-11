import SwiftUI

struct OpenMarkdownAction {
    let perform: () -> Void

    func callAsFunction() {
        perform()
    }
}

private struct OpenMarkdownActionKey: FocusedValueKey {
    typealias Value = OpenMarkdownAction
}

extension FocusedValues {
    var openMarkdownDocument: OpenMarkdownAction? {
        get { self[OpenMarkdownActionKey.self] }
        set { self[OpenMarkdownActionKey.self] = newValue }
    }
}

struct OpenDocumentCommands: Commands {
    @FocusedValue(\.openMarkdownDocument) private var openMarkdownDocument

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("打开…") {
                openMarkdownDocument?()
            }
            .keyboardShortcut("o", modifiers: .command)
            .disabled(openMarkdownDocument == nil)
        }
    }
}
