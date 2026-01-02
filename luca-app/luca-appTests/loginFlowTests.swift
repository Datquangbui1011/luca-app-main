import XCTest
import Foundation
@testable import luca_app

final class loginFlowTests: XCTestCase {
    
    // Test account credentials (created once, reused)
    private var testEmail: String!
    private var testPassword: String!
    private var testAccountId: Int!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        clearAuthToken()
    }
    
    override func tearDown() {
        clearAuthToken()
        super.tearDown()
    }
    
    // BASIC LOGIN FLOW TESTS
    
    @MainActor
    func testLogin_WithValidCredentials_Success() async throws {
        // Given: A registered user
        let email = "test\(UUID())@example.com"
        let password = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        // Register the user first
        let registerResponse = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        let accountId = registerResponse.account.id
        
        // Logout to clear token
        try await APIService.logout()
        XCTAssertNil(APIService.getAuthToken())
        
        // When: User logs in with valid credentials
        let loginResponse = try await APIService.login(
            email: email,
            password: password
        )
        
        // Then: Login succeeds
        XCTAssertEqual(loginResponse.message, "Login successful")
        XCTAssertFalse(loginResponse.token.isEmpty, "Token should not be empty")
        XCTAssertEqual(loginResponse.account.id, accountId)
        XCTAssertEqual(loginResponse.account.email, email)
        
        // And: Token is saved to Keychain
        let savedToken = APIService.getAuthToken()
        XCTAssertNotNil(savedToken)
        XCTAssertEqual(savedToken, loginResponse.token)
        
        // And: User is authenticated
        XCTAssertTrue(APIService.isAuthenticated())
        
        // And: Can access protected endpoints
        let account = try await APIService.getMyAccount()
        XCTAssertEqual(account.id, accountId)
        XCTAssertEqual(account.email, email)
    }
    
    @MainActor
    func testLogin_WithInvalidEmail_Fails() async throws {
        // Given: Invalid email (account doesn't exist)
        let nonExistentEmail = "nonexistent\(UUID())@example.com"
        let password = "password123"
        
        // When: User tries to login with non-existent email
        do {
            _ = try await APIService.login(
                email: nonExistentEmail,
                password: password
            )
            
            XCTFail("Login should fail with non-existent email")
            
        } catch APIError.serverError(let message) {
            // Then: Login fails with appropriate error
            XCTAssertTrue(
                message.lowercased().contains("invalid") ||
                message.lowercased().contains("email") ||
                message.lowercased().contains("password"),
                "Error should indicate invalid credentials"
            )
            
            // And: No token is saved
            XCTAssertNil(APIService.getAuthToken())
            XCTAssertFalse(APIService.isAuthenticated())
        }
    }
    
    @MainActor
    func testLogin_WithWrongPassword_Fails() async throws {
        // Given: A registered user
        let email = "test\(UUID())@example.com"
        let correctPassword = "password123"
        let wrongPassword = "wrongpassword123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: correctPassword
        )
        
        try await APIService.logout()
        
        // When: User tries to login with wrong password
        do {
            _ = try await APIService.login(
                email: email,
                password: wrongPassword
            )
            
            XCTFail("Login should fail with wrong password")
            
        } catch APIError.serverError(let message) {
            // Then: Login fails
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
    
    @MainActor
    func testLogin_WithEmptyPassword_Fails() async throws {
        // Given: Valid email but empty password
        let email = "test@example.com"
        let emptyPassword = ""
        
        // When/Then: Should be caught by form validation before API call
        XCTAssertFalse(isLoginFormValid(email: email, password: emptyPassword))
        
        // But if it somehow gets through, API should reject it
        do {
            _ = try await APIService.login(
                email: email,
                password: emptyPassword
            )
            
            XCTFail("Login should fail with empty password")
            
        } catch {
            XCTAssertTrue(error is APIError)
            XCTAssertNil(APIService.getAuthToken())
        }
    }
    
    @MainActor
    func testLogin_WithMalformedEmail_Fails() async throws {
        // Given: Malformed email
        let malformedEmail = "not-an-email"
        let password = "password123"
        
        // When/Then: Should be caught by form validation
        XCTAssertFalse(isLoginFormValid(email: malformedEmail, password: password))
        
        do {
            _ = try await APIService.login(
                email: malformedEmail,
                password: password
            )
            
            XCTFail("Login should fail with malformed email")
            
        } catch {
            XCTAssertTrue(error is APIError)
            XCTAssertNil(APIService.getAuthToken())
        }
    }
    
    // LOGIN STATE MANAGEMENT TESTS
    
    @MainActor
    func testLogin_TokenPersistence() async throws {
        // Given: User logs in successfully
        let email = "test\(UUID())@example.com"
        let password = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        try await APIService.logout()
        
        let loginResponse = try await APIService.login(
            email: email,
            password: password
        )
        
        let originalToken = loginResponse.token
        
        // When: Simulate app restart (Keychain persists)
        let retrievedToken = APIService.getAuthToken()
        
        // Then: Token is still available
        XCTAssertNotNil(retrievedToken)
        XCTAssertEqual(retrievedToken, originalToken)
        
        // And: User is still authenticated
        XCTAssertTrue(APIService.isAuthenticated())
        
        // And: Can still access protected endpoints
        let account = try await APIService.getMyAccount()
        XCTAssertEqual(account.email, email)
    }
    
    @MainActor
    func testLogin_MultipleLoginsSameAccount() async throws {
        // Given: A registered user
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
        
        let accountId = registerResponse.account.id
        try await APIService.logout()
        
        // When: User logs in multiple times
        let login1 = try await APIService.login(email: email, password: password)
        let token1 = login1.token
        
        try await APIService.logout()
        
        let login2 = try await APIService.login(email: email, password: password)
        let token2 = login2.token
        
        try await APIService.logout()
        
        let login3 = try await APIService.login(email: email, password: password)
        let token3 = login3.token
        
        // Then: Each login returns a valid token
        XCTAssertFalse(token1.isEmpty)
        XCTAssertFalse(token2.isEmpty)
        XCTAssertFalse(token3.isEmpty)
        
        // And: All logins return same account
        XCTAssertEqual(login1.account.id, accountId)
        XCTAssertEqual(login2.account.id, accountId)
        XCTAssertEqual(login3.account.id, accountId)
        }
    
    @MainActor
    func testLogin_AfterLogout_RequiresReauthentication() async throws {
        // Given: User is logged in
        let email = "test\(UUID())@example.com"
        let password = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        // Verify authenticated
        XCTAssertTrue(APIService.isAuthenticated())
        let account1 = try await APIService.getMyAccount()
        XCTAssertEqual(account1.email, email)
        
        // When: User logs out
        try await APIService.logout()
        
        // Then: Token is cleared
        XCTAssertNil(APIService.getAuthToken())
        XCTAssertFalse(APIService.isAuthenticated())
        
        // And: Cannot access protected endpoints
        do {
            _ = try await APIService.getMyAccount()
            XCTFail("Should not be able to access protected endpoint after logout")
        } catch APIError.unauthorized {
            // Expected
        }
        
        // When: User logs back in
        _ = try await APIService.login(email: email, password: password)
        
        // Then: Can access protected endpoints again
        let account2 = try await APIService.getMyAccount()
        XCTAssertEqual(account2.email, email)
    }
    
    // LOGIN FORM VALIDATION TESTS
    
    func testLoginFormValidation_EmailValidation() {
        // Valid emails
        XCTAssertTrue(isLoginFormValid(email: "user@example.com", password: "password123"))
        XCTAssertTrue(isLoginFormValid(email: "test.user@example.com", password: "password123"))
        XCTAssertTrue(isLoginFormValid(email: "user+tag@example.co.uk", password: "password123"))
        
        // Invalid emails
        XCTAssertFalse(isLoginFormValid(email: "notanemail", password: "password123"))
        XCTAssertFalse(isLoginFormValid(email: "@example.com", password: "password123"))
        XCTAssertFalse(isLoginFormValid(email: "user@", password: "password123"))
        XCTAssertFalse(isLoginFormValid(email: "", password: "password123"))
    }
    
    func testLoginFormValidation_PasswordValidation() {
        // Valid password
        XCTAssertTrue(isLoginFormValid(email: "user@example.com", password: "password123"))
        
        // Empty password
        XCTAssertFalse(isLoginFormValid(email: "user@example.com", password: ""))
        
        // Whitespace-only password
        XCTAssertFalse(isLoginFormValid(email: "user@example.com", password: "   "))
    }
    
    func testLoginFormValidation_BothFieldsRequired() {
        // Both empty
        XCTAssertFalse(isLoginFormValid(email: "", password: ""))
        
        // Email only
        XCTAssertFalse(isLoginFormValid(email: "user@example.com", password: ""))
        
        // Password only
        XCTAssertFalse(isLoginFormValid(email: "", password: "password123"))
        
        // Both provided
        XCTAssertTrue(isLoginFormValid(email: "user@example.com", password: "password123"))
    }
    
    func testLoginFormValidation_EmailCaseInsensitive() {
        // Email validation should accept any case
        XCTAssertTrue(isLoginFormValid(email: "USER@EXAMPLE.COM", password: "password123"))
        XCTAssertTrue(isLoginFormValid(email: "User@Example.Com", password: "password123"))
        XCTAssertTrue(isLoginFormValid(email: "user@example.com", password: "password123"))
    }
    
    // LOGIN WITH SPECIAL CHARACTERS
    
    @MainActor
    func testLogin_WithSpecialCharactersInPassword() async throws {
        // Given: User with special characters in password
        let email = "test\(UUID())@example.com"
        let passwordWithSpecialChars = "P@ssw0rd!#$%"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: passwordWithSpecialChars
        )
        
        try await APIService.logout()
        
        // When: User logs in with special characters in password
        let loginResponse = try await APIService.login(
            email: email,
            password: passwordWithSpecialChars
        )
        
        // Then: Login succeeds
        XCTAssertEqual(loginResponse.message, "Login successful")
        XCTAssertNotNil(APIService.getAuthToken())
        XCTAssertTrue(APIService.isAuthenticated())
    }
    
    @MainActor
    func testLogin_WithEmailPlusAddressing() async throws {
        // Given: User with + in email (plus addressing)
        let email = "test+tag\(UUID())@example.com"
        let password = "password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        try await APIService.logout()
        
        // When: User logs in with email containing +
        let loginResponse = try await APIService.login(
            email: email,
            password: password
        )
        
        // Then: Login succeeds
        XCTAssertEqual(loginResponse.message, "Login successful")
        XCTAssertEqual(loginResponse.account.email, email)
    }
    
    // LOGIN ERROR RECOVERY TESTS
    @MainActor
    func testLogin_AfterFailedAttempt_SucceedsWithCorrectPassword() async throws {
        // Given: A registered user
        let email = "test\(UUID())@example.com"
        let correctPassword = "password123"
        let wrongPassword = "wrongpassword"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: correctPassword
        )
        
        try await APIService.logout()
        
        // When: First attempt with wrong password
        do {
            _ = try await APIService.login(email: email, password: wrongPassword)
            XCTFail("Should fail with wrong password")
        } catch {
            // Expected failure
        }
        
        // And: Second attempt with correct password
        let loginResponse = try await APIService.login(
            email: email,
            password: correctPassword
        )
        
        // Then: Login succeeds
        XCTAssertEqual(loginResponse.message, "Login successful")
        XCTAssertNotNil(APIService.getAuthToken())
        XCTAssertTrue(APIService.isAuthenticated())
    }
    
    @MainActor
    func testLogin_PasswordCaseSensitivity() async throws {
        // Given: User with password "Password123"
        let email = "test\(UUID())@example.com"
        let password = "Password123"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        _ = try await APIService.createAccount(
            name: "Test User",
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        try await APIService.logout()
        
        // When: Try to login with different case
        do {
            _ = try await APIService.login(email: email, password: "password123")
            XCTFail("Password should be case-sensitive")
        } catch {
            // Expected - password is case-sensitive
        }
        
        // When: Login with correct case
        let loginResponse = try await APIService.login(email: email, password: password)
        
        // Then: Succeeds
        XCTAssertEqual(loginResponse.message, "Login successful")
    }
    
    // LOGIN TO PROTECTED ENDPOINTS FLOW
    
    @MainActor
    func testLogin_ThenAccessProtectedEndpoints() async throws {
        // Given: User logs in
        let email = "test\(UUID())@example.com"
        let password = "password123"
        let name = "Test User"
        let dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        
        let registerResponse = try await APIService.createAccount(
            name: name,
            email: email,
            phone: "1234567890",
            dateOfBirth: dateOfBirth,
            password: password
        )
        
        try await APIService.logout()
        
        _ = try await APIService.login(email: email, password: password)
        
        // When: Access various protected endpoints
        
        // Get account details
        let account = try await APIService.getMyAccount()
        XCTAssertEqual(account.id, registerResponse.account.id)
        XCTAssertEqual(account.name, name)
        XCTAssertEqual(account.email, email)
    }
    
    @MainActor
    func testLogin_WithoutToken_CannotAccessProtectedEndpoints() async throws {
        // Given: No authentication token
        clearAuthToken()
        XCTAssertNil(APIService.getAuthToken())
        XCTAssertFalse(APIService.isAuthenticated())
        
        // When: Try to access protected endpoint
        do {
            _ = try await APIService.getMyAccount()
            XCTFail("Should not be able to access protected endpoint without token")
        } catch APIError.unauthorized {
            // Then: Get unauthorized error
            // This is expected
        }
    }
    
    // HELPER FUNCTIONS
    
    private func clearAuthToken() {
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
    
    private func isLoginFormValid(email: String, password: String) -> Bool {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return isValidEmail(email) && !trimmedPassword.isEmpty
    }
}
