import SwiftUI
import SwiftData
import Combine

// MARK: - Achievements Gallery View

public struct AchievementsGalleryView: View {
    @ObservedObject var service: AchievementService
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedRarity: AchievementRarity? = nil
    @State private var showOnlyUnlocked: Bool = false
    
    private let allAchievements: [AchievementDefinition]
    
    public init(service: AchievementService) {
        self.service = service
        self.allAchievements = AchievementLibrary.shared.allDefinitions()
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with stats
                headerView
                
                Divider()
                
                // Filters
                filtersView
                
                Divider()
                
                // Achievement grid
                ScrollView {
                    if filteredAchievements.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredAchievements, id: \.id) { achievement in
                                AchievementGalleryCard(
                                    definition: achievement,
                                    isUnlocked: isUnlocked(id: achievement.id),
                                    unlockedDate: unlockedDate(for: achievement.id)
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Achievements")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                AchievementStatBadge(
                    title: "Unlocked",
                    value: "\(service.unlockedAchievements.count)/\(allAchievements.count)",
                    icon: "trophy.fill",
                    color: .orange
                )
                
                AchievementStatBadge(
                    title: "Progress",
                    value: String(format: "%.0f%%", progressPercentage),
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                AchievementStatBadge(
                    title: "Rarest",
                    value: rarestUnlocked?.rarity.rawValue ?? "None",
                    icon: "star.fill",
                    color: .purple
                )
            }
            
            // Progress bar
            ProgressView(value: progressPercentage, total: 100.0)
                .tint(.orange)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Show only unlocked toggle
                Toggle(isOn: $showOnlyUnlocked) {
                    Label("Unlocked Only", systemImage: "checkmark.circle")
                }
                .toggleStyle(.button)
                
                Divider()
                    .frame(height: 20)
                
                // Category filters
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = selectedCategory == category ? nil : category
                    } label: {
                        Label(category.rawValue, systemImage: category.icon)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedCategory == category ? .accentColor : .gray)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Rarity filters
                ForEach(AchievementRarity.allCases, id: \.self) { rarity in
                    Button {
                        selectedRarity = selectedRarity == rarity ? nil : rarity
                    } label: {
                        Text(rarity.rawValue)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedRarity == rarity ? .accentColor : .gray)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Achievements Found",
            systemImage: "trophy.slash",
            description: Text("Try adjusting your filters")
        )
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func isUnlocked(id: String) -> Bool {
        return service.isUnlocked(id: id)
    }
    
    private func unlockedDate(for id: String) -> Date? {
        return service.unlockedAchievements.first { $0.achievementID == id }?.unlockedAt
    }
    
    private var filteredAchievements: [AchievementDefinition] {
        allAchievements.filter { achievement in
            // Category filter
            if let category = selectedCategory, achievement.category != category {
                return false
            }
            
            // Rarity filter
            if let rarity = selectedRarity, achievement.rarity != rarity {
                return false
            }
            
            // Unlocked filter
            if showOnlyUnlocked && !isUnlocked(id: achievement.id) {
                return false
            }
            
            return true
        }
    }
    
    private var progressPercentage: Double {
        guard let userID = service.unlockedAchievements.first?.userID else { return 0.0 }
        return service.progressPercentage(for: userID)
    }
    
    private var rarestUnlocked: AchievementDefinition? {
        let unlocked = service.unlockedAchievements.compactMap { achievement in
            AchievementLibrary.shared.definition(for: achievement.achievementID)
        }
        
        return unlocked.max { $0.rarity.rawValue < $1.rarity.rawValue }
    }
}

// MARK: - Achievement Card

struct AchievementGalleryCard: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(rarityColor.opacity(isUnlocked ? 0.2 : 0.05))
                    .frame(width: 80, height: 80)
                
                Image(systemName: definition.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(isUnlocked ? rarityColor : .gray)
                    .opacity(isUnlocked ? 1.0 : 0.3)
            }
            
            // Name
            Text(definition.name)
                .font(.headline)
                .foregroundStyle(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(definition.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Rarity badge
            HStack(spacing: 4) {
                Circle()
                    .fill(rarityColor)
                    .frame(width: 8, height: 8)
                Text(definition.rarity.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Unlock date
            if let date = unlockedDate {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Locked")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? rarityColor.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 2)
        )
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
    
    private var rarityColor: Color {
        guard let nsColor = NSColor(hex: definition.rarity.color) else {
            return .gray
        }
        return Color(nsColor: nsColor)
    }
}

// MARK: - Stat Badge

struct NotificationStatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let container = try! ModelContainer(for: UserAchievement.self)
    let context = ModelContext(container)
    let service = AchievementService(modelContext: context)
    
    return AchievementsGalleryView(service: service)
        .frame(width: 900, height: 700)
}


// MARK: - Achievement Stat Badge

struct AchievementStatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
