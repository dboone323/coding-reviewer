//
// DiffView.swift
// CodingReviewer
//
// View for displaying code diffs
//

import SwiftUI

struct DiffView: View {
    let original: String
    let modified: String
    
    var body: some View {
        HSplitView {
            VStack {
                Text("Original")
                    .font(.headline)
                TextEditor(text: .constant(original))
                    .font(.monospaced(.body)())
            }
            
            VStack {
                Text("Modified")
                    .font(.headline)
                TextEditor(text: .constant(modified))
                    .font(.monospaced(.body)())
            }
        }
    }
}
