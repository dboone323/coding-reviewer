//
//  NewReviewView.swift
//  CodingReviewer
//
//  View for creating a new code review
//

import SwiftUI

struct NewReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""
    @State private var repositoryURL = ""
    @State private var branchName = "main"
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $projectName)
                    TextField("Repository URL", text: $repositoryURL)
                    TextField("Branch", text: $branchName)
                }

                Section {
                    Button("Create Review") {
                        createReviewSession()
                    }
                    .disabled(projectName.isEmpty || repositoryURL.isEmpty)
                }
            }
            .navigationTitle("New Code Review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .frame(width: 400, height: 300)
    }

    private func createReviewSession() {
        let context = CoreDataStack.shared.context
        let newSession = ReviewSession(context: context)
        newSession.id = UUID()
        newSession.date = Date()
        newSession.summary = "Project: \(projectName), Repo: \(repositoryURL), Branch: \(branchName)"
        // Optionally, add initial issues or other properties here
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save review session: \(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    NewReviewView()
}
