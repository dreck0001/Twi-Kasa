//
//  ProfileView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/12/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                
                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Settings & preferences")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Coming soon!")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}
