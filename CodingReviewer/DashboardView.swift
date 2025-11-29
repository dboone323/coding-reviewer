//
// DashboardView.swift
// CodingReviewer
//
// Main dashboard for the application
//

import SwiftUI

struct DashboardView: View {
    @Binding var showFilePicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("CodingReviewer Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                DashboardCard(title: "Analyze Code", icon: "magnifyingglass", color: .blue) {
                    showFilePicker = true
                }
                
                DashboardCard(title: "Review History", icon: "clock", color: .orange) {
                    // Navigate to history
                }
                
                DashboardCard(title: "Settings", icon: "gear", color: .gray) {
                    // Open settings
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
    }
}

struct RecentFilesList: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Files")
                .font(.headline)
            
            List {
                Text("No recent files")
                    .foregroundColor(.secondary)
            }
            .frame(height: 200)
        }
    }
}
