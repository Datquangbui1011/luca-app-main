//
//  NewPasswordView.swift
//  luca-app
//
//  Created by UI Team  on 10/13/25.
//
import SwiftUI

struct NewPasswordView: View {
    @Binding var authState: AuthState
    let resetToken: String  // Will come from email link
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var resetSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("Create New Password")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Enter your new password")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                
// MARK: New Password Field
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Password")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            
                            if showPassword {
                                TextField("Create a password", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .font(.subheadline)
                            } else {
                                SecureField("Create a password", text: $newPassword)
                                    .textContentType(.newPassword)
                                    .font(.subheadline)
                            }
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
// MARK: Password requirements
                        if !newPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                PasswordRequirement(
                                    text: "At least 8 characters",
                                    isMet: newPassword.count >= 8
                                )
                                PasswordRequirement(
                                    text: "Contains a number",
                                    isMet: newPassword.contains(where: { $0.isNumber })
                                )
                                PasswordRequirement(
                                    text: "Contains a letter",
                                    isMet: newPassword.contains(where: { $0.isLetter })
                                )
                            }
                            .font(.caption2)
                            .padding(.top, 4)
                        }
                    }
                    
// MARK: Confirm Password Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            
                            if showConfirmPassword {
                                TextField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .font(.subheadline)
                            } else {
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .font(.subheadline)
                            }
                            
                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        if !confirmPassword.isEmpty && newPassword != confirmPassword {
                            Text("Passwords don't match")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
// MARK: Reset Password Button
                Button {
                    Task { await resetPassword() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("Reset Password")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 200)
                .frame(height: 56)
                .background(isFormValid ? Color(hex: "D9B53E") : Color.gray)
                .cornerRadius(30)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .disabled(!isFormValid || isLoading)
                
                Spacer()
            }
        }
        .background(Color(hex: "F5E8C7"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                if resetSuccess {
                    authState = .login
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !newPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword.contains(where: { $0.isNumber }) &&
        newPassword.contains(where: { $0.isLetter }) &&
        newPassword == confirmPassword
    }
    
// MARK: Reset Password API Call
    private func resetPassword() async {
        isLoading = true
        
        do {
            try await APIService.resetPassword(token: resetToken, newPassword: newPassword)
            
            await MainActor.run {
                isLoading = false
                alertTitle = "Success"
                alertMessage = "Your password has been reset successfully. Please log in with your new password."
                resetSuccess = true
                showAlert = true
            }
        } catch APIError.serverError(let message) {
            await MainActor.run {
                isLoading = false
                alertTitle = "Error"
                alertMessage = message
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertTitle = "Error"
                alertMessage = "Unable to reset password. Please try again."
                showAlert = true
            }
        }
    }
}


