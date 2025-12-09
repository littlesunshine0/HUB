//
//  MediaCenterView.swift
//  Hub
//
//  Organize and manage digital media (glyphs, icons, illustrations, animations)
//

import SwiftUI

struct MediaCenterView: View {
    @State private var selectedCategory: MediaCategory = .all
    @State private var searchQuery = ""
    @State private var viewMode: ViewMode = .grid
    
    enum MediaCategory: String, CaseIterable, Identifiable {
        case all = "All Media"
        case icons = "Icons"
        case glyphs = "Glyphs"
        case illustrations = "Illustrations"
        case animations = "Animations"
        case images = "Images"
        case videos = "Videos"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .icons: return "app.badge"
            case .glyphs: return "character.cursor.ibeam"
            case .illustrations: return "paintbrush.pointed"
            case .animations: return "wand.and.stars"
            case .images: return "photo"
            case .videos: return "film"
            }
        }
    }
    
    enum ViewMode {
        case grid, list
    }
    
    var body: some View {
        NavigationSplitView {
            List(MediaCategory.allCases, selection: $selectedCategory) { category in
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.rawValue)
                        Text("\(mediaCount(for: category)) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: category.icon)
                }
                .tag(category)
            }
            .navigationTitle("Media Center")
            .searchable(text: $searchQuery, prompt: "Search media...")
        } detail: {
            VStack(spacing: 0) {
                // Toolbar
                mediaToolbar
                    .padding()
                
                Divider()
                
                // Content
                if viewMode == .grid {
                    mediaGridView
                } else {
                    mediaListView
                }
            }
        }
    }
    
    private var mediaToolbar: some View {
        HStack {
            // Category Info
            HStack(spacing: 12) {
                Image(systemName: selectedCategory.icon)
                    .font(.title2)
                    .foregroundStyle(.pink.gradient)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCategory.rawValue)
                        .font(.headline)
                    Text("\(mediaCount(for: selectedCategory)) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // View Mode Toggle
            Picker("View Mode", selection: $viewMode) {
                Label("Grid", systemImage: "square.grid.2x2").tag(ViewMode.grid)
                Label("List", systemImage: "list.bullet").tag(ViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            
            // Actions
            Menu {
                Button("Import Media") {}
                Button("Create Collection") {}
                Divider()
                Button("Sort by Name") {}
                Button("Sort by Date") {}
                Button("Sort by Size") {}
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    private var mediaGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredMedia) { item in
                    MediaGridItem(item: item)
                }
            }
            .padding()
        }
    }
    
    private var mediaListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredMedia) { item in
                    MediaListItem(item: item)
                }
            }
            .padding()
        }
    }
    
    private var filteredMedia: [MediaCenterItem] {
        sampleMedia.filter { item in
            (selectedCategory == .all || item.category == selectedCategory) &&
            (searchQuery.isEmpty || item.name.localizedCaseInsensitiveContains(searchQuery))
        }
    }
    
    private func mediaCount(for category: MediaCategory) -> Int {
        if category == .all {
            return sampleMedia.count
        }
        return sampleMedia.filter { $0.category == category }.count
    }
    
    // Sample data
    private var sampleMedia: [MediaCenterItem] {
        [
            // Icons
            MediaCenterItem(name: "App Icon", category: .icons, format: "PNG", size: "512x512", fileSize: "24 KB"),
            MediaCenterItem(name: "Settings Icon", category: .icons, format: "SVG", size: "256x256", fileSize: "8 KB"),
            MediaCenterItem(name: "Profile Icon", category: .icons, format: "PNG", size: "512x512", fileSize: "32 KB"),
            
            // Glyphs
            MediaCenterItem(name: "Arrow Glyph", category: .glyphs, format: "SVG", size: "24x24", fileSize: "2 KB"),
            MediaCenterItem(name: "Star Glyph", category: .glyphs, format: "SVG", size: "24x24", fileSize: "2 KB"),
            MediaCenterItem(name: "Heart Glyph", category: .glyphs, format: "SVG", size: "24x24", fileSize: "2 KB"),
            
            // Illustrations
            MediaCenterItem(name: "Welcome Illustration", category: .illustrations, format: "SVG", size: "800x600", fileSize: "45 KB"),
            MediaCenterItem(name: "Empty State", category: .illustrations, format: "PNG", size: "400x300", fileSize: "28 KB"),
            MediaCenterItem(name: "Success Illustration", category: .illustrations, format: "SVG", size: "600x600", fileSize: "38 KB"),
            
            // Animations
            MediaCenterItem(name: "Loading Animation", category: .animations, format: "Lottie", size: "N/A", fileSize: "12 KB"),
            MediaCenterItem(name: "Success Animation", category: .animations, format: "Lottie", size: "N/A", fileSize: "18 KB"),
            MediaCenterItem(name: "Transition", category: .animations, format: "GIF", size: "400x400", fileSize: "156 KB"),
            
            // Images
            MediaCenterItem(name: "Hero Image", category: .images, format: "JPG", size: "1920x1080", fileSize: "245 KB"),
            MediaCenterItem(name: "Background", category: .images, format: "PNG", size: "2560x1440", fileSize: "892 KB"),
            MediaCenterItem(name: "Thumbnail", category: .images, format: "JPG", size: "400x300", fileSize: "45 KB"),
            
            // Videos
            MediaCenterItem(name: "Tutorial Video", category: .videos, format: "MP4", size: "1920x1080", fileSize: "12.4 MB"),
            MediaCenterItem(name: "Demo", category: .videos, format: "MP4", size: "1280x720", fileSize: "8.2 MB"),
        ]
    }
}

struct MediaCenterItem: Identifiable {
    let id = UUID()
    let name: String
    let category: MediaCenterView.MediaCategory
    let format: String
    let size: String
    let fileSize: String
}

struct MediaGridItem: View {
    let item: MediaCenterItem
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(.pink.opacity(0.5))
            }
            
            // Info
            VStack(spacing: 4) {
                Text(item.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(item.format)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button("Preview") {}
            Button("Copy") {}
            Button("Export") {}
            Divider()
            Button("Delete", role: .destructive) {}
        }
    }
    
    private var categoryIcon: String {
        switch item.category {
        case .icons: return "app.badge"
        case .glyphs: return "character.cursor.ibeam"
        case .illustrations: return "paintbrush.pointed"
        case .animations: return "wand.and.stars"
        case .images: return "photo"
        case .videos: return "film"
        case .all: return "square.grid.2x2"
        }
    }
}

struct MediaListItem: View {
    let item: MediaCenterItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .frame(width: 60, height: 60)
                
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundStyle(.pink.opacity(0.5))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(item.format, systemImage: "doc")
                    Text("•")
                    Label(item.size, systemImage: "ruler")
                    Text("•")
                    Label(item.fileSize, systemImage: "externaldrive")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    // Preview
                } label: {
                    Image(systemName: "eye")
                }
                .buttonStyle(.plain)
                
                Button {
                    // Copy
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                
                Menu {
                    Button("Export") {}
                    Button("Share") {}
                    Divider()
                    Button("Delete", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var categoryIcon: String {
        switch item.category {
        case .icons: return "app.badge"
        case .glyphs: return "character.cursor.ibeam"
        case .illustrations: return "paintbrush.pointed"
        case .animations: return "wand.and.stars"
        case .images: return "photo"
        case .videos: return "film"
        case .all: return "square.grid.2x2"
        }
    }
}

#Preview {
    MediaCenterView()
}
