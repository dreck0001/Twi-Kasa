import SwiftUI

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authService = AuthService.shared
    @State private var showError = false
    
    var body: some View {
        ZStack {
            // porcupine background (same as launch screen)
            Image("porcupine")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            // dark overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // logo area (matching launch screen)
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("Twi")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(" Kasa")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    
                    HStack(spacing: 6) {
                        Text("/ʧwi kasa/")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // welcome text
                VStack(spacing: 8) {
                    Text("Welcome!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Sign in to get credit for your contributions")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 32)
                
                // sign in buttons - side by side
                HStack(spacing: 16) {
                    // Google button
                    Button {
                        authService.errorMessage = "Google Sign In coming soon"
                        showError = true
                    } label: {
                        HStack(spacing: 8) {
                            Image("google")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Google")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white.opacity(0.03))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Apple button
                    Button {
                        authService.startAppleSignIn()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.title3)
                            Text("Apple")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white.opacity(0.03))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 70)
                
                // divider with fading lines
                HStack(spacing: 16) {
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    
                    Text("Or")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                }
                .padding(.horizontal, 90)
                .padding(.vertical, 24)
                
                // continue as guest
                Button {
                    dismiss()
                } label: {
                    Text("Continue as Guest")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white.opacity(0.03))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 70)
                
                Spacer()
                    .frame(height: 60)
            }
            
            // loading overlay
            if authService.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .alert("Oops", isPresented: $showError) {
            Button("OK") {
                authService.clearError()
            }
        } message: {
            Text(authService.errorMessage ?? "Something went wrong")
        }
        .onChange(of: authService.errorMessage) { _, newValue in
            if newValue != nil {
                showError = true
            }
        }
        .onChange(of: authService.isSignedIn) { _, signedIn in
            if signedIn {
                dismiss()
            }
        }
    }
}

#Preview {
    SignInView()
}
