//
// DashboardView.swift
// CodingReviewer
//
// Main dashboard for the application
//

import SwiftUI

struct DashboardView: View {
    @Binding var showFilePicker: Bool
    @AppStorage("CR_USE_AI") private var useAI: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("CodingReviewer Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityLabel("CodingReviewer Dashboard")
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 20) {
                DashboardCard(title: "Analyze Code", icon: "magnifyingglass", color: .blue) {
                    showFilePicker = true
                }

                DashboardCard(title: "Review History", icon: "clock", color: .orange) {
                    print("Navigate to History")
                    // In a full app, this would trigger a NavigationLink or switch a tab
                }

                DashboardCard(title: "AI Status", icon: "cpu", color: useAI ? .green : .secondary) {
                    print("Show AI Service Status")
                    // Trigger status modal or settings
                }
            }
            .padding()

            RecentFilesList()
        }
        .padding()
    }
}

struct DashboardCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .padding(.top, 5)
            }
            .frame(width: 150, height: 120)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

struct RecentFilesList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Files")
                .font(.headline)

            VStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
                Text("No recent analysis found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .accessibilityLabel("Recent files empty state")
        }
    }
}
