//
//  outputView.swift
//  luca-app
//
//  Created by Rhett Larsen on 11/17/25.
//

import SwiftUI

struct OutputView: View {
    var body: some View {
        VStack {
            Text("Output Page")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OutputView()
    }
}

