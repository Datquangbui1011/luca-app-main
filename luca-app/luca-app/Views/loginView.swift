import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @Binding var authState: AuthState
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var hasError: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
// MARK: Error Message
                if hasError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 32)
                }
                
// MARK: Email Input
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if !email.isEmpty && !isValidEmail(email) {
                            Text("Invalid email format")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
// MARK: Password Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            ZStack(alignment: .leading) {
                                // Hidden Password
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .opacity(showPassword ? 0 : 1)
                                    .allowsHitTesting(!showPassword)
                                    .accessibilityHidden(showPassword)

                                // Visible Password
                                TextField("Enter your password", text: $password)
                                    .textContentType(.password) .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .opacity(showPassword ? 1 : 0)
                                    .allowsHitTesting(showPassword)
                                    .accessibilityHidden(!showPassword)
                            }
                            // Toggle password visibility
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { showPassword.toggle() }
                            } label: {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 44)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    
// MARK: Forgot Password
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                authState = .resetPassword
                            }
                        } label: {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
// MARK: Login Button
                Button {
                    performLogin()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 200)
                .frame(height: 56)
                .background(email.isEmpty || password.isEmpty ? Color.gray.opacity(0.4) : Color(hex: "D9B53E"))
                .cornerRadius(30)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .disabled(email.isEmpty || password.isEmpty || isLoading || !isValidEmail(email))
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    
                    Text("or")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                
// MARK: Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    
                    Button("Sign Up") {
                        withAnimation {
                            authState = .signup
                        }
                    }
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(.top, 16)
                
                Spacer()
            }
        }
        .background(Color(hex: "F5E8C7"))
        .navigationBarTitleDisplayMode(.inline)
        .dismissKeyboardOnTap()
    }
    
// MARK: Login API Call
    private func performLogin() {
        isLoading = true
        hasError = false
        
        Task {
            do {
                // Backend request
                let response = try await APIService.login(email: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                    isAuthenticated = true
                }
            } catch APIError.serverError(let message) {
                // Returns specific error message
                await MainActor.run {
                    isLoading = false
                    errorMessage = message
                    hasError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unable to connect. Please check your connection."
                    hasError = true
                }
            }
        }
    }
    
// MARK: Email Validation
    
    private func isValidEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: trimmed)
    }
}
