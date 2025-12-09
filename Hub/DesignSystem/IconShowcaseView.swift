import SwiftUI

/// Comprehensive showcase of all Hub icon variants and enhancements
public struct IconShowcaseView: View {
    @State private var selectedTab: ShowcaseTab = .enhanced
    @State private var iconSize: CGFloat = 120
    @State private var isActive = true
    @State private var backgroundColor: BackgroundStyle = .light
    
    public init() {}
    
    public var body: some View {
        HSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Icon Showcase")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Divider()
                
                // Tab Selection
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(ShowcaseTab.allCases, id: \.self) { tab in
                            ShowcaseTabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                action: { selectedTab = tab }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("Controls")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Size: \(Int(iconSize))px")
                            .font(.caption)
                        Slider(value: $iconSize, in: 32...200, step: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Background")
                            .font(.caption)
                        Picker("Background", selection: $backgroundColor) {
                            ForEach(BackgroundStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if selectedTab == .states {
                        Toggle("Active State", isOn: $isActive)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .frame(minWidth: 250, maxWidth: 300)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content
            ScrollView {
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 8) {
                        Text(selectedTab.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(selectedTab.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    Divider()
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .enhanced:
                            enhancedIconsView
                        case .animated:
                            animatedIconsView
                        case .states:
                            stateIconsView
                        case .comparison:
                            comparisonView
                        case .sizes:
                            sizesView
                        case .original:
                            originalIconsView
                        }
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(backgroundColor.color)
            }
        }
        .frame(minWidth: 900, minHeight: 650)
    }
    
    // MARK: - Content Views
    
    private var enhancedIconsView: some View {
        VStack(spacing: 40) {
            // Main enhanced icon
            VStack(spacing: 16) {
                EnhancedHubIconView(size: iconSize)
                Text("Enhanced Hub Icon")
                    .font(.headline)
                Text("Glass effects, depth, and modern visual treatments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Feature breakdown
            VStack(alignment: .leading, spacing: 24) {
                Text("Enhancement Features")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ShowcaseFeatureCard(
                        icon: "sparkles",
                        title: "Angular Gradient",
                        description: "Multi-stop gradient with smooth color transitions"
                    )
                    
                    ShowcaseFeatureCard(
                        icon: "light.max",
                        title: "Glass Highlights",
                        description: "Diagonal light sweeps and edge reflections"
                    )
                    
                    ShowcaseFeatureCard(
                        icon: "circle.hexagongrid.fill",
                        title: "Backlit Nodes",
                        description: "Radial glows behind network nodes"
                    )
                    
                    ShowcaseFeatureCard(
                        icon: "drop.fill",
                        title: "Liquid Highlights",
                        description: "Droplet-style highlights on nodes"
                    )
                    
                    ShowcaseFeatureCard(
                        icon: "shadow",
                        title: "Multi-Layer Shadows",
                        description: "Depth through layered shadow effects"
                    )
                    
                    ShowcaseFeatureCard(
                        icon: "waveform",
                        title: "Subtle Animation",
                        description: "Gentle pulsing glow animation"
                    )
                }
            }
        }
    }
    
    private var animatedIconsView: some View {
        VStack(spacing: 40) {
            // Animated variants
            HStack(spacing: 40) {
                VStack(spacing: 16) {
                    AnimatedHubIconView(size: iconSize)
                    Text("Pulsing Glow")
                        .font(.headline)
                    Text("For loading states")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    RotatingHubIconView(size: iconSize)
                    Text("Rotating")
                        .font(.headline)
                    Text("For sync/processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Use cases
            VStack(alignment: .leading, spacing: 16) {
                Text("Use Cases")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                UseCaseRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Loading States",
                    description: "Use AnimatedHubIconView for loading indicators"
                )
                
                UseCaseRow(
                    icon: "arrow.clockwise",
                    title: "Sync Status",
                    description: "Use RotatingHubIconView for active sync operations"
                )
                
                UseCaseRow(
                    icon: "bell.badge",
                    title: "Notifications",
                    description: "Use pulsing animation to draw attention"
                )
            }
        }
    }
    
    private var stateIconsView: some View {
        VStack(spacing: 40) {
            // State variants
            HStack(spacing: 40) {
                VStack(spacing: 16) {
                    EnhancedHubIconView(size: iconSize)
                    Text("Default")
                        .font(.headline)
                }
                
                VStack(spacing: 16) {
                    ActiveHubIconView(size: iconSize, isActive: isActive)
                    Text("Active")
                        .font(.headline)
                }
                
                VStack(spacing: 16) {
                    SuccessHubIconView(size: iconSize)
                    Text("Success")
                        .font(.headline)
                }
            }
            
            Divider()
            
            // State descriptions
            VStack(alignment: .leading, spacing: 16) {
                Text("State Indicators")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                StateDescriptionRow(
                    color: .blue,
                    title: "Default State",
                    description: "Standard appearance with subtle effects"
                )
                
                StateDescriptionRow(
                    color: .cyan,
                    title: "Active State",
                    description: "Blue glow ring with scale effect for selection"
                )
                
                StateDescriptionRow(
                    color: .green,
                    title: "Success State",
                    description: "Green glow for completion and success feedback"
                )
            }
        }
    }
    
    private var comparisonView: some View {
        VStack(spacing: 40) {
            // Side by side comparison
            HStack(spacing: 60) {
                VStack(spacing: 16) {
                    HubIconView(size: iconSize)
                    Text("Original")
                        .font(.headline)
                    Text("Simple gradient")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    EnhancedHubIconView(size: iconSize)
                    Text("Enhanced")
                        .font(.headline)
                    Text("Glass effects & depth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Enhancement comparison table
            VStack(alignment: .leading, spacing: 16) {
                Text("Enhancement Comparison")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                ComparisonTable()
            }
        }
    }
    
    private var sizesView: some View {
        VStack(spacing: 40) {
            // Multiple sizes
            VStack(spacing: 32) {
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        EnhancedHubIconView(size: 200)
                        Text("200px - Hero")
                            .font(.caption)
                    }
                    
                    VStack(spacing: 8) {
                        EnhancedHubIconView(size: 128)
                        Text("128px - Large")
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        EnhancedHubIconView(size: 64)
                        Text("64px - Medium")
                            .font(.caption)
                    }
                    
                    VStack(spacing: 8) {
                        EnhancedHubIconView(size: 32)
                        Text("32px - Small")
                            .font(.caption)
                    }
                    
                    VStack(spacing: 8) {
                        EnhancedHubIconView(size: 16)
                        Text("16px - Tiny")
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            // Size recommendations
            VStack(alignment: .leading, spacing: 16) {
                Text("Size Recommendations")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                SizeRecommendationRow(size: "200px+", useCase: "Hero displays, splash screens")
                SizeRecommendationRow(size: "128px", useCase: "App icons, large buttons")
                SizeRecommendationRow(size: "64px", useCase: "Toolbar icons, medium UI")
                SizeRecommendationRow(size: "32px", useCase: "Small icons, lists")
                SizeRecommendationRow(size: "16px", useCase: "Status bar, tiny indicators")
            }
        }
    }
    
    private var originalIconsView: some View {
        VStack(spacing: 40) {
            // Original variants
            HStack(spacing: 40) {
                VStack(spacing: 16) {
                    HubIconView(size: iconSize)
                    Text("Hexagon")
                        .font(.headline)
                }
                
                VStack(spacing: 16) {
                    HubIconSymbol(size: iconSize)
                    Text("SF Symbol")
                        .font(.headline)
                }
                
                VStack(spacing: 16) {
                    HubIconCube(size: iconSize)
                    Text("3D Cube")
                        .font(.headline)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Original Variants")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("These are the original icon designs before enhancement. They remain available for simpler use cases or performance-critical scenarios.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct ShowcaseTabButton: View {
    let tab: ShowcaseTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .frame(width: 24)
                Text(tab.rawValue)
                    .font(.body)
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : (isHovered ? Color.blue.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct ShowcaseFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct UseCaseRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct StateDescriptionRow: View {
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct SizeRecommendationRow: View {
    let size: String
    let useCase: String
    
    var body: some View {
        HStack {
            Text(size)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 80, alignment: .leading)
            Text(useCase)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ComparisonTable: View {
    let features = [
        ("Gradient Type", "Linear", "Angular (4-stop)"),
        ("Shadows", "Single", "Multi-layer (2+)"),
        ("Highlights", "None", "Glass + Liquid"),
        ("Node Effects", "Solid", "Backlit glows"),
        ("Animation", "None", "Subtle pulse"),
        ("Depth", "Flat", "Layered 3D")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Feature")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Original")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Enhanced")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Rows
            ForEach(features, id: \.0) { feature in
                HStack {
                    Text(feature.0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(feature.1)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(feature.2)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                Divider()
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

enum ShowcaseTab: String, CaseIterable {
    case enhanced = "Enhanced Icons"
    case animated = "Animated Variants"
    case states = "State Indicators"
    case comparison = "Comparison"
    case sizes = "Size Guide"
    case original = "Original Variants"
    
    var icon: String {
        switch self {
        case .enhanced: return "sparkles"
        case .animated: return "waveform.path"
        case .states: return "circle.hexagongrid.fill"
        case .comparison: return "arrow.left.and.right"
        case .sizes: return "ruler"
        case .original: return "square.grid.2x2"
        }
    }
    
    var title: String { rawValue }
    
    var description: String {
        switch self {
        case .enhanced:
            return "Modern glass effects, depth, and visual polish"
        case .animated:
            return "Dynamic animations for loading and active states"
        case .states:
            return "Visual feedback for different interaction states"
        case .comparison:
            return "Side-by-side comparison of original vs enhanced"
        case .sizes:
            return "Icon appearance at different sizes"
        case .original:
            return "Original icon designs and variants"
        }
    }
}

enum BackgroundStyle: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case clear = "Clear"
    
    var color: Color {
        switch self {
        case .light: return Color.white
        case .dark: return Color.black
        case .clear: return Color.clear
        }
    }
}

// MARK: - Preview

#Preview {
    IconShowcaseView()
}
