//
//  AdminReportsView.swift
//  TwiKasa
//
//  Created by Throw Catchers on 1/26/26.
//


import SwiftUI

struct AdminReportsView: View {
    @State private var reports: [ReportItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading reports...")
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                }
            } else if reports.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("No reports!")
                        .font(.headline)
                    Text("All clear for now")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(reports) { report in
                        ReportRow(report: report)
                    }
                    .onDelete(perform: deleteReports)
                }
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !reports.isEmpty {
                EditButton()
            }
        }
        .task {
            await loadReports()
        }
        .refreshable {
            await loadReports()
        }
    }
    
    private func loadReports() async {
        do {
            let fetched = try await AdminService.shared.fetchReports()
            await MainActor.run {
                reports = fetched
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Couldn't load reports"
                isLoading = false
            }
        }
    }
    
    private func deleteReports(at offsets: IndexSet) {
        let reportsToDelete = offsets.map { reports[$0] }
        reports.remove(atOffsets: offsets)
        
        Task {
            for report in reportsToDelete {
                try? await AdminService.shared.deleteReport(report.id)
            }
        }
    }
}

struct ReportRow: View {
    let report: ReportItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(report.contextEmoji)
                
                if !report.contextLabel.isEmpty {
                    Text(report.contextLabel)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text(report.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(report.typeLabel)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            if !report.description.isEmpty {
                Text(report.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
            }
            
            if !report.contextId.isEmpty {
                Text("ID: \(report.contextId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AdminReportsView()
    }
}