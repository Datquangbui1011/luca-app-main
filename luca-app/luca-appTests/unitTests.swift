//  luca_appTests.swift
//  luca-appTests

import Foundation
import Testing
@testable import luca_app

struct unitTests {
    
    // EMAIL VALIDATION TESTS
    
    @Test func testValidEmailFormats() async throws {
        let validEmails = [
            "user@example.com",
            "test.user@example.com",
            "user+tag@example.co.uk",
            "user123@test-domain.com"
        ]
        
        for email in validEmails {
            #expect(isValidEmail(email), "Should accept valid email: \(email)")
        }
    }
    
    @Test func testInvalidEmailFormats() async throws {
        let invalidEmails = [
            "invalid.email",
            "@example.com",
            "user@",
            "user @example.com",
            "user@.com",
            ""
        ]
        
        for email in invalidEmails {
            #expect(!isValidEmail(email), "Should reject invalid email: \(email)")
        }
    }
    
    @Test func testEmailCaseSensitivity() async throws {
        let emails = [
            "JOHN@EXAMPLE.COM",
            "john@Example.Com",
            "john@example.com"
        ]
        
        for email in emails {
            #expect(isValidEmail(email), "Email validation should be case-insensitive")
        }
    }
    
    @Test func testEmailWhitespaceHandling() async throws {
        let emailWithSpaces = "  john@example.com  "
        let trimmed = emailWithSpaces.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(isValidEmail(trimmed))
        #expect(isValidEmail(emailWithSpaces))
    }
    
    // PASSWORD VALIDATION TESTS
    
    @Test func testPasswordMinimumLength() async throws {
        #expect(!isValidPassword("abc123"), "Password too short")
        #expect(isValidPassword("abcd1234"), "8 characters minimum")
        #expect(isValidPassword("abcdefgh123"), "Longer password valid")
    }
    
    @Test func testPasswordRequiresNumber() async throws {
        #expect(!isValidPassword("abcdefgh"), "Must contain number")
        #expect(isValidPassword("abcdefgh1"), "Contains number")
    }
    
    @Test func testPasswordRequiresLetter() async throws {
        #expect(!isValidPassword("12345678"), "Must contain letter")
        #expect(isValidPassword("1234567a"), "Contains letter")
    }
    
    @Test func testPasswordCompleteValidation() async throws {
        let validPasswords = [
            "password123",
            "Pass1234",
            "MyP@ssw0rd",
            "test1234"
        ]
        
        for password in validPasswords {
            #expect(isValidPassword(password), "\(password) should be valid")
        }
        
        let invalidPasswords = [
            "short1",
            "1234567",
            "NoNumbers",
            ""
        ]
        
        for password in invalidPasswords {
            #expect(!isValidPassword(password), "\(password) should be invalid")
        }
    }
    
    @Test func testPasswordMatching() async throws {
        #expect(passwordsMatch("password123", "password123"))
        #expect(!passwordsMatch("password123", "password124"))
        #expect(!passwordsMatch("password123", ""))
    }
    
    // PHONE NUMBER VALIDATION TESTS
    
    @Test func testPhoneNumberFormatting() async throws {
        #expect(formatPhoneNumber("1234567890") == "(123) 456-7890")
        #expect(formatPhoneNumber("123") == "(123")
        #expect(formatPhoneNumber("1234") == "(123) 4")
        #expect(formatPhoneNumber("123456") == "(123) 456")
        #expect(formatPhoneNumber("") == "")
    }
    
    @Test func testPhoneNumberDigitExtraction() async throws {
        #expect(extractDigits("(123) 456-7890") == "1234567890")
        #expect(extractDigits("123-456-7890") == "1234567890")
        #expect(extractDigits("abc123def456") == "123456")
        #expect(extractDigits("no digits here") == "")
    }
    
    @Test func testPhoneNumberLengthValidation() async throws {
        #expect(isValidPhoneNumber("1234567890"))
        #expect(isValidPhoneNumber("(123) 456-7890"))
        #expect(!isValidPhoneNumber("123456789"))
        #expect(!isValidPhoneNumber("12345678901"))
    }
    
    @Test func testPhoneNumberTruncation() async throws {
        // Should limit to 10 digits
        let formatted = formatPhoneNumber("12345678901234")
        let digits = extractDigits(formatted)
        #expect(digits.count == 10)
    }
    
    // DATE OF BIRTH VALIDATION TESTS
    
    @Test func testAgeCalculation() async throws {
        let calendar = Calendar.current
        
        // 25 years ago
        let date25YearsAgo = calendar.date(byAdding: .year, value: -25, to: Date())!
        #expect(calculateAge(from: date25YearsAgo) == 25)
        
        // 13 years ago
        let date13YearsAgo = calendar.date(byAdding: .year, value: -13, to: Date())!
        #expect(calculateAge(from: date13YearsAgo) == 13)
        
        // 12 years ago (not old enough)
        let date12YearsAgo = calendar.date(byAdding: .year, value: -12, to: Date())!
        #expect(calculateAge(from: date12YearsAgo) == 12)
    }
    
    @Test func testMinimumAgeRequirement() async throws {
        let calendar = Calendar.current
        
        let date13YearsAgo = calendar.date(byAdding: .year, value: -13, to: Date())!
        #expect(meetsMinimumAge(date13YearsAgo, minimum: 13))
        
        let date12YearsAgo = calendar.date(byAdding: .year, value: -12, to: Date())!
        #expect(!meetsMinimumAge(date12YearsAgo, minimum: 13))
    }
    
    
    // TEMPERATURE CONVERSION TESTS
    
    @Test func testFahrenheitToCelsius() async throws {
        #expect(abs(fahrenheitToCelsius(98.6) - 37.0) < 0.1)
        #expect(abs(fahrenheitToCelsius(32.0) - 0.0) < 0.1)
        #expect(abs(fahrenheitToCelsius(212.0) - 100.0) < 0.1)
    }
    
    @Test func testCelsiusToFahrenheit() async throws {
        #expect(abs(celsiusToFahrenheit(37.0) - 98.6) < 0.1)
        #expect(abs(celsiusToFahrenheit(0.0) - 32.0) < 0.1)
        #expect(abs(celsiusToFahrenheit(100.0) - 212.0) < 0.1)
    }
    
    @Test func testTemperatureUnitDetection() async throws {
        #expect(detectTemperatureUnit(37.0) == .celsius)
        #expect(detectTemperatureUnit(98.6) == .fahrenheit)
        #expect(detectTemperatureUnit(69.9) == .celsius)
        #expect(detectTemperatureUnit(70.0) == .fahrenheit)
    }
    
    @Test func testTemperatureRangeValidation() async throws {
        // Normal body temperature ranges
        #expect(isTemperatureInRange(37.0, unit: .celsius))
        #expect(isTemperatureInRange(98.6, unit: .fahrenheit))
        
        // Out of range
        #expect(!isTemperatureInRange(40.0, unit: .celsius))
        #expect(!isTemperatureInRange(120.0, unit: .fahrenheit))
    }
    
    // VITAL SIGNS VALIDATION TESTS
    
    @Test func testHeartRateValidation() async throws {
        #expect(isHeartRateValid(120))
        #expect(isHeartRateValid(70))
        #expect(isHeartRateValid(180))
        
        #expect(!isHeartRateValid(69))
        #expect(!isHeartRateValid(181))
        #expect(!isHeartRateValid(0))
    }
    
    @Test func testBloodPressureMAPValidation() async throws {
        // For gestational age 24.0-29.9 weeks: 24-40
        #expect(isMAPValid(30, gestationalAge: "24.0-29.9 weeks"))
        #expect(!isMAPValid(20, gestationalAge: "24.0-29.9 weeks"))
        #expect(!isMAPValid(45, gestationalAge: "24.0-29.9 weeks"))
        
        // For gestational age 30.0-35.9 weeks: 30-45
        #expect(isMAPValid(35, gestationalAge: "30.0-35.9 weeks"))
        #expect(!isMAPValid(28, gestationalAge: "30.0-35.9 weeks"))
        
        // For gestational age 36.0+ weeks: 35-50
        #expect(isMAPValid(40, gestationalAge: "36.0+ weeks"))
        #expect(!isMAPValid(55, gestationalAge: "36.0+ weeks"))
    }
    
    @Test func testRespiratoryRateValidation() async throws {
        #expect(isRespiratoryRateValid(40))
        #expect(isRespiratoryRateValid(20))
        #expect(isRespiratoryRateValid(80))
        
        #expect(!isRespiratoryRateValid(19))
        #expect(!isRespiratoryRateValid(81))
    }
    
    @Test func testOxygenSaturationValidation() async throws {
        #expect(isOxygenSaturationValid(96))
        #expect(isOxygenSaturationValid(85))
        #expect(isOxygenSaturationValid(100))
        
        #expect(!isOxygenSaturationValid(84))
        #expect(!isOxygenSaturationValid(101))
    }
    
    @Test func testVitalSignsNumericParsing() async throws {
        #expect(parseVitalSign("120") == 120.0)
        #expect(parseVitalSign("98.6") == 98.6)
        #expect(parseVitalSign("invalid") == nil)
        #expect(parseVitalSign("") == nil)
        #expect(parseVitalSign("  37.5  ") == 37.5)
    }
    
    // FORM COMPLETION VALIDATION TESTS

    @Test func testSignUpFormCompletion() async throws {
        // All fields filled and valid
        #expect(isSignUpFormValid(
            fullName: "John Doe",
            email: "john@example.com",
            phone: "1234567890",
            dateOfBirth: Date(),
            password: "password123",
            confirmPassword: "password123",
            agreedToTerms: true
        ))
        
        // Missing name
        #expect(!isSignUpFormValid(
            fullName: "",
            email: "john@example.com",
            phone: "1234567890",
            dateOfBirth: Date(),
            password: "password123",
            confirmPassword: "password123",
            agreedToTerms: true
        ))
        
        // Passwords don't match
        #expect(!isSignUpFormValid(
            fullName: "John Doe",
            email: "john@example.com",
            phone: "1234567890",
            dateOfBirth: Date(),
            password: "password123",
            confirmPassword: "password456",
            agreedToTerms: true
        ))
        
        // Terms not agreed
        #expect(!isSignUpFormValid(
            fullName: "John Doe",
            email: "john@example.com",
            phone: "1234567890",
            dateOfBirth: Date(),
            password: "password123",
            confirmPassword: "password123",
            agreedToTerms: false
        ))
    }
    
    @Test func testLoginFormCompletion() async throws {
        #expect(isLoginFormValid(email: "john@example.com", password: "password123"))
        #expect(!isLoginFormValid(email: "", password: "password123"))
        #expect(!isLoginFormValid(email: "john@example.com", password: ""))
        #expect(!isLoginFormValid(email: "invalid", password: "password123"))
    }
    
    @Test func testVitalSignsFormCompletion() async throws {
        #expect(isVitalSignsFormValid(
            heartRate: "120",
            bloodPressure: "35",
            temperature: "98.6",
            respiratoryRate: "40",
            oxygenSaturation: "96"
        ))
        
        #expect(!isVitalSignsFormValid(
            heartRate: "",
            bloodPressure: "35",
            temperature: "98.6",
            respiratoryRate: "40",
            oxygenSaturation: "96"
        ))
        
        #expect(!isVitalSignsFormValid(
            heartRate: "120",
            bloodPressure: "",
            temperature: "",
            respiratoryRate: "",
            oxygenSaturation: ""
        ))
    }
    
    // MARK: - ========================================
    // MARK: - INPUT SANITIZATION TESTS
    // MARK: - ========================================
    
    @Test func testWhitespaceTrimming() async throws {
        #expect(trimWhitespace("  test@example.com  ") == "test@example.com")
        #expect(trimWhitespace("no spaces") == "no spaces")
        #expect(trimWhitespace("   ") == "")
    }
    
    @Test func testEmailLowercasing() async throws {
        #expect(normalizeEmail("USER@EXAMPLE.COM") == "user@example.com")
        #expect(normalizeEmail("User@Example.Com") == "user@example.com")
    }
    
    @Test func testNameValidation() async throws {
        #expect(isValidName("John Doe"))
        #expect(isValidName("Rhett Bobby"))
        #expect(!isValidName("A"))
        #expect(!isValidName(""))
        #expect(!isValidName("   "))
    }
    
    // HELPER FUNCTIONS (extracted from views)
    
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
    
    private enum TemperatureUnit: Equatable {
        case celsius, fahrenheit
    }
    
    private func fahrenheitToCelsius(_ f: Double) -> Double {
        return (f - 32.0) * 5.0 / 9.0
    }
    
    private func celsiusToFahrenheit(_ c: Double) -> Double {
        return (c * 9.0 / 5.0) + 32.0
    }
    
    private func detectTemperatureUnit(_ value: Double) -> TemperatureUnit {
        return value < 70 ? .celsius : .fahrenheit
    }
    
    private func isTemperatureInRange(_ value: Double, unit: TemperatureUnit) -> Bool {
        let celsius = unit == .celsius ? value : fahrenheitToCelsius(value)
        return celsius >= 36.4 && celsius <= 38.0
    }
    
    private func isHeartRateValid(_ hr: Int) -> Bool {
        return hr >= 70 && hr <= 180
    }
    
    private func isMAPValid(_ map: Int, gestationalAge: String) -> Bool {
        let lower = gestationalAge.lowercased()
        if lower.contains("24.0-29.9") {
            return map >= 24 && map <= 40
        } else if lower.contains("30.0-35.9") {
            return map >= 30 && map <= 45
        } else if lower.contains("36") {
            return map >= 35 && map <= 50
        }
        return false
    }
    
    private func isRespiratoryRateValid(_ rr: Int) -> Bool {
        return rr >= 20 && rr <= 80
    }
    
    private func isOxygenSaturationValid(_ o2: Int) -> Bool {
        return o2 >= 85 && o2 <= 100
    }
    
    private func parseVitalSign(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(trimmed)
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
    
    private func isLoginFormValid(email: String, password: String) -> Bool {
        return isValidEmail(email) && !password.isEmpty
    }
    
    private func isVitalSignsFormValid(
        heartRate: String,
        bloodPressure: String,
        temperature: String,
        respiratoryRate: String,
        oxygenSaturation: String
    ) -> Bool {
        return !heartRate.isEmpty &&
               !bloodPressure.isEmpty &&
               !temperature.isEmpty &&
               !respiratoryRate.isEmpty &&
               !oxygenSaturation.isEmpty
    }
    
    private func trimWhitespace(_ value: String) -> String {
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func normalizeEmail(_ email: String) -> String {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2
    }
}
