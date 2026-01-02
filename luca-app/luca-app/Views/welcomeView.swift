import SwiftUI

struct WelcomeView: View {
    @Binding var isAuthenticated: Bool
    @Binding var authState: AuthState
    
    var body: some View {
        ZStack {
                // Background color
                Color(hex: "F5E8C7")
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo/App Name
                    VStack(spacing: 16) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 220)
                            .offset(x: -25, y: 0) 
                        
                       
                    }
                    
                    // Welcome text in center
                    Text("Welcome, future nurse leaders, your journey to excellence and support starts now.")
                        .font(.custom("Georgia-Italic", size: 14))
                        .foregroundStyle(.black.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 16) {
                        Button {
                            withAnimation {
                                authState = .login
                            }
                        } label: {
                            Text("Login")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 200)
                                .frame(height: 56)
                                .background(Color(hex: "D9B53E"))
                                .cornerRadius(30)
                        }
                        
                        Button {
                            withAnimation {
                                authState = .signup
                            }
                        } label: {
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 200)
                                .frame(height: 56)
                                .background(Color(hex: "D9B53E"))
                                .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
    }

// Color extension to support hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

