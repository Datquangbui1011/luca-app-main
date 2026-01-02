import SwiftUI

struct ResetPassword: View {
    @Binding var authState: AuthState

    @State private var email = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Header
                VStack(spacing: 4) {
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold))

                    Text("Enter your email to get a reset link")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)

// MARK: Email Field
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.caption)
                            .fontWeight(.medium)

                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            TextField("name@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .font(.subheadline)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)

// MARK: Send Link Button
                Button {
                    Task { await sendResetEmail() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("Send Reset Link")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 200)
                .frame(height: 56)
                .background(canSubmit ? Color(hex: "D9B53E") : Color.gray)
                .cornerRadius(30)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .disabled(!canSubmit || isLoading)
                
// MARK: Back to Login
                HStack {
                    Text("Remember your password?")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    Button("Sign In") {
                        withAnimation {
                            authState = .login
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .padding(.top, 12)
                
                Spacer(minLength: 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "F5E8C7"))
        .alert("Password Reset", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

// MARK: Send Reset Email
    private func sendResetEmail() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard isValidEmail(trimmed) else {
            await MainActor.run {
                alertMessage = "Please enter a valid email address."
                showAlert = true
            }
            return
        }
        
        isLoading = true
        do {
            try await APIService.requestPasswordReset(email: trimmed)
            await MainActor.run {
                alertMessage = "If an account exists for \(trimmed), we've sent you a reset link."
                showAlert = true
                isLoading = false
            }
        } catch APIError.serverError(let msg) {
            await MainActor.run {
                alertMessage = msg
                showAlert = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Unable to send reset link. Please try again."
                showAlert = true
                isLoading = false
            }
        }
    }
    
// MARK: Email Validation
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
    
    private var canSubmit: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && isValidEmail(trimmed)
    }
}

