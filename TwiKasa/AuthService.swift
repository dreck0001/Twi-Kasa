import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

class AuthService: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    static let shared = AuthService()
    
    @Published var user: User?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentNonce: String?
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private override init() {
        super.init()
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isSignedIn = user != nil && !(user?.isAnonymous ?? true)
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    var isAnonymous: Bool {
        Auth.auth().currentUser?.isAnonymous ?? true
    }
    
    var displayName: String? {
        Auth.auth().currentUser?.displayName
    }
    
    var email: String? {
        Auth.auth().currentUser?.email
    }
    
    var photoURL: URL? {
        Auth.auth().currentUser?.photoURL
    }
    
    var uid: String? {
        Auth.auth().currentUser?.uid
    }
    
    // MARK: - Apple Sign In
    
    func startAppleSignIn() {
        // prevent duplicate attempts
        guard !isLoading else { return }
        
        isLoading = true
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                signInWithApple(credential: appleIDCredential)
            }
        case .failure(let error):
            DispatchQueue.main.async {
                // don't show error if user just cancelled
                if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
    
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce,
              let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.errorMessage = "Unable to process Apple sign in"
                self.isLoading = false
            }
            return
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        let displayName = credential.fullName?.formatted()
        
        // clear nonce after use
        currentNonce = nil
        
        // sign in directly with Apple credential
        performSignIn(with: firebaseCredential, displayName: displayName)
    }
    
    private func performSignIn(with credential: AuthCredential, displayName: String? = nil) {
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Sign in error: \(error.localizedDescription)")
                    self?.errorMessage = "Sign in failed. Please try again."
                    self?.isLoading = false
                }
                return
            }
            
            // reload user to ensure we have latest profile data
            Auth.auth().currentUser?.reload { _ in
                DispatchQueue.main.async {
                    self?.user = Auth.auth().currentUser
                    self?.isSignedIn = true
                    self?.isLoading = false
                    
                    // update displayName if Apple provided one (first sign-in only)
                    if let name = displayName, !name.isEmpty {
                        self?.updateDisplayName(name)
                    }
                }
            }
        }
    }
    
    private func updateDisplayName(_ name: String) {
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.commitChanges { [weak self] _ in
            // refresh user to get updated name
            DispatchQueue.main.async {
                self?.user = Auth.auth().currentUser
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isSignedIn = false
                self.isLoading = false
                self.currentNonce = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            signInWithApple(credential: appleIDCredential)
        } else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            let nsError = error as NSError
            // don't show error if user cancelled
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                // provide friendlier error message
                if nsError.domain == ASAuthorizationError.errorDomain {
                    self.errorMessage = "Apple Sign In failed. Please try again."
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
}
