import SwiftUI
import Combine

// MARK: - Theme Marketplace
struct ThemeMarketplaceView: View {
    @StateObject private var viewModel = ThemeMarketplaceViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search & Filters
                HStack {
                    TextField("Search themes...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All").tag(ThemeCategory?.none)
                        ForEach(ThemeCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                }
                .padding()
                
                // Theme Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 20) {
                        ForEach(viewModel.filteredThemes(search: searchText)) { theme in
                            MarketplaceThemeCard(theme: theme) {
                                viewModel.selectTheme(theme)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Theme Marketplace")
            .sheet(item: $viewModel.selectedTheme) { theme in
                ThemeDetailView(theme: theme)
            }
        }
    }
}

struct MarketplaceThemeCard: View {
    let theme: MarketplaceTheme
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview
            ThemePreview(theme: theme)
                .frame(height: 150)
                .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.headline)
                
                Text(theme.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(theme.rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text("(\(theme.downloads))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if theme.isPremium {
                        Text("$\(theme.price, specifier: "%.2f")")
                            .font(.headline)
                    } else {
                        Text("Free")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture(perform: onTap)
    }
}

struct ThemePreview: View {
    let theme: MarketplaceTheme
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.colors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack {
                Text("Preview")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
    }
}

struct ThemeDetailView: View {
    let theme: MarketplaceTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Large Preview
                    ThemePreview(theme: theme)
                        .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(theme.name)
                            .font(.largeTitle)
                        
                        Text("by \(theme.author)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(theme.rating) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                            Text("\(theme.rating, specifier: "%.1f")")
                            Text("•")
                            Text("\(theme.downloads) downloads")
                        }
                        .font(.caption)
                        
                        Divider()
                        
                        Text(theme.description)
                        
                        Divider()
                        
                        Text("Colors")
                            .font(.headline)
                        
                        HStack {
                            ForEach(theme.colors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 40, height: 40)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            // Install theme
                        }) {
                            Text(theme.isPremium ? "Purchase for $\(theme.price, specifier: "%.2f")" : "Install Free")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

@MainActor
class ThemeMarketplaceViewModel: ObservableObject {
    @Published var themes: [MarketplaceTheme] = []
    @Published var selectedCategory: ThemeCategory?
    @Published var selectedTheme: MarketplaceTheme?
    
    init() {
        loadThemes()
    }
    
    func filteredThemes(search: String) -> [MarketplaceTheme] {
        var filtered = themes
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !search.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(search) ||
                $0.author.localizedCaseInsensitiveContains(search)
            }
        }
        
        return filtered
    }
    
    func selectTheme(_ theme: MarketplaceTheme) {
        selectedTheme = theme
    }
    
    private func loadThemes() {
        themes = [
            MarketplaceTheme(
                name: "Ocean Breeze",
                author: "DesignStudio",
                description: "A calming blue theme inspired by the ocean",
                category: .modern,
                colors: ["#0077BE", "#00A8E8", "#00C9FF"],
                rating: 4.8,
                downloads: 1250,
                isPremium: false
            ),
            MarketplaceTheme(
                name: "Sunset Glow",
                author: "ColorMaster",
                description: "Warm sunset colors for your app",
                category: .colorful,
                colors: ["#FF6B6B", "#FFA500", "#FFD700"],
                rating: 4.9,
                downloads: 2100,
                isPremium: true,
                price: 4.99
            )
        ]
    }
}

struct MarketplaceTheme: Identifiable {
    let id = UUID()
    let name: String
    let author: String
    let description: String
    let category: ThemeCategory
    let colors: [String]
    let rating: Double
    let downloads: Int
    let isPremium: Bool
    var price: Double = 0.0
}

enum ThemeCategory: String, CaseIterable {
    case modern = "Modern"
    case minimal = "Minimal"
    case colorful = "Colorful"
    case dark = "Dark"
    case light = "Light"
}
// Color.init(hex:) extension removed - using centralized version from ColorExtensions.swift
