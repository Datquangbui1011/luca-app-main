//  RegistrationFlowIntegrationTests.swift
//  luca-app

import XCTest
import Foundation
@testable import luca_app

final class createAccountTests: XCTestCase {
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Clear any existing auth tokens before each test
        clearAuthToken()
    }
    
    override func tearDown() {
        // Clean up after tests
        clearAuthToken()
        super.tearDown()
    }
    
    // COMPLETE REGISTRATION FLOW TESTS
    
    @MainActor
    func testCompleteRegistrationFlow_Success() async throws {
        // Given: Valid user registration data
        let uniqueEmail = "test\(UUID().uuidString)@example.com"
        let name = "Test User"
        let phone = "1234567890"
        let password = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        // When: User registers with valid data
        let response = try await APIService.createAccount(
            name: name,
            email: uniqueEmail,
            phone: phone,
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        // Then: Registration succeeds
        XCTAssertEqual(response.message, "Account created successfully")
        XCTAssertFalse(response.token.isEmpty, "Token should not be empty")
        XCTAssertEqual(response.account.name, name)
        XCTAssertEqual(response.account.email, uniqueEmail)
        XCTAssertEqual(response.account.phone, phone)
        
        // And: Token is saved to Keychain
        let savedToken = APIService.getAuthToken()
        XCTAssertNotNil(savedToken, "Token should be saved to Keychain")
        XCTAssertEqual(savedToken, response.token)
        
        // And: User is authenticated
        XCTAssertTrue(APIService.isAuthenticated())
        
        // And: Can fetch account details with token
        let accountDetails = try await APIService.getMyAccount()
        XCTAssertEqual(accountDetails.id, response.account.id)
        XCTAssertEqual(accountDetails.name, name)
        XCTAssertEqual(accountDetails.email, uniqueEmail)
    }
    
    @MainActor
    func testRegistrationFlow_DuplicateEmail_Fails() async throws {
        // Given: An existing user
        let email = "duplicate\(UUID().uuidString)@example.com"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "First User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: "password123"
        )
        
        clearAuthToken() // Clear token from first registration
        
        // When: Another user tries to register with same email
        do {
            _ = try await APIService.createAccount(
                name: "Second User",
                email: email,
                phone: "0987654321",
                dateOfBirth: dateOfBirth,
                password: "password456"
            )
            
            // Then: Registration should fail
            XCTFail("Registration should have failed with duplicate email")
            
        } catch APIError.serverError(let message) {
            // Then: Appropriate error is thrown
            XCTAssertTrue(
                message.lowercased().contains("already registered") ||
                message.lowercased().contains("email"),
                "Error message should indicate duplicate email"
            )
            
            // And: No token is saved
            XCTAssertNil(APIService.getAuthToken())
            XCTAssertFalse(APIService.isAuthenticated())
        }
    }
    
    @MainActor
    func testRegistrationFlow_InvalidEmail_Fails() async throws {
        // Given: Invalid email format
        let invalidEmail = "notanemail"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        // When: User tries to register with invalid email
        do {
            _ = try await APIService.createAccount(
                name: "Test User",
                email: invalidEmail,
                phone: "1234567890",
                dateOfBirth: dateOfBirth,
                password: "password123"
            )
            
            // Then: Should fail
            XCTFail("Registration should fail with invalid email")
            
        } catch {
            // Then: Error is caught
            XCTAssertTrue(error is APIError)
            
            // And: No token saved
            XCTAssertNil(APIService.getAuthToken())
            XCTAssertFalse(APIService.isAuthenticated())
        }
    }
    
    @MainActor
    func testRegistrationFlow_WeakPassword_Fails() async throws {
        // Given: Password that doesn't meet requirements
        let weakPassword = "weak" // Too short, no numbers
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        // When: User tries to register with weak password
        do {
            _ = try await APIService.createAccount(
                name: "Test User",
                email: "test\(UUID())@example.com",
                phone: "1234567890",
                dateOfBirth: dateOfBirth,
                password: weakPassword
            )
            
            // Then: Should fail
            XCTFail("Registration should fail with weak password")
            
        } catch {
            // Then: Error is caught
            XCTAssertTrue(error is APIError)
            XCTAssertNil(APIService.getAuthToken())
        }
    }
    
    // REGISTRATION TO LOGIN FLOW TESTS
    
    @MainActor
    func testRegistrationThenLogin_Success() async throws {
        // Given: User successfully registers
        let email = "test\(UUID())@example.com"
        let password = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        let registerResponse = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        let registrationAccountId = registerResponse.account.id
        let _registrationToken = registerResponse.token
        
        // When: User logs out
        try await APIService.logout()
        
        // Then: Token should be cleared
        XCTAssertNil(APIService.getAuthToken())
        XCTAssertFalse(APIService.isAuthenticated())
        
        // When: User logs back in with same credentials
        let loginResponse = try await APIService.login(
            email: email,
            password: password
        )
        
        // Then: Login succeeds
        XCTAssertEqual(loginResponse.message, "Login successful")
        XCTAssertFalse(loginResponse.token.isEmpty)
        XCTAssertEqual(loginResponse.account.id, registrationAccountId)
        XCTAssertEqual(loginResponse.account.email, email)
        
        // And: New token is saved
        let newToken = APIService.getAuthToken()
        XCTAssertNotNil(newToken)
        XCTAssertEqual(newToken, loginResponse.token)
        
        // Note: Token should be different from registration token
        // (This depends on your backend implementation)
        
        // And: User is authenticated again
        XCTAssertTrue(APIService.isAuthenticated())
    }
    
    @MainActor
    func testRegistrationThenLoginWithWrongPassword_Fails() async throws {
        // Given: User successfully registers
        let email = "test\(UUID())@example.com"
        let correctPassword = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: correctPassword
        )
        
        // When: User logs out
        try await APIService.logout()
        
        // And: Tries to login with wrong password
        do {
            _ = try await APIService.login(
                email: email,
                password: "wrongpassword123"
            )
            
            XCTFail("Login should fail with wrong password")
            
        } catch APIError.serverError(let message) {
            // Then: Login fails with appropriate error
            XCTAssertTrue(
                message.lowercased().contains("invalid") ||
                message.lowercased().contains("password"),
                "Error should indicate invalid credentials"
            )
            
            // And: No token is saved
            XCTAssertNil(APIService.getAuthToken())
            XCTAssertFalse(APIService.isAuthenticated())
        }
    }
    
    // FORM VALIDATION INTEGRATION TESTS
    
    @MainActor
    func testFormValidation_BeforeAPICall() {
        // Test that form validation catches errors before API call
        
        // Given: Invalid form data
        let invalidEmail = "notanemail"
        let validEmail = "test@example.com"
        let shortPassword = "abc"
        let validPassword = "password123"
        let mismatchPassword = "different123"
        
        // When/Then: Email validation
        XCTAssertFalse(isValidEmail(invalidEmail))
        XCTAssertTrue(isValidEmail(validEmail))
        
        // When/Then: Password validation
        XCTAssertFalse(isValidPassword(shortPassword))
        XCTAssertTrue(isValidPassword(validPassword))
        
        // When/Then: Password matching
        XCTAssertFalse(passwordsMatch(validPassword, mismatchPassword))
        XCTAssertTrue(passwordsMatch(validPassword, validPassword))
        
        // When/Then: Complete form validation
        XCTAssertFalse(isSignUpFormValid(
            fullName: "Test User",
            email: invalidEmail, // Invalid
            phone: "1234567890",
            dateOfBirth: Date(),
            password: validPassword,
            confirmPassword: validPassword,
            agreedToTerms: true
        ))
        
        XCTAssertTrue(isSignUpFormValid(
            fullName: "Test User",
            email: validEmail,
            phone: "1234567890",
            dateOfBirth: Date(),
            password: validPassword,
            confirmPassword: validPassword,
            agreedToTerms: true
        ))
    }
    
    func testPhoneNumberFormatting_Integration() {
        // Test that phone formatting works correctly in registration flow
        
        // Given: Raw phone input
        let rawPhone = "1234567890"
        
        // When: Format is applied
        let formatted = formatPhoneNumber(rawPhone)
        
        // Then: Correct format
        XCTAssertEqual(formatted, "(123) 456-7890")
        
        // When: Digits are extracted for API
        let digits = extractDigits(formatted)
        
        // Then: Only digits remain
        XCTAssertEqual(digits, rawPhone)
        XCTAssertTrue(isValidPhoneNumber(digits))
    }
    
    func testAgeValidation_Integration() {
        // Test age calculation for minimum age requirement
        
        let calendar = Calendar.current
        
        // Given: User is 13 years old (minimum age)
        let date13YearsAgo = calendar.date(byAdding: .year, value: -13, to: Date())!
        XCTAssertTrue(meetsMinimumAge(date13YearsAgo, minimum: 13))
        
        // Given: User is 12 years old (too young)
        let date12YearsAgo = calendar.date(byAdding: .year, value: -12, to: Date())!
        XCTAssertFalse(meetsMinimumAge(date12YearsAgo, minimum: 13))
        
        // Given: User is 25 years old (valid)
        let date25YearsAgo = calendar.date(byAdding: .year, value: -25, to: Date())!
        XCTAssertTrue(meetsMinimumAge(date25YearsAgo, minimum: 13))
    }
    
    
    // ACCOUNT MANAGEMENT AFTER REGISTRATION
    
    @MainActor
    func testAccountRetrieval_AfterRegistration() async throws {
        // Given: User successfully registers
        let email = "test\(UUID())@example.com"
        let name = "Test User"
        let phone = "1234567890"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        let registerResponse = try await APIService.createAccount(
            name: name,
            email: email,
            phone: phone,
            dateOfBirth: dateOfBirth,
            password: "password123"
        )
        
        // When: Fetch account details
        let account = try await APIService.getMyAccount()
        
        // Then: Account details match registration
        XCTAssertEqual(account.id, registerResponse.account.id)
        XCTAssertEqual(account.name, name)
        XCTAssertEqual(account.email, email)
        XCTAssertEqual(account.phone, phone)
        XCTAssertEqual(account.date_of_birth, formatDateForAPI(dateOfBirth))
    }
    
    @MainActor
    func testAccountDeletion_AfterRegistration() async throws {
        // Given: User successfully registers
        let email = "test\(UUID())@example.com"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        let registerResponse = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: "password123"
        )
        
        let accountId = registerResponse.account.id
        
        // Verify account exists
        let account = try await APIService.getMyAccount()
        XCTAssertEqual(account.id, accountId)
        
        // When: Delete account
        try await APIService.deleteMyAccount()
        
        // Then: Token is cleared
        XCTAssertNil(APIService.getAuthToken())
        XCTAssertFalse(APIService.isAuthenticated())
        
        // And: Cannot fetch account details (401 Unauthorized)
        do {
            _ = try await APIService.getMyAccount()
            XCTFail("Should not be able to fetch account after deletion")
        } catch APIError.unauthorized {
            // Expected
        }
    }
    
    // HELPER FUNCTIONS
    
    private func clearAuthToken() {
        // Clear token from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken"
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: trimmed)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8 &&
               password.contains(where: { $0.isNumber }) &&
               password.contains(where: { $0.isLetter })
    }
    
    private func passwordsMatch(_ password: String, _ confirm: String) -> Bool {
        return !password.isEmpty && password == confirm
    }
    
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
    
    private func extractDigits(_ value: String) -> String {
        return value.filter { $0.isNumber }
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = extractDigits(phone)
        return digits.count == 10
    }
    
    private func calculateAge(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }
    
    private func meetsMinimumAge(_ date: Date, minimum: Int) -> Bool {
        return calculateAge(from: date) >= minimum
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func isSignUpFormValid(
        fullName: String,
        email: String,
        phone: String,
        dateOfBirth: Date,
        password: String,
        confirmPassword: String,
        agreedToTerms: Bool
    ) -> Bool {
        return !fullName.isEmpty &&
               isValidEmail(email) &&
               isValidPhoneNumber(phone) &&
               isValidPassword(password) &&
               passwordsMatch(password, confirmPassword) &&
               agreedToTerms
    }
}
