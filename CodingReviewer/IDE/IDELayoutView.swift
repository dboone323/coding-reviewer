//
//  IDELayoutView.swift
//  CodingReviewer
//
//  Main IDE layout: file tree | editor+tabs | right panel | bottom panel
//

import SwiftUI

/// Panel visibility state for the IDE layout
@MainActor
@Observable
public final class IDEPanelState {
    public var showFileTree: Bool = true
    public var showRightPanel: Bool = true
    public var showBottomPanel: Bool = false
    public var rightPanelTab: RightPanelTab = .chat
    public var bottomPanelTab: BottomPanelTab = .terminal

    public enum RightPanelTab: String, CaseIterable {
        case sourceControl = "Source Control"
        case chat = "Chat"
        case agents = "Agents"
        case github = "GitHub"
        case review = "Review"
    }

    public enum BottomPanelTab: String, CaseIterable {
        case terminal = "Terminal"
        case output = "Output"
        case problems = "Problems"
    }
}

/// Main IDE layout view
public struct IDELayoutView: View {
    @State var editorVM = EditorViewModel()
    @State var panelState = IDEPanelState()
    @State var chatVM = ChatViewModel()
    @State var sourceControlVM = SourceControlViewModel()
    @State var githubVM = GitHubPanelViewModel()

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            IDEToolbar(
                panelState: panelState,
                editorVM: editorVM,
                chatVM: chatVM
            )

            Divider()

            // Main content area
            HSplitView {
                // Left: File Tree
                if panelState.showFileTree {
                    FileTreeView(viewModel: editorVM)
                        .frame(minWidth: 180, idealWidth: 240, maxWidth: 350)
                }

                // Center: Editor
                EditorPaneView(viewModel: editorVM)
                    .frame(minWidth: 400)

                // Right: Chat / Agents / GitHub / Review
                if panelState.showRightPanel {
                    RightPanel(
                        panelState: panelState,
                        chatVM: chatVM,
                        editorVM: editorVM,
                        sourceControlVM: sourceControlVM,
                        githubVM: githubVM
                    )
                    .frame(minWidth: 280, idealWidth: 340, maxWidth: 500)
                }
            }

            // Bottom panel (terminal/output) - placeholder for Phase 4
            if panelState.showBottomPanel {
                Divider()
                BottomPanel(panelState: panelState)
                    .frame(minHeight: 120, idealHeight: 200, maxHeight: 400)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .focusable()
    }
}

/// IDE toolbar with panel toggles and actions
struct IDEToolbar: View {
    @Bindable var panelState: IDEPanelState
    @Bindable var editorVM: EditorViewModel
    @Bindable var chatVM: ChatViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Panel toggles
            ToolbarToggle(
                icon: "sidebar.leading",
                isActive: panelState.showFileTree,
                help: "Toggle File Tree"
            ) {
                panelState.showFileTree.toggle()
            }

            Divider().frame(height: 18)

            // Project name
            if let root = editorVM.projectRootURL {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))
                    Text(root.lastPathComponent)
                        .font(.system(size: 12, weight: .medium))
                }
            }

            Spacer()

            // Chat mode indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(chatVM.isConnected ? .green : .red)
                    .frame(width: 6, height: 6)
                Text(chatVM.currentMode.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Divider().frame(height: 18)

            // Right panel toggles
            ToolbarToggle(
                icon: "bubble.left.and.bubble.right",
                isActive: panelState.showRightPanel && panelState.rightPanelTab == .chat,
                help: "Toggle Chat"
            ) {
                if panelState.showRightPanel && panelState.rightPanelTab == .chat {
                    panelState.showRightPanel = false
                } else {
                    panelState.showRightPanel = true
                    panelState.rightPanelTab = .chat
                }
            }

            ToolbarToggle(
                icon: "terminal",
                isActive: panelState.showBottomPanel,
                help: "Toggle Terminal"
            ) {
                panelState.showBottomPanel.toggle()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// Reusable toolbar toggle button
struct ToolbarToggle: View {
    let icon: String
    let isActive: Bool
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isActive ? .primary : .tertiary)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}

/// Right panel with tabbed content
struct RightPanel: View {
    @Bindable var panelState: IDEPanelState
    @Bindable var chatVM: ChatViewModel
    @Bindable var editorVM: EditorViewModel
    @Bindable var sourceControlVM: SourceControlViewModel
    @Bindable var githubVM: GitHubPanelViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                ForEach(IDEPanelState.RightPanelTab.allCases, id: \.self) { tab in
                    PanelTabButton(
                        title: tab.rawValue,
                        isActive: panelState.rightPanelTab == tab
                    ) {
                        panelState.rightPanelTab = tab
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)

            Divider()

            // Tab content
            switch panelState.rightPanelTab {
            case .sourceControl:
                SourceControlView(viewModel: sourceControlVM)
            case .chat:
                ChatView(viewModel: chatVM, editorVM: editorVM)
            case .agents:
                AgentsPlaceholderView()
            case .github:
                GitHubPanelView(viewModel: githubVM)
            case .review:
                ReviewPanelView()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

/// Tab button for panel sections
struct PanelTabButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .primary : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isActive ? Color.accentColor.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}

/// Bottom panel placeholder
struct BottomPanel: View {
    @Bindable var panelState: IDEPanelState

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(IDEPanelState.BottomPanelTab.allCases, id: \.self) { tab in
                    PanelTabButton(
                        title: tab.rawValue,
                        isActive: panelState.bottomPanelTab == tab
                    ) {
                        panelState.bottomPanelTab = tab
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Divider()

            // Placeholder for terminal (Phase 4)
            Text("Terminal coming in Phase 4")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}

/// Placeholder views for future panels

struct AgentsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "cpu")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Docker Agents")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Agent management coming in Phase 5")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct GitHubPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("GitHub Integration")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Source control coming in Phase 3")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

/// Review panel - existing code review functionality as a panel
struct ReviewPanelView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Code Review")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Run analysis on the active file")
                .font(.caption)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 8) {
                ReviewActionButton(title: "Analyze Code", icon: "wand.and.stars", color: .blue)
                ReviewActionButton(title: "Generate Tests", icon: "testtube.2", color: .green)
                ReviewActionButton(title: "Generate Docs", icon: "doc.text", color: .orange)
                ReviewActionButton(title: "Security Scan", icon: "shield.checkered", color: .red)
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReviewActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 12))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
