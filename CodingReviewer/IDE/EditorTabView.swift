//
//  EditorTabView.swift
//  CodingReviewer
//
//  Tabbed code editor using TextEditor (CodeEditSourceEditor integration pending)
//

import SwiftUI

/// Tab bar showing all open files
public struct EditorTabBar: View {
    @Bindable var viewModel: EditorViewModel

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.openFiles) { file in
                    EditorTab(
                        file: file,
                        isActive: file.id == viewModel.activeFileID,
                        onSelect: { viewModel.selectTab(id: file.id) },
                        onClose: { viewModel.closeFile(id: file.id) }
                    )
                }
            }
        }
        .frame(height: 32)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// Individual tab for an open file
struct EditorTab: View {
    let file: OpenFile
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            // Modified indicator
            if file.isModified {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            }

            Text(file.filename)
                .font(.system(size: 11))
                .lineLimit(1)

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.borderless)
            .opacity(isHovering || isActive ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        .overlay(alignment: .bottom) {
            if isActive {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button("Close") { onClose() }
            Button("Close Others") {
                // Close all tabs except this one
                let otherIDs = viewModel.openFiles.filter { $0.id != file.id }.map(\.id)
                for id in otherIDs {
                    viewModel.closeFile(id: id)
                }
            }
            Button("Close All") { viewModel.closeAllFiles() }
            Divider()
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: "")
            }
        }
    }

    @Bindable private var viewModel = EditorViewModel()
}

/// The main code editor pane with tabs
public struct EditorPaneView: View {
    @Bindable var viewModel: EditorViewModel

    @AppStorage("CR_EDITOR_FONT_SIZE") private var fontSize: Double = 13
    @AppStorage("CR_EDITOR_SHOW_LINE_NUMBERS") private var showLineNumbers: Bool = true
    @AppStorage("CR_EDITOR_WORD_WRAP") private var wordWrap: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            EditorTabBar(viewModel: viewModel)

            Divider()

            if let activeIndex = viewModel.activeFileIndex {
                let binding = Binding<String>(
                    get: { viewModel.openFiles[activeIndex].content },
                    set: { newValue in
                        viewModel.updateContent(newValue, for: viewModel.openFiles[activeIndex].id)
                    }
                )

                // TODO: Integrate CodeEditSourceEditor properly with SourceEditorState/Configuration
                // For now using basic TextEditor as placeholder
                TextEditor(text: binding)
                    .font(.system(size: fontSize, design: .monospaced))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(viewModel.openFiles[activeIndex].id)

                // Status bar
                EditorStatusBar(
                    file: viewModel.openFiles[activeIndex],
                    lineCount: binding.wrappedValue.components(separatedBy: .newlines).count
                )
            } else {
                // No file open - show welcome
                WelcomePanel()
            }
        }
    }
}

/// Status bar at the bottom of the editor
struct EditorStatusBar: View {
    let file: OpenFile
    let lineCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(lineCount) lines")
                .font(.system(size: 11, design: .monospaced))

            Spacer()

            Text(file.language.capitalized)
                .font(.system(size: 11))

            Text("UTF-8")
                .font(.system(size: 11))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// Welcome panel when no files are open
struct WelcomePanel: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "curlybraces")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)

            Text("CodingReviewer IDE")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                KeyboardShortcutHint(keys: "⌘O", description: "Open File")
                KeyboardShortcutHint(keys: "⌘⇧O", description: "Open Folder")
                KeyboardShortcutHint(keys: "⌘N", description: "New File")
                KeyboardShortcutHint(keys: "⌘⇧P", description: "Command Palette")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

struct KeyboardShortcutHint: View {
    let keys: String
    let description: String

    var body: some View {
        HStack(spacing: 8) {
            Text(keys)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}
