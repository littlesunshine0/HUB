import SwiftUI

// MARK: - Community Template Card

struct CommunityTemplateCard: View {
    let template: CloudTemplate
    let onDownload: () async -> Void
    let onViewDetails: () -> Void
    
    @State private var isDownloading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with cloud badge
            HStack {
                Image(systemName: template.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(template.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        // Cloud source badge
                        HStack(spacing: 2) {
                            Image(systemName: "icloud")
                                .font(.caption2)
                            Text("Cloud")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundStyle(.purple)
                        .cornerRadius(4)
                    }
                    
                    Label(template.category.rawValue, systemImage: template.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", template.rating))
                        Text("•")
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                        Text("\(template.downloadCount)")
                    }
                    .font(.caption2)
                }
                
                Spacer()
            }
            
            // Description
            Text(template.templateDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(height: 32)
            
            // Author
            HStack {
                Image(systemName: "person.fill")
                    .font(.caption2)
                Text(template.author)
                    .font(.caption2)
                Spacer()
                Text(template.version)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(template.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    onViewDetails()
                } label: {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    isDownloading = true
                    Task {
                        await onDownload()
                        isDownloading = false
                    }
                } label: {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Download", systemImage: "arrow.down.circle.fill")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDownloading)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
