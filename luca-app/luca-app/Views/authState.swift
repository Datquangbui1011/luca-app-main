import Foundation

enum AuthState: Equatable {
    case welcome
    case login
    case signup
    case resetPassword
    case newPassword(token: String)
}
