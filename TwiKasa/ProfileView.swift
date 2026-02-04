//
//  ProfileView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/27/26.
//


import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @AppStorage("showExplicitContent") private var showExplicitContent = true
    @StateObject private var adminService = AdminService.shared
    @ObservedObject private var authService = AuthService.shared
    @State private var showReportSheet = false
    @State private var showSignInSheet = false
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // profile/sign in section
                profileSection
                
                // settings
                Section {
                    Toggle(isOn: $showExplicitContent) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Explicit Content")
                            Text("Display words with explicit meanings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Content")
                }
                
                // feedback
                Section {
                    Button {
                        showReportSheet = true
                    } label: {
                        HStack {
                            Label("Send Feedback", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Feedback")
                }
                
                // admin (if applicable)
                if adminService.isAdmin {
                    Section {
                        NavigationLink {
                            AdminReportsView()
                        } label: {
                            Label("View Reports", systemImage: "flag")
                        }
                    } header: {
                        Text("Admin")
                    }
                }
                
                // about
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    if let uid = Auth.auth().currentUser?.uid {
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(String(uid.prefix(12)) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = uid
                            } label: {
                                Label("Copy Full ID", systemImage: "doc.on.doc")
                            }
                        }
                    }
                } header: {
                    Text("About")
                }
                
                // sign out
                if authService.isSignedIn {
                    Section {
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showReportSheet) {
                ReportView()
            }
            .sheet(isPresented: $showSignInSheet) {
                SignInView()
            }
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Keep Favorites") {
                    // sign out but keep local favorites
                    authService.signOut()
                }
                Button("Clear Favorites", role: .destructive) {
                    // sign out and clear local favorites
                    FavoritesManager.shared.clearLocalOnSignOut()
                    authService.signOut()
                }
            } message: {
                Text("Your favorites are saved to your account. Keep them on this device or clear them?")
            }
            .onAppear {
                adminService.checkAdminStatus()
            }
        }
    }
    
    @ViewBuilder
    private var profileSection: some View {
        Section {
            if authService.isSignedIn {
                // signed in state
                HStack(spacing: 14) {
                    profileImage
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(displayNameOrFallback)
                            .font(.headline)
                        
                        if let email = authService.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 6)
            } else {
                // signed out state
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Sign in to TwiKasa")
                        .font(.headline)
                    
                    Text("Get credit for contributions and sync across devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showSignInSheet = true
                    } label: {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // show displayName, or email username, or "User" as last resort
    private var displayNameOrFallback: String {
        if let name = authService.displayName, !name.isEmpty {
            return name
        }
        if let email = authService.email {
            // extract username from email (part before @)
            let username = email.components(separatedBy: "@").first ?? email
            return username.capitalized
        }
        return "User"
    }
    
    private var profileImage: some View {
        Group {
            if let url = authService.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }
    
    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            )
    }
}

#Preview {
    ProfileView()
}
