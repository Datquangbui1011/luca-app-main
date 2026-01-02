////
////  CoachingFeatureView.swift
////  luca-app
////
////  Created by Dane Troia on 10/13/25.
////
//
//import SwiftUI
//
//struct CoachingFeatureView: View {
//    @State private var accounts: [AccountResponse] = []
//    @State private var isLoading = true
//    @State private var errorMessage: String?
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                if isLoading {
//                    VStack(spacing: 10) {
//                        ProgressView()
//                            .scaleEffect(1.5)
//                        Text("Loading accounts...")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding()
//                } else if let error = errorMessage {
//                    // Error State
//                    VStack(spacing: 15) {
//                        Image(systemName: "exclamationmark.triangle.fill")
//                            .font(.system(size: 50))
//                            .foregroundColor(.red)
//                        
//                        Text("Connection Error")
//                            .font(.headline)
//                        
//                        Text(error)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//                        
//                        Button(action: {
//                            Task { await fetchData() }
//                        }) {
//                            HStack {
//                                Image(systemName: "arrow.clockwise")
//                                Text("Retry")
//                            }
//                            .padding(.horizontal, 30)
//                            .padding(.vertical, 12)
//                            .background(Color(hex: "D9B53E"))
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                        }
//                    }
//                    .padding()
//                } else if accounts.isEmpty {
//                    // Empty State
//                    VStack(spacing: 15) {
//                        Image(systemName: "tray")
//                            .font(.system(size: 50))
//                            .foregroundColor(.gray)
//                        
//                        Text("No Accounts Found")
//                            .font(.headline)
//                        
//                        Text("There are no user accounts registered yet.")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//                        
//                        Button(action: {
//                            Task { await fetchData() }
//                        }) {
//                            HStack {
//                                Image(systemName: "arrow.clockwise")
//                                Text("Refresh")
//                            }
//                            .padding(.horizontal, 30)
//                            .padding(.vertical, 12)
//                            .background(Color(hex: "D9B53E"))
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                        }
//                    }
//                    .padding()
//                } else {
//                    // Success State - Show Data
//                    VStack(spacing: 0) {
//                        // Header
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("User Accounts")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                
//                                Text("\(accounts.count) user(s) found")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                            }
//                            
//                            Spacer()
//                            
//                            Button(action: {
//                                Task { await fetchData() }
//                            }) {
//                                Image(systemName: "arrow.clockwise")
//                                    .font(.title3)
//                                    .foregroundColor(Color(hex: "D9B53E"))
//                            }
//                        }
//                        .padding()
//                        .background(Color.white)
//                        
//                        // List of accounts
//                        List(accounts) { account in
//                            VStack(alignment: .leading, spacing: 10) {
//                                // Name and ID
//                                HStack {
//                                    Image(systemName: "person.circle.fill")
//                                        .foregroundColor(Color(hex: "D9B53E"))
//                                        .font(.title2)
//                                    
//                                    VStack(alignment: .leading, spacing: 2) {
//                                        Text(account.name)
//                                            .font(.headline)
//                                            .foregroundColor(.primary)
//                                        
//                                        Text("ID: \(account.id)")
//                                            .font(.caption)
//                                            .foregroundColor(.secondary)
//                                    }
//                                    
//                                    Spacer()
//                                }
//                                
//                                Divider()
//                                
//                                // Email
//                                HStack {
//                                    Image(systemName: "envelope.fill")
//                                        .foregroundColor(.blue)
//                                        .font(.caption)
//                                        .frame(width: 20)
//                                    
//                                    Text(account.email)
//                                        .font(.subheadline)
//                                        .foregroundColor(.primary)
//                                }
//                                
//                                // Phone
//                                HStack {
//                                    Image(systemName: "phone.fill")
//                                        .foregroundColor(.green)
//                                        .font(.caption)
//                                        .frame(width: 20)
//                                    
//                                    Text(account.phone)
//                                        .font(.subheadline)
//                                        .foregroundColor(.primary)
//                                }
//                                
//                                // Date of Birth
//                                HStack {
//                                    Image(systemName: "calendar")
//                                        .foregroundColor(.orange)
//                                        .font(.caption)
//                                        .frame(width: 20)
//                                    
//                                    Text("DOB: \(account.date_of_birth)")
//                                        .font(.subheadline)
//                                        .foregroundColor(.primary)
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                        .listStyle(.plain)
//                    }
//                }
//            }
//            .navigationTitle("Coaching Feature")
//            .navigationBarTitleDisplayMode(.inline)
//            .background(Color(hex: "F5E8C7"))
//        }
//        .task {
//            await fetchData()
//        }
//    }
//    
//    func fetchData() async {
//        await MainActor.run {
//            isLoading = true
//            errorMessage = nil
//        }
//        
//        do {
//            print("Fetching accounts from API...")
//            
//            let fetchedAccounts = try await APIService.getAllAccounts()
//            
//            print("Successfully fetched \(fetchedAccounts.count) accounts")
//            
//            await MainActor.run {
//                accounts = fetchedAccounts
//                isLoading = false
//            }
//            
//        } catch APIError.unauthorized {
//            await MainActor.run {
//                errorMessage = "Authentication required. Please log in again."
//                isLoading = false
//            }
//        } catch APIError.serverError(let message) {
//            await MainActor.run {
//                errorMessage = message
//                isLoading = false
//            }
//        } catch {
//            print("Error fetching accounts: \(error)")
//            
//            await MainActor.run {
//                errorMessage = "Failed to load accounts. Please check your connection."
//                isLoading = false
//            }
//        }
//    }
//}
//
//#Preview {
//    CoachingFeatureView()
//}


// TEMP CODE FOR RELEASE
import SwiftUI

struct CoachingFeatureView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Coaching Feature")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(hex: "F5E8C7"))
        }
    }
}

#Preview {
    CoachingFeatureView()
}
