//
//  SourceControlView.swift
//  CodingReviewer
//
//  Git source control UI with file staging, commit, and diff viewing
//

import SwiftUI

/// Source control panel showing git status and operations
public struct SourceControlView: View {
    @Bindable var viewModel: SourceControlViewModel

    public var body: some View {
        VStack(spacing: 0) {
            // Header with branch and sync buttons
            SourceControlHeader(viewModel: viewModel)

            Divider()

            if viewModel.errorMessage != nil {
                // Error message
                ErrorBanner(viewModel: viewModel)
            }

            if viewModel.isLoading {
                // Loading indicator
                ProgressView("Loading...")
                    .padding()
                Spacer()
            } else if let status = viewModel.status {
                // Changes list
                HSplitView {
                    // Left: File list
                    ChangesList(viewModel: viewModel, status: status)
                        .frame(minWidth: 200)

                    // Right: Diff view
                    if viewModel.selectedFile != nil {
                        GitDiffView(viewModel: viewModel)
                            .frame(minWidth: 300)
                    } else {
                        Text("Select a file to view changes")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                Divider()

                // Commit section
                CommitSection(viewModel: viewModel)
            } else {
                // Not a git repository
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Not a Git Repository")
                        .font(.headline)
                    Text("Open a folder with a git repository to use source control")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            }
        }
    }
}

/// Source control header with branch and sync
struct SourceControlHeader: View {
    @Bindable var viewModel: SourceControlViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Branch name
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 11))
                Text(viewModel.currentBranch)
                    .font(.system(size: 11, weight: .medium))
            }

            Spacer()

            // Refresh button
            Button(action: { Task { await viewModel.refreshStatus() } }, label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            })
            .buttonStyle(.borderless)
            .help("Refresh")

            // Pull button
            Button(action: { Task { await viewModel.pull() } }, label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 11))
            })
            .buttonStyle(.borderless)
            .help("Pull")

            // Push button
            Button(action: { Task { await viewModel.push() } }, label: {
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 11))
            })
            .buttonStyle(.borderless)
            .help("Push")
            .disabled((viewModel.status?.staged.isEmpty ?? true))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Error banner
struct ErrorBanner: View {
    @Bindable var viewModel: SourceControlViewModel

    var body: some View {
        if let error = viewModel.errorMessage {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Dismiss") { viewModel.errorMessage = nil }
                    .font(.caption)
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.1))
        }
    }
}

/// List of file changes
struct ChangesList: View {
    @Bindable var viewModel: SourceControlViewModel
    let status: GitStatus

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                // Staged changes
                if !status.staged.isEmpty {
                    Text("STAGED CHANGES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    ForEach(stagedChanges, id: \.id) { change in
                        FileChangeRow(
                            change: change,
                            isSelected: viewModel.selectedFile == change.path,
                            onSelect: {
                                Task { await viewModel.selectFile(change.path, staged: true) }
                            },
                            onToggle: { Task { await viewModel.unstageFile(change.path) } }
                        )
                    }
                }

                // Unstaged changes
                if !unstagedChanges.isEmpty {
                    Text("CHANGES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    ForEach(unstagedChanges, id: \.id) { change in
                        FileChangeRow(
                            change: change,
                            isSelected: viewModel.selectedFile == change.path,
                            onSelect: {
                                Task { await viewModel.selectFile(change.path, staged: false) }
                            },
                            onToggle: { Task { await viewModel.stageFile(change.path) } }
                        )
                    }
                }

                if status.staged.isEmpty && unstagedChanges.isEmpty {
                    Text("No changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
    }

    private var stagedChanges: [GitFileChange] {
        status.allChanges.filter(\.isStaged)
    }

    private var unstagedChanges: [GitFileChange] {
        status.allChanges.filter { !$0.isStaged }
    }
}

/// Individual file change row
struct FileChangeRow: View {
    let change: GitFileChange
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            // Checkbox (stage/unstage)
            Button(action: onToggle) {
                Image(systemName: change.isStaged ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundStyle(change.isStaged ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // Status icon
            Text(statusIcon(for: change.status))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(statusColor(for: change.status))
                .frame(width: 14)

            // File name
            Text(change.path.components(separatedBy: "/").last ?? change.path)
                .font(.system(size: 11))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private func statusIcon(for status: GitChangeStatus) -> String {
        switch status {
        case .modified: "M"
        case .added: "A"
        case .deleted: "D"
        case .renamed: "R"
        case .untracked: "U"
        }
    }

    private func statusColor(for status: GitChangeStatus) -> Color {
        switch status {
        case .modified: .orange
        case .added: .green
        case .deleted: .red
        case .renamed: .blue
        case .untracked: .purple
        }
    }
}

/// Git diff viewer
struct GitDiffView: View {
    @Bindable var viewModel: SourceControlViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File name header
            if let file = viewModel.selectedFile {
                HStack {
                    Text(file.components(separatedBy: "/").last ?? file)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()
            }

            // Diff content
            if viewModel.isLoadingDiff {
                ProgressView("Loading diff...")
                    .font(.caption)
                    .padding()
                Spacer()
            } else if !viewModel.selectedFileDiff.isEmpty {
                ScrollView([.horizontal, .vertical]) {
                    Text(viewModel.selectedFileDiff)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                }
            } else {
                Text("No changes to display")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            }
        }
    }
}

/// Commit section
struct CommitSection: View {
    @Bindable var viewModel: SourceControlViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Commit message field
            TextEditor(
                text: Binding(
                    get: { viewModel.commitMessage },
                    set: { viewModel.commitMessage = $0 }
                )
            )
            .font(.system(size: 11))
            .frame(height: 60)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            // Commit button
            HStack {
                Spacer()
                Button(action: { Task { await viewModel.commit() } }, label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Commit")
                    }
                    .font(.system(size: 11, weight: .medium))
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(
                    viewModel.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || (viewModel.status?.staged.isEmpty ?? true)
                )
            }
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
