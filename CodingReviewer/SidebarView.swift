//
//  SidebarView.swift
//  CodingReviewer
//
//  Sidebar with file browser and analysis tools
//

import SwiftUI

public struct SidebarView: View {
    @Binding var selectedFileURL: URL?
    @Binding var showFilePicker: Bool
    @Binding var selectedAnalysisType: AnalysisType
    @Binding var currentView: ContentViewType
    private let presenter: SidebarViewPresenter

    init(
        selectedFileURL: Binding<URL?>,
        showFilePicker: Binding<Bool>,
        selectedAnalysisType: Binding<AnalysisType>,
        currentView: Binding<ContentViewType>,
        presenter: SidebarViewPresenter = SidebarViewPresenter()
    ) {
        _selectedFileURL = selectedFileURL
        _showFilePicker = showFilePicker
        _selectedAnalysisType = selectedAnalysisType
        _currentView = currentView
        self.presenter = presenter
    }

    public var body: some View {
        List {
            Section("Files") {
                Button(action: presenter.openFileAction(binding: $showFilePicker)) {
                    Label("Open File", systemImage: "doc")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Open File")
                .accessibilityHint("Browse for a code file to review")

                if selectedFileURL != nil {
                    Text(selectedFileURL!.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Selected file: \(selectedFileURL!.lastPathComponent)")
                }
            }

            Section("Analysis Type") {
                Picker("Type", selection: $selectedAnalysisType) {
                    ForEach(AnalysisType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Analysis Type")
                .accessibilityHint("Select the type of code analysis")
            }

            Section("Tools") {
                Button(action: presenter.setViewAction(binding: $currentView, target: .analysis)) {
                    Label("Code Analysis", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Code Analysis")
                .accessibilityHint("Analyze code for issues and improvements")

                Button(action: presenter.setViewAction(binding: $currentView, target: .documentation)) {
                    Label("Documentation", systemImage: "doc.text")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Documentation")
                .accessibilityHint("Generate documentation for code")

                Button(action: presenter.setViewAction(binding: $currentView, target: .tests)) {
                    Label("Generate Tests", systemImage: "testtube.2")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Generate Tests")
                .accessibilityHint("Generate unit tests for code")
            }

            Section("Settings") {
                Button(action: presenter.preferencesAction()) {
                    Label("Preferences", systemImage: "gear")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Preferences")
                .accessibilityHint("Open application preferences")
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .accessibilityLabel("Navigation Sidebar")
    }
}

struct SidebarViewPresenter {
    func openFileAction(binding: Binding<Bool>) -> () -> Void {
        {
            binding.wrappedValue = true
        }
    }

    func setViewAction(binding: Binding<ContentViewType>, target: ContentViewType) -> () -> Void {
        {
            binding.wrappedValue = target
        }
    }

    func preferencesAction() -> () -> Void {
        {
            // Placeholder for future preferences handling
        }
    }
}
