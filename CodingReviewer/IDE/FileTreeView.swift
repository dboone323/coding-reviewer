//
//  FileTreeView.swift
//  CodingReviewer
//
//  Recursive file tree sidebar for browsing project folders
//

import SwiftUI

/// Represents a node in the file tree
public struct FileNode: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [FileNode]?

    public init(url: URL, isDirectory: Bool, children: [FileNode]? = nil) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }

    public var icon: String {
        if isDirectory { return "folder.fill" }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "doc.text"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "html", "htm": return "globe"
        case "css": return "paintbrush"
        case "json": return "curlybraces.square"
        case "md", "markdown": return "doc.richtext"
        case "sh", "bash", "zsh": return "terminal"
        case "yaml", "yml": return "list.bullet"
        case "xcodeproj", "xcworkspace": return "hammer"
        default: return "doc"
        }
    }

    public var iconColor: Color {
        if isDirectory { return .accentColor }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return .orange
        case "py": return .blue
        case "js", "ts", "jsx", "tsx": return .yellow
        case "html", "htm": return .red
        case "css": return .purple
        case "json": return .green
        case "md", "markdown": return .gray
        case "sh", "bash", "zsh": return .mint
        default: return .secondary
        }
    }
}

/// Builds a FileNode tree from a directory URL
public enum FileTreeBuilder {
    public static func buildTree(from url: URL, depth: Int = 3) -> FileNode? {
        let fm = FileManager.default
        var isDir: ObjCBool = false

        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }

        if isDir.boolValue {
            var children: [FileNode] = []
            if depth > 0,
                let contents = try? fm.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
            {
                children =
                    contents
                    .sorted { a, b in
                        let aIsDir =
                            (try? a.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory
                            ?? false
                        let bIsDir =
                            (try? b.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory
                            ?? false
                        if aIsDir != bIsDir { return aIsDir }
                        return a.lastPathComponent.localizedCaseInsensitiveCompare(
                            b.lastPathComponent) == .orderedAscending
                    }
                    .compactMap { childURL in
                        buildTree(from: childURL, depth: depth - 1)
                    }
            }
            return FileNode(url: url, isDirectory: true, children: children)
        } else {
            return FileNode(url: url, isDirectory: false)
        }
    }
}

/// Sidebar view showing project file tree
public struct FileTreeView: View {
    @Bindable var viewModel: EditorViewModel
    @State private var rootNode: FileNode?
    @State private var expandedNodes: Set<String> = []

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with open folder button
            HStack {
                Text("EXPLORER")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: openFolder) {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Open Folder")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // File tree
            if let root = rootNode {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(root.children ?? []) { node in
                            FileTreeNodeView(
                                node: node,
                                expandedNodes: $expandedNodes,
                                onFileSelected: { url in
                                    viewModel.openFile(url: url)
                                },
                                depth: 0
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No folder open")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Open Folder") { openFolder() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 200, idealWidth: 240)
        .onChange(of: viewModel.projectRootURL) { _, newURL in
            if let url = newURL {
                rootNode = FileTreeBuilder.buildTree(from: url, depth: 4)
                if let root = rootNode {
                    expandedNodes.insert(root.id)
                }
            }
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a project folder to open"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.openFolder(url: url)
        }
    }
}

/// Recursive view for a single node in the file tree
struct FileTreeNodeView: View {
    let node: FileNode
    @Binding var expandedNodes: Set<String>
    let onFileSelected: (URL) -> Void
    let depth: Int

    private var isExpanded: Bool {
        expandedNodes.contains(node.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: handleTap) {
                HStack(spacing: 4) {
                    if node.isDirectory {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 12)
                    } else {
                        Spacer().frame(width: 12)
                    }

                    Image(systemName: node.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(node.iconColor)
                        .frame(width: 16)

                    Text(node.name)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
                .padding(.leading, CGFloat(depth) * 16)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if node.isDirectory, isExpanded, let children = node.children {
                ForEach(children) { child in
                    FileTreeNodeView(
                        node: child,
                        expandedNodes: $expandedNodes,
                        onFileSelected: onFileSelected,
                        depth: depth + 1
                    )
                }
            }
        }
    }

    private func handleTap() {
        if node.isDirectory {
            if isExpanded {
                expandedNodes.remove(node.id)
            } else {
                expandedNodes.insert(node.id)
                // Lazy-load children if needed
                if let rootNode = FileTreeBuilder.buildTree(from: node.url, depth: 2),
                    let children = rootNode.children
                {
                    // Children already loaded via tree builder
                    _ = children
                }
            }
        } else {
            onFileSelected(node.url)
        }
    }
}
