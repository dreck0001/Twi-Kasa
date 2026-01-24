import SwiftUI

struct ProfileView: View {
    @AppStorage("showExplicitContent") private var showExplicitContent = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $showExplicitContent) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Explicit Content")
                                .font(.body)
                            Text("Display words with explicit or sensitive meanings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Content Filtering")
                }
                
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ProfileView()
}
