//
//  AccountManagementView.swift
//  luca-app
//

import SwiftUI

struct AccountManagementView: View {
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Button("Sign Out") {
                    isAuthenticated = false
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "F5E8C7"))
            .navigationTitle("Account Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
