import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @AppStorage("showExplicitContent") private var showExplicitContent = true
    @StateObject private var adminService = AdminService.shared
    @State private var showReportSheet = false
    
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
                
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    if let uid = Auth.auth().currentUser?.uid {
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(uid)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = uid
                            } label: {
                                Label("Copy UID", systemImage: "doc.on.doc")
                            }
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showReportSheet) {
                ReportView()
            }
            .onAppear {
                adminService.checkAdminStatus()
            }
        }
    }
}

#Preview {
    SettingsView()
}
