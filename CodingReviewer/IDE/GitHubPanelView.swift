//
//  GitHubPanelView.swift
//  CodingReviewer
//
//  GitHub integration panel showing PRs and issues
//

import SwiftUI

/// GitHub panel for viewing PRs and issues
public struct GitHubPanelView: View {
    @Bindable var viewModel: GitHubPanelViewModel
    @State private var selectedTab: Tab = .pullRequests

    enum Tab: String, CaseIterable {
        case pullRequests = "Pull Requests"
        case issues = "Issues"
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with repo info
            GitHubHeader(viewModel: viewModel)

            Divider()

            // Tab selector
            Picker("View", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            // Content based on selected tab
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .padding()
                Spacer()
            } else if let error = viewModel.errorMessage {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.detectCurrentRepo() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                Spacer()
            } else {
                switch selectedTab {
                case .pullRequests:
                    PullRequestsList(viewModel: viewModel)
                case .issues:
                    IssuesList(viewModel: viewModel)
                }
            }
        }
    }
}

/// GitHub header with repo info
struct GitHubHeader: View {
    @Bindable var viewModel: GitHubPanelViewModel

    var body: some View {
        HStack(spacing: 8) {
            if let repo = viewModel.repo {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 11))
                Text(repo.fullName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 11))
                Text("No repository detected")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Refresh button
            Button(action: { Task { await viewModel.detectCurrentRepo() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Refresh")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Pull requests list
struct PullRequestsList: View {
    @Bindable var viewModel: GitHubPanelViewModel

    var body: some View {
        if viewModel.pullRequests.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.pull")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("No open pull requests")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            Spacer()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.pullRequests) { pr in
                        GitHubPRRow(pr: pr)
                    }
                }
                .padding(8)
            }
        }
    }
}

/// GitHub pull request row
struct GitHubPRRow: View {
    let pr: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(pr.number)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(pr.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)

                Spacer()

                // State badge
                Text(pr.state.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(pr.state == "open" ? Color.green : Color.purple)
                    .clipShape(Capsule())
            }

            HStack(spacing: 6) {
                Text(pr.user.login)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.secondary)

                Text(pr.createdAt, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            // Open in browser button
            Button(action: { openURL(pr.htmlUrl) }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.square")
                    Text("Open in Browser")
                }
                .font(.system(size: 10))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Issues list
struct IssuesList: View {
    @Bindable var viewModel: GitHubPanelViewModel
    @State private var showingCreateIssue = false

    var body: some View {
        VStack(spacing: 0) {
            // Create issue button
            HStack {
                Spacer()
                Button(action: { showingCreateIssue = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Issue")
                    }
                    .font(.system(size: 10))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(8)

            Divider()

            if viewModel.issues.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No open issues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.issues) { issue in
                            GitHubIssueRow(issue: issue)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .sheet(isPresented: $showingCreateIssue) {
            CreateIssueSheet(viewModel: viewModel)
        }
    }
}

/// GitHub issue row
struct GitHubIssueRow: View {
    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(issue.number)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)

                Text(issue.title)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)

                Spacer()

                // State badge
                Text(issue.state.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(issue.state == "open" ? Color.green : Color.purple)
                    .clipShape(Capsule())
            }

            HStack(spacing: 6) {
                Text(issue.user.login)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            // Open in browser button
            Button(action: { openURL(issue.htmlUrl) }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.square")
                    Text("Open in Browser")
                }
                .font(.system(size: 10))
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Create issue sheet
struct CreateIssueSheet: View {
    @Bindable var viewModel: GitHubPanelViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var issueBody: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Create New Issue")
                .font(.headline)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $issueBody)
                .font(.system(size: 12))
                .frame(height: 150)
                .border(Color(nsColor: .separatorColor))

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    Task {
                        await viewModel.createIssue(title: title, body: issueBody)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 400)
    }
}
