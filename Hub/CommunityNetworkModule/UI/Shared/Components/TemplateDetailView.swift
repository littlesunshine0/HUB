import SwiftUI

// MARK: - Template Detail View

public struct CloudTemplateDetailView: View {
    let template: CloudTemplate
    @ObservedObject var cloudService: CloudKitService
    let onDownload: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var comments: [TemplateComment] = []
    @State private var ratings: [TemplateRating] = []
    @State private var newComment = ""
    @State private var userRating: Double = 5.0
    @State private var isLoading = false
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 16) {
                        Image(systemName: template.icon)
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                            .frame(width: 100, height: 100)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.title)
                                .bold()
                            
                            Label(template.category.rawValue, systemImage: template.category.icon)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { index in
                                        Image(systemName: index < Int(template.rating) ? "star.fill" : "star")
                                            .foregroundStyle(.yellow)
                                    }
                                    Text(String(format: "%.1f", template.rating))
                                }
                                
                                Text("•")
                                    .foregroundStyle(.secondary)
                                
                                Text("\(template.downloadCount) downloads")
                            }
                            .font(.caption)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(template.templateDescription)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Features")
                            .font(.headline)
                        ForEach(template.features, id: \.self) { feature in
                            Label(feature, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    // Author & Version
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Author")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(template.author)
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Version")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(template.version)
                                .font(.body)
                        }
                    }
                    
                    Divider()
                    
                    // Rate this template
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rate this template")
                            .font(.headline)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { index in
                                Button {
                                    userRating = Double(index)
                                } label: {
                                    Image(systemName: index <= Int(userRating) ? "star.fill" : "star")
                                        .foregroundStyle(.yellow)
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                            
                            Button("Submit Rating") {
                                Task {
                                    await submitRating()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Divider()
                    
                    // Comments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comments (\(comments.count))")
                            .font(.headline)
                        
                        // Add comment
                        HStack {
                            TextField("Add a comment...", text: $newComment)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Post") {
                                Task {
                                    await postComment()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newComment.isEmpty)
                        }
                        
                        // Comment list
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.userID)
                                        .font(.caption)
                                        .bold()
                                    Spacer()
                                    Text(comment.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text(comment.comment)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Template Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await onDownload()
                        }
                    } label: {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 600, height: 700)
        .task {
            await loadDetails()
        }
    }
    
    private func loadDetails() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            comments = try await cloudService.fetchComments(templateID: template.templateID.uuidString)
            ratings = try await cloudService.fetchTemplateRatings(templateID: template.templateID.uuidString)
        } catch {
            cloudService.errorMessage = "Failed to load details: \(error.localizedDescription)"
        }
    }
    
    private func submitRating() async {
        do {
            try await cloudService.rateTemplate(templateID: template.templateID.uuidString, rating: userRating)
            await loadDetails()
        } catch {
            cloudService.errorMessage = "Failed to submit rating: \(error.localizedDescription)"
        }
    }
    
    private func postComment() async {
        guard !newComment.isEmpty else { return }
        
        do {
            try await cloudService.addComment(templateID: template.templateID.uuidString, comment: newComment)
            newComment = ""
            await loadDetails()
        } catch {
            cloudService.errorMessage = "Failed to post comment: \(error.localizedDescription)"
        }
    }
}
