//
//  EnhancedDeepLinkHandler.swift
//  Hub
//
//  Enhanced deep linking with sharing, QR codes, and analytics
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

/// Enhanced deep link handler with sharing and analytics
@MainActor
public class EnhancedDeepLinkHandler: ObservableObject {
    @Published public var activeDeepLink: EnhancedDeepLink?
    @Published public var recentLinks: [DeepLinkHistoryItem] = []
    @Published public var favoriteLinks: [DeepLinkHistoryItem] = []
    
    private let analytics: DeepLinkAnalytics
    private let maxHistoryItems = 50
    
    public init() {
        self.analytics = DeepLinkAnalytics()
        loadHistory()
    }
    
    // MARK: - URL Handling
    
    public func handle(url: URL) {
        guard url.scheme == "hub" else {
            print("⚠️ Invalid URL scheme: \(url.scheme ?? "none")")
            return
        }
        
        // Track analytics
        analytics.trackLinkOpened(url: url)
        
        // Parse and handle
        if let deepLink = parseURL(url) {
            activeDeepLink = deepLink
            addToHistory(url: url, deepLink: deepLink)
        }
    }
    
    private func parseURL(_ url: URL) -> EnhancedDeepLink? {
        let host = url.host ?? ""
        let path = url.path
        let components = path.split(separator: "/").map(String.init)
        let query = url.queryParameters
        
        switch host {
        case "template":
            return parseTemplateURL(components: components, query: query)
        case "hub":
            return parseHubURL(components: components, query: query)
        case "marketplace":
            return parseMarketplaceURL(components: components, query: query)
        case "onboarding":
            return parseOnboardingURL(components: components, query: query)
        case "settings":
            return parseSettingsURL(components: components, query: query)
        case "ai":
            return parseAIURL(components: components, query: query)
        case "package":
            return parsePackageURL(components: components, query: query)
        case "community":
            return parseCommunityURL(components: components, query: query)
        case "achievement":
            return parseAchievementURL(components: components, query: query)
        default:
            return nil
        }
    }
    
    // MARK: - URL Parsing
    
    private func parseTemplateURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        guard let templateId = components.first else {
            return .templateGallery
        }
        return .template(id: templateId, action: query["action"])
    }
    
    private func parseHubURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        guard let hubId = components.first else {
            return .hubGallery
        }
        return .hub(id: hubId, action: query["action"])
    }
    
    private func parseMarketplaceURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .marketplace(category: components.first, search: query["search"])
    }
    
    private func parseOnboardingURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .onboarding(role: components.first)
    }
    
    private func parseSettingsURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .settings(section: components.first)
    }
    
    private func parseAIURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .ai(agent: components.first, task: query["task"])
    }
    
    private func parsePackageURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .package(id: components.first, action: query["action"])
    }
    
    private func parseCommunityURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .community(section: components.first, filter: query["filter"])
    }
    
    private func parseAchievementURL(components: [String], query: [String: String]) -> EnhancedDeepLink? {
        return .achievement(id: components.first)
    }
    
    // MARK: - History Management
    
    private func addToHistory(url: URL, deepLink: EnhancedDeepLink) {
        let item = DeepLinkHistoryItem(
            url: url,
            deepLink: deepLink,
            timestamp: Date()
        )
        
        recentLinks.insert(item, at: 0)
        
        // Limit history size
        if recentLinks.count > maxHistoryItems {
            recentLinks = Array(recentLinks.prefix(maxHistoryItems))
        }
        
        saveHistory()
    }
    
    public func addToFavorites(_ item: DeepLinkHistoryItem) {
        if !favoriteLinks.contains(where: { $0.url == item.url }) {
            favoriteLinks.append(item)
            saveHistory()
        }
    }
    
    public func removeFromFavorites(_ item: DeepLinkHistoryItem) {
        favoriteLinks.removeAll { $0.url == item.url }
        saveHistory()
    }
    
    public func clearHistory() {
        recentLinks.removeAll()
        saveHistory()
    }
    
    private func saveHistory() {
        // TODO: Persist to UserDefaults or SwiftData
    }
    
    private func loadHistory() {
        // TODO: Load from UserDefaults or SwiftData
    }
    
    // MARK: - Sharing
    
    public func shareURL(_ url: URL) -> ShareSheet {
        return ShareSheet(items: [url])
    }
    
    public func shareURLWithQR(_ url: URL) -> ShareSheet {
        var items: [Any] = [url]
        
        if let qrImage = generateQRCode(for: url) {
            items.append(qrImage)
        }
        
        return ShareSheet(items: items)
    }
    
    public func copyURL(_ url: URL) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #else
        UIPasteboard.general.string = url.absoluteString
        #endif
    }
    
    // MARK: - QR Code Generation
    
    public func generateQRCode(for url: URL) -> Image? {
        #if os(macOS)
        guard let qrImage = generateQRCodeImage(from: url.absoluteString) else {
            return nil
        }
        return Image(nsImage: qrImage)
        #else
        guard let qrImage = generateQRCodeImage(from: url.absoluteString) else {
            return nil
        }
        return Image(uiImage: qrImage)
        #endif
    }
    
    private func generateQRCodeImage(from string: String) -> PlatformImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        #if os(macOS)
        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
        #else
        return UIImage(ciImage: scaledImage)
        #endif
    }
    
    // MARK: - Clear
    
    public func clearDeepLink() {
        activeDeepLink = nil
    }
}

// MARK: - Enhanced Deep Link Types

public enum EnhancedDeepLink: Equatable, Codable {
    case template(id: String, action: String?)
    case templateGallery
    case hub(id: String, action: String?)
    case hubGallery
    case marketplace(category: String?, search: String?)
    case onboarding(role: String?)
    case settings(section: String?)
    case ai(agent: String?, task: String?)
    case package(id: String?, action: String?)
    case community(section: String?, filter: String?)
    case achievement(id: String?)
    
    public var title: String {
        switch self {
        case .template(let id, _): return "Template: \(id)"
        case .templateGallery: return "Template Gallery"
        case .hub(let id, _): return "Hub: \(id)"
        case .hubGallery: return "Hub Gallery"
        case .marketplace: return "Marketplace"
        case .onboarding: return "Onboarding"
        case .settings: return "Settings"
        case .ai: return "AI Assistant"
        case .package: return "Package"
        case .community: return "Community"
        case .achievement: return "Achievement"
        }
    }
    
    public var icon: String {
        switch self {
        case .template, .templateGallery: return "doc.text.fill"
        case .hub, .hubGallery: return "square.grid.2x2.fill"
        case .marketplace: return "storefront.fill"
        case .onboarding: return "person.badge.plus.fill"
        case .settings: return "gearshape.fill"
        case .ai: return "brain.head.profile"
        case .package: return "shippingbox.fill"
        case .community: return "person.3.fill"
        case .achievement: return "trophy.fill"
        }
    }
}

// MARK: - History Item

public struct DeepLinkHistoryItem: Identifiable, Codable {
    public let id = UUID()
    public let url: URL
    public let deepLink: EnhancedDeepLink
    public let timestamp: Date
    
    public var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Analytics

public class DeepLinkAnalytics {
    private var openCount: [String: Int] = [:]
    
    public func trackLinkOpened(url: URL) {
        let key = "\(url.host ?? ""):\(url.path)"
        openCount[key, default: 0] += 1
        
        print("📊 Deep link opened: \(key) (count: \(openCount[key] ?? 0))")
    }
    
    public func getMostPopularLinks() -> [(String, Int)] {
        return openCount.sorted { $0.value > $1.value }
    }
}

// MARK: - Share Sheet

public struct ShareSheet {
    let items: [Any]
    
    #if os(macOS)
    public func present() {
        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: .zero, of: NSView(), preferredEdge: .minY)
    }
    #else
    public func makeUIViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    #endif
}

