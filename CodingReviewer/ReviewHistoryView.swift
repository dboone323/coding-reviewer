//
// ReviewHistoryView.swift
// CodingReviewer
//
// View for displaying past review history
//

import CoreData
import SwiftUI

struct ReviewHistoryView: View {
    @FetchRequest(
        entity: ReviewSession.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ReviewSession.date, ascending: false)],
    ) var sessions: FetchedResults<ReviewSession>

    var body: some View {
        List(sessions, id: \ReviewSession.id) { session in
            HStack {
                VStack(alignment: .leading) {
                    Text(session.summary ?? "(No summary)")
                        .font(.headline)
                    if let date = session.date {
                        Text(date.formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                let count = (session.issues as? Set<ReviewIssue>)?.count ?? 0
                Text("\(count) issues")
                    .foregroundColor(count > 0 ? .red : .green)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Review History")
    }
}
