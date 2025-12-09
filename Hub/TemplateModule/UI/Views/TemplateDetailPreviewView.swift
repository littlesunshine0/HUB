import SwiftUI

/// Detailed template view with live preview and actions
struct TemplateDetailPreviewView: View {
    let template: TemplateModel
    let templateManager: TemplateManager
    let onEdit: () -> Void
    let onEditCode: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @State private var selectedTab: DetailTab = .overview
    @State private var showingLivePreview = false
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case features = "Features"
        case code = "Code"
        case preview = "Preview"
        case reviews = "Reviews"
        case analytics = "Analytics"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            ScrollView {
                switch selectedTab {
                case .overview:
                    overviewTab
                case .features:
                    featuresTab
                case .code:
                    codeTab
                case .preview:
                    previewTab
                case .reviews:
                    reviewsTab
                case .analytics:
                    analyticsTab
                }
            }
            
            Divider()
            
            // Actions
            actionsView
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: template.icon)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            // Name
            Text(template.name)
                .font(.title2)
                .fontWeight(.bold)
            
            // Category
            Text(template.category.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Rating
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(template.averageRating.rounded()) ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Text(String(format: "%.1f", template.averageRating))
                    .font(.caption)
                Text("(\(template.reviewCount) reviews)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Stats
            HStack(spacing: 20) {
                TemplateStatBadge(icon: "arrow.down.circle.fill", value: "\(template.downloadCount)", label: "Downloads")
                TemplateStatBadge(icon: "eye.fill", value: "\(template.viewCount)", label: "Views")
                TemplateStatBadge(icon: "calendar", value: template.updatedAt, style: .date, label: "Updated")
            }
            .font(.caption)
            
            // Badges
            HStack(spacing: 8) {
                if template.isFeatured {
                    Text("Featured")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                if template.isBuiltIn {
                    Text("Built-in")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                if template.isVisualTemplate {
                    Text("Visual")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            GroupBox("Description") {
                Text(template.templateDescription)
                    .font(.body)
                    .padding()
            }
            
            // Author
            GroupBox("Author") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(template.author)
                            .font(.headline)
                        Text("Version \(template.version)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
            }
            
            // Tags
            if !template.tags.isEmpty {
                GroupBox("Tags") {
                    WelcomeFlowLayout(spacing: 8) {
                        ForEach(template.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                }
            }
            
            // Dependencies
            if !template.dependencies.isEmpty {
                GroupBox("Dependencies") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(template.dependencies, id: \.self) { dep in
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundStyle(.orange)
                                Text(dep)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Features Tab
    
    private var featuresTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Features") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(template.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.body)
                        }
                    }
                }
                .padding()
            }
            
            if !template.sharedModules.isEmpty {
                GroupBox("Shared Modules") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(template.sharedModules, id: \.self) { module in
                            HStack {
                                Image(systemName: "cube.fill")
                                    .foregroundStyle(.purple)
                                Text(module)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            if !template.featureToggles.isEmpty {
                GroupBox("Feature Toggles") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(template.featureToggles.keys.sorted()), id: \.self) { key in
                            HStack {
                                Image(systemName: template.featureToggles[key] == true ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(template.featureToggles[key] == true ? .green : .secondary)
                                Text(key)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Code Tab
    
    private var codeTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Source Files") {
                if template.sourceFiles.isEmpty {
                    Text("No source files available")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(template.sourceFiles.keys.sorted()), id: \.self) { filename in
                            DisclosureGroup {
                                ScrollView(.horizontal) {
                                    Text(template.sourceFiles[filename] ?? "")
                                        .font(.system(.caption, design: .monospaced))
                                        .padding()
                                }
                                .frame(maxHeight: 200)
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(.blue)
                                    Text(filename)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            Button {
                onEditCode()
            } label: {
                Label("Edit Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Preview Tab
    
    private var previewTab: some View {
        VStack(spacing: 16) {
            if template.isVisualTemplate {
                GroupBox("Live Preview") {
                    if !template.visualScreens.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(template.visualScreens) { screen in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(screen.name)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    // Render preview
                                    Text("Visual preview: \(screen.components.count) components")
                                        .frame(maxWidth: .infinity, maxHeight: 400)
                                        .background(Color(nsColor: .textBackgroundColor))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .frame(height: 500)
                    } else {
                        Text("No visual screens available")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            } else {
                GroupBox("Preview") {
                    VStack(spacing: 12) {
                        Image(systemName: "eye.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Preview not available for code-based templates")
                            .foregroundStyle(.secondary)
                        Text("Use 'Edit Code' to view and modify the source")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(40)
                }
            }
            
            if template.previewImageData != nil {
                GroupBox("Screenshot") {
                    // Display preview image if available
                    Text("Preview image available")
                        .padding()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Reviews Tab
    
    private var reviewsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Reviews") {
                if template.reviews.isEmpty {
                    Text("No reviews yet")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(template.reviews) { review in
                            TemplateReviewCard(review: review)
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Usage Statistics") {
                VStack(spacing: 16) {
                    AnalyticRow(label: "Total Downloads", value: "\(template.downloadCount)", icon: "arrow.down.circle.fill", color: .green)
                    AnalyticRow(label: "Total Views", value: "\(template.viewCount)", icon: "eye.fill", color: .blue)
                    AnalyticRow(label: "Average Rating", value: String(format: "%.2f", template.averageRating), icon: "star.fill", color: .yellow)
                    AnalyticRow(label: "Review Count", value: "\(template.reviewCount)", icon: "text.bubble.fill", color: .purple)
                    
                    if let lastViewed = template.lastViewedAt {
                        AnalyticRow(label: "Last Viewed", value: lastViewed, style: .relative, icon: "clock.fill", color: .orange)
                    }
                }
                .padding()
            }
            
            GroupBox("Metadata") {
                VStack(spacing: 8) {
                    MetadataRow(label: "Created", value: template.createdAt, style: .date)
                    MetadataRow(label: "Updated", value: template.updatedAt, style: .date)
                    MetadataRow(label: "Template ID", value: template.id.uuidString)
                }
                .padding()
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private var actionsView: some View {
        HStack(spacing: 12) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                onEditCode()
            } label: {
                Label("Edit Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Spacer()
            
            if !template.isBuiltIn {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Supporting Views

struct TemplateStatBadge: View {
    let icon: String
    var value: String = ""
    var date: Date? = nil
    var style: Text.DateStyle? = nil
    let label: String
    
    init(icon: String, value: String, label: String) {
        self.icon = icon
        self.value = value
        self.label = label
    }
    
    init(icon: String, value: Date, style: Text.DateStyle, label: String) {
        self.icon = icon
        self.date = value
        self.style = style
        self.label = label
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            if let date = date, let style = style {
                Text(date, style: style)
                    .font(.caption2)
            } else {
                Text(value)
                    .font(.caption2)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct TemplateBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}

struct TemplateReviewCard: View {
    let review: TemplateReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.userName)
                    .font(.headline)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(review.rating.rounded()) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }
            
            Text(review.comment)
                .font(.body)
            
            HStack {
                Text(review.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if review.isVerifiedDownload {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AnalyticRow: View {
    let label: String
    var value: String = ""
    var date: Date? = nil
    var style: Text.DateStyle? = nil
    let icon: String
    let color: Color
    
    init(label: String, value: String, icon: String, color: Color) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    init(label: String, value: Date, style: Text.DateStyle, icon: String, color: Color) {
        self.label = label
        self.date = value
        self.style = style
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
            Spacer()
            if let date = date, let style = style {
                Text(date, style: style)
                    .foregroundStyle(.secondary)
            } else {
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MetadataRow: View {
    let label: String
    var value: String = ""
    var date: Date? = nil
    var style: Text.DateStyle? = nil
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date, style: Text.DateStyle) {
        self.label = label
        self.date = value
        self.style = style
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            if let date = date, let style = style {
                Text(date, style: style)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct WelcomeFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
