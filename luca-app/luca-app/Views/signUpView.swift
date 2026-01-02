import SwiftUI
import UIKit

struct SignUpView: View {
    @Binding var isAuthenticated: Bool
    @Binding var authState: AuthState
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dateOfBirth = Date()
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccessAlert = false
    
// MARK: Date format
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // Date formatter for API (YYYY-MM-DD)
    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // Header
                VStack(spacing: 4) {
                    Text("New Account")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Sign up to get started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .padding(.bottom, 16)
                
// MARK: Error Message
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                
// MARK: Fields
                VStack(spacing: 12) {
               
                    
// MARK: Full Name
                    FieldView(label: "Full Name", text: $fullName, icon: "person")
             
                    
// MARK: Email
                    FieldView(label: "Email", text: $email, icon: "envelope", keyboard: .emailAddress, autocapitalization: .never)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "phone")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            
                            TextField("(123) 456-7890", text: $phone)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                                .font(.subheadline)
                                .onChange(of: phone) { _, newValue in
                                    let formatted = formatPhoneNumber(newValue)
                                    if formatted != phone { phone = formatted }
                                    
                                    // Auto-dismiss keyboard when complete
                                    if phone.filter(\.isNumber).count == 10 {
                                        UIApplication.shared.sendAction(
                                            #selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil
                                        )
                                    }
                                }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
// MARK: Date of Birth
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date of Birth")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            
                            DatePicker(
                                "Select date of birth",
                                selection: $dateOfBirth,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                            
                            Spacer()
                            
                            Text(dateFormatter.string(from: dateOfBirth))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
// MARK: Password
                    PasswordField(label: "Password", text: $password, showText: $showPassword)
                    
                    // Confirm Password
                    PasswordField(label: "Confirm Password", text: $confirmPassword, showText: $showConfirmPassword)
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords don't match")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    
// MARK: Terms and Conditions
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            agreedToTerms.toggle()
                        } label: {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundStyle(agreedToTerms ? .blue : .gray)
                                .font(.callout)
                        }
                        
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                
// MARK: Sign Up Button
                Button {
                    signUp()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Text("Create Account")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(isFormValid ? .white : .gray)
                    }
                }
                .frame(width: 200, height: 56)
                .background(isFormValid ? Color(hex: "D9B53E") : Color.gray.opacity(0.5))
                .cornerRadius(30)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .disabled(!isFormValid || isLoading)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                
// MARK: Back To Login
                HStack {
                    Text("Already have an account?")
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
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "F5E8C7"))
        .dismissKeyboardOnTap()
        .alert("Welcome to LUCA!", isPresented: $showSuccessAlert) {
            Button("Continue") {
                authState = .login
            }
        } message: {
            Text("Your account was successfully created. Please sign in to get started.")
        }

    }
    
// MARK: Form Validation
    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return
            !fullName.isEmpty &&
            !trimmedEmail.isEmpty && isValidEmail(trimmedEmail) &&
            !phone.isEmpty && phone.filter(\.isNumber).count == 10 &&
            !password.isEmpty && password == confirmPassword && agreedToTerms
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
    
// MARK: Sign Up Logic
    
    private func signUp() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedPhone = phone.filter(\.isNumber)
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        // Validate Phone Length
        guard cleanedPhone.count == 10 else {
            errorMessage = "Please enter a valid 10-digit phone number"
            showError = true
            return
        }
        
        // Require Minimum Age
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
        guard age >= 13 else {
            errorMessage = "You must be at least 13 years old to create an account"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                // Create Account Backend Request
                _ = try await APIService.createAccount(
                    name: fullName.trimmingCharacters(in: .whitespaces),
                    email: trimmedEmail.lowercased(),
                    phone: cleanedPhone,
                    dateOfBirth: dateOfBirth,
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch APIError.serverError(let message) {
                print("Server error message:", message)

                await MainActor.run {
                    isLoading = false

                    let lower = message.lowercased()

                    if lower.contains("already registered")
                    {
                        errorMessage = "An account with this email already exists."
                    }
                    else if (lower.contains("invalid") && lower.contains("email"))
                        || lower.contains("unprocessable")
                        || lower.contains("422") {
                        errorMessage = "Please enter a valid email address."
                    }
                    else {
                        errorMessage = "Unable to create account. Please try again."
                    }
                    
                    showError = true
                    
                }
            } catch {
                print("Generic catch was hit:", error)
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Unable to create account. Please try again."
                    showError = true
                }
            }
        }
    }

// MARK: Phone Number Formate
    private func formatPhoneNumber(_ value: String) -> String {
        let digits = value.filter { $0.isNumber }
        let limited = String(digits.prefix(10))
        let count = limited.count
        
        switch count {
        case 0:
            return ""
        case 1...3:
            return "(\(limited)"
        case 4...6:
            let area = limited.prefix(3)
            let mid = limited.dropFirst(3)
            return "(\(area)) \(mid)"
        default:
            let area = limited.prefix(3)
            let mid = limited.dropFirst(3).prefix(3)
            let last = limited.dropFirst(6)
            return "(\(area)) \(mid)-\(last)"
        }
    }
}

// MARK: - Reusable Views

struct FieldView: View {
    let label: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
            
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                TextField("Enter your \(label.lowercased())", text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalization)
                    .font(.subheadline)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct PasswordField: View {
    let label: String
    @Binding var text: String
    @Binding var showText: Bool
    var contentType: UITextContentType = .newPassword

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)

            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                ZStack(alignment: .leading) {
                    SecureField("Enter your password", text: $text)
                        .textContentType(contentType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.subheadline)
                        .opacity(showText ? 0 : 1)
                        .allowsHitTesting(!showText)
                        .accessibilityHidden(showText)

                    TextField("Enter your password", text: $text)
                        .textContentType(contentType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.subheadline)
                        .opacity(showText ? 1 : 0)
                        .allowsHitTesting(showText)
                        .accessibilityHidden(!showText)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { showText.toggle() }
                } label: {
                    Image(systemName: showText ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Group {
                HStack(spacing: 10) {
                    PasswordRequirement(text: "8+ chars", isMet: text.count >= 8)
                    PasswordRequirement(text: "Number",
                        isMet: text.range(of: #"\d"#, options: .regularExpression) != nil)
                    PasswordRequirement(text: "Letter",
                        isMet: text.range(of: #"[a-zA-Z]"#, options: .regularExpression) != nil)
                }
                .padding(.top, 4)
            }
            .opacity(text.isEmpty ? 0 : 1)
            .accessibilityHidden(text.isEmpty)
        }
    }
}


struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption2)
                .foregroundStyle(isMet ? .green : .gray)
            Text(text)
                .font(.caption2)
                .foregroundStyle(isMet ? .green : .secondary)
        }
    }
}
