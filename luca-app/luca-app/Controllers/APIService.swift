//
//  APIService.swift
//  luca-app
//
//  API Service for connecting to FastAPI backend
//

import Foundation
import Security

// MARK: - Models

struct AccountResponse: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String
    let date_of_birth: String
    let created_at: String?
    let last_login: String?
}

struct AccountCreateRequest: Codable {
    let name: String
    let email: String
    let phone: String
    let date_of_birth: String  // Format: YYYY-MM-DD
    let password: String
}

struct RegisterResponse: Codable {
    let message: String
    let token: String
    let account: AccountResponse
}

struct LoginCredentials: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let message: String
    let token: String
    let account: AccountResponse
}

struct ErrorResponse: Codable {
    let detail: String
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed
    case decodingFailed
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed:
            return "Request failed"
        case .decodingFailed:
            return "Failed to decode response"
        case .unauthorized:
            return "Unauthorized"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - API Service

class APIService {
    // Change this to your computer's local IP when testing on physical device
    // For simulator: use "localhost"
    // For physical device: use your computer's IP (e.g., "192.168.1.x")
    static let baseURL = "https://luca-app-dev.onrender.com"
    
    // MARK: - Health Checks
    
    static func healthCheck() async throws -> [String: String] {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Debug: Print what we received
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Health check response: \(jsonString)")
        }
        
        let response = try JSONDecoder().decode([String: String].self, from: data)
        return response
    }
    
    // MARK: - Authentication
    
    /// Register a new account
    static func createAccount(
        name: String,
        email: String,
        phone: String,
        dateOfBirth: Date,
        password: String
    ) async throws -> RegisterResponse {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert Date to YYYY-MM-DD format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = dateFormatter.string(from: dateOfBirth)
        
        let body = AccountCreateRequest(
            name: name,
            email: email,
            phone: phone,
            date_of_birth: dobString,
            password: password
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Debug: Print response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Register response (\(httpResponse.statusCode)): \(jsonString)")
        }
        
        switch httpResponse.statusCode {
        case 201:
            let registerResponse = try JSONDecoder().decode(RegisterResponse.self, from: data)
            
            // Save the token to Keychain
            saveAuthToken(registerResponse.token)
            
            return registerResponse
            
        case 400:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.detail ?? "Email already registered")
            
        case 422:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.detail ?? "Invalid input data")
            
        default:
            throw APIError.serverError("Failed to create account")
        }
    }
    
    /// Login to existing account
    static func login(email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = LoginCredentials(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(credentials)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Debug: Print response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Login response (\(httpResponse.statusCode)): \(jsonString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            // Save the token to Keychain
            saveAuthToken(loginResponse.token)
            
            return loginResponse
            
        case 401:
            throw APIError.serverError("Invalid email or password")
            
        case 429:
            throw APIError.serverError("Too many login attempts. Please try again later.")
            
        default:
            throw APIError.serverError("Login failed")
        }
    }
    
    /// Logout (invalidate token)
    static func logout() async throws {
        guard let token = getAuthToken() else {
            return
        }
        
        guard let url = URL(string: "\(baseURL)/auth/logout/token") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
        
        // Remove token from Keychain
        deleteAuthToken()
    }
    
    // MARK: - Protected Endpoints (Require Authentication)
    
    /// Get current user's account information
    static func getMyAccount() async throws -> AccountResponse {
        guard let token = getAuthToken() else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/accounts/me") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(AccountResponse.self, from: data)
        case 401:
            deleteAuthToken()
            throw APIError.unauthorized
        default:
            throw APIError.requestFailed
        }
    }
    
    static func deleteMyAccount() async throws {
        guard let token = getAuthToken() else {
            throw APIError.unauthorized
        }
        
        // First get account ID
        let account = try await getMyAccount()
        
        guard let url = URL(string: "\(baseURL)/accounts/\(account.id)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
        
        // Remove token from Keychain
        deleteAuthToken()
    }
        
    static func getAllAccounts() async throws -> [AccountResponse] {
        guard let token = getAuthToken() else {
            throw APIError.unauthorized
        }
        
        guard let url = URL(string: "\(baseURL)/admin/accounts") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Get all accounts response (\(httpResponse.statusCode)): \(jsonString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([AccountResponse].self, from: data)
        case 401:
            deleteAuthToken()
            throw APIError.unauthorized
        default:
            throw APIError.requestFailed
        }
    }
        
    static func requestPasswordReset(email: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/password/forgot") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 400..<500:
            let msg = String(data: data, encoding: .utf8) ?? "Invalid request."
            throw APIError.serverError(msg)
        default:
            throw APIError.requestFailed
        }
    }
    
    static func resetPassword(token: String, newPassword: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/password/reset") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "token": token,
            "new_password": newPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 400:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.detail ?? "Invalid or expired reset token")
        default:
            throw APIError.serverError("Failed to reset password")
        }
    }

    private static func saveAuthToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Delete old token if exists
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("Token saved to Keychain")
        } else {
            print("Failed to save token: \(status)")
        }
    }
    
    // Get auth token from keychain
    static func getAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    /// Delete authentication token from Keychain
    private static func deleteAuthToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken"
        ]
        
        SecItemDelete(query as CFDictionary)
        print("🗑️ Token deleted from Keychain")
    }
    
    /// Check if user is authenticated (has valid token)
    static func isAuthenticated() -> Bool {
        return getAuthToken() != nil
    }
}
