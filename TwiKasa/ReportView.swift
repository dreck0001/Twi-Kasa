import SwiftUI

struct ReportView: View {
    let context: Report.ReportContext
    let contextId: String?
    let contextLabel: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: ReportType = .wrongDefinition
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    
    init(wordId: String, headword: String) {
        self.context = .word
        self.contextId = wordId
        self.contextLabel = headword
    }
    
    init(searchQuery: String) {
        self.context = .search
        self.contextId = nil
        self.contextLabel = searchQuery
    }
    
    init() {
        self.context = .general
        self.contextId = nil
        self.contextLabel = nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let label = contextLabel {
                    Section {
                        HStack {
                            Text(contextTitle)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(label)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Section("What's the issue?") {
                    ForEach(ReportType.allCases) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .frame(width: 24)
                                    .foregroundColor(.primary)
                                
                                Text(type.label)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Details (optional)") {
                    TextField("Tell us more...", text: $description, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(isSubmitting)
                }
            }
            .alert("Thanks!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("We'll look into this soon.")
            }
            .alert("Oops", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text("Something went wrong. Try again later.")
            }
        }
    }
    
    private var contextTitle: String {
        switch context {
        case .word: return "Word"
        case .search: return "Search"
        case .general: return "Topic"
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        let report = Report(
            context: context,
            contextId: contextId,
            contextLabel: contextLabel,
            type: selectedType,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        Task {
            do {
                try await ReportService.shared.submitReport(report)
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    showError = true
                }
            }
        }
    }
}

#Preview("Word Report") {
    ReportView(wordId: "odo", headword: "ɔdɔ")
}

#Preview("Search Report") {
    ReportView(searchQuery: "hello")
}

#Preview("General Report") {
    ReportView()
}
