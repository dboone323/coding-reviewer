//
// ReviewHistoryView.swift
// CodingReviewer
//
// View for displaying past review history
//

import SwiftUI

struct ReviewHistoryView: View {
    // Mock data for now
    struct ReviewItem: Identifiable {
        let id = UUID()
        let fileName: String
        let date: Date
        let issuesCount: Int
    }

    let history: [ReviewItem] = [
        ReviewItem(fileName: "AppDelegate.swift", date: Date(), issuesCount: 3),
        ReviewItem(fileName: "ContentView.swift", date: Date().addingTimeInterval(-86400), issuesCount: 0)
    ]

    var body: some View {
        List(history) { item in
            HStack {
                VStack(alignment: .leading) {
                    Text(item.fileName)
                        .font(.headline)
                    Text(item.date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(item.issuesCount) issues")
                    .foregroundColor(item.issuesCount > 0 ? .red : .green)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Review History")
    }
}
