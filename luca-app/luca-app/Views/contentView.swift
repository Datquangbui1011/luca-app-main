import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var authState: AuthState = .welcome
    
    var body: some View {
        Group {
            if isAuthenticated {
                HomePageView(isAuthenticated: $isAuthenticated)
            } else {
                switch authState {
                    case .welcome:
                        WelcomeView(
                            isAuthenticated: $isAuthenticated,
                            authState: $authState
                        )
                    case .login:
                        LoginView(
                            isAuthenticated: $isAuthenticated,
                            authState: $authState
                        )
                    case .signup:
                        SignUpView(
                            isAuthenticated: $isAuthenticated,
                            authState: $authState
                        )
                    case .resetPassword:
                        ResetPassword(authState: $authState)
                    case .newPassword(let token):
                        NewPasswordView(
                            authState: $authState,
                            resetToken: token
                        )
                }
            }
        }
        .animation(.easeInOut, value: isAuthenticated)
        .animation(.easeInOut, value: authState)
        .onOpenURL { url in
            handlePasswordResetLink(url)
        }
    }
    private func handlePasswordResetLink(_ url: URL) {
            // Email link will be: yourapp://reset-password?token=abc123
            if url.host == "reset-password" || url.path.contains("reset-password"),
               let token = url.queryParameters?["token"] {
                // Navigate to new password screen with token
                authState = .newPassword(token: token)
            }
        }
    }

    // Helper extension to parse URL query parameters
    extension URL {
        var queryParameters: [String: String]? {
            guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return nil
            }
            return Dictionary(uniqueKeysWithValues: queryItems.compactMap {
                guard let value = $0.value else { return nil }
                return ($0.name, value)
            })
        }
    }

#Preview {
    ContentView()
}
