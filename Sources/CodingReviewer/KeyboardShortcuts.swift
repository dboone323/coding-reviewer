import SwiftUI

enum CodingReviewerKeyboardShortcuts {
    static let analyze = KeyboardShortcut("r", modifiers: [.command, .shift])
    static let documentation = KeyboardShortcut("d", modifiers: [.command, .shift])
    static let tests = KeyboardShortcut("t", modifiers: [.command, .shift])
}
