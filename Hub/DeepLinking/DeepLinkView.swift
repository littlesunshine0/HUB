//
//  DeepLinkView.swift
//  Hub
//
//  View modifier for handling deep links
//

import SwiftUI

// MARK: - Deep Link View Modifier

extension View {
    /// Handle deep links in this view
    public func handleDeepLinks(handler: DeepLinkHandler) -> some View {
        self.modifier(DeepLinkViewModifier(handler: handler))
    }
}

struct DeepLinkViewModifier: ViewModifier {
    @ObservedObject var handler: DeepLinkHandler
    @State private var showingDeepLinkSheet = false
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handler.handle(url: url)
            }
            .onChange(of: handler.activeDeepLink) { _, newLink in
                if newLink != nil {
                    showingDeepLinkSheet = true
                }
            }
            .sheet(isPresented: $showingDeepLinkSheet, onDismiss: {
                handler.clearDeepLink()
            }) {
                if let deepLink = handler.activeDeepLink {
                    DeepLinkDestinationView(deepLink: deepLink)
                }
            }
    }
}

// MARK: - Deep Link Destination View

struct DeepLinkDestinationView: View {
    let deepLink: DeepLink
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            destinationContent
                .navigationTitle(deepLink.description)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var destinationContent: some View {
        switch deepLink {
        case .template(let id, let action):
            TemplateDeepLinkView(templateId: id, action: action)
            
        case .templateGallery:
            Text("Template Gallery")
                .font(.title)
            
        case .hub(let id, let action):
            HubDeepLinkView(hubId: id, action: action)
            
        case .hubGallery:
            Text("Hub Gallery")
                .font(.title)
            
        case .marketplace(let category, let search):
            MarketplaceDeepLinkView(category: category, search: search)
            
        case .onboarding(let role):
            OnboardingDeepLinkView(role: role)
            
        case .settings(let section):
            SettingsDeepLinkView(section: section)
        }
    }
}

// MARK: - Template Deep Link View

struct TemplateDeepLinkView: View {
    let templateId: String
    let action: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Template: \(templateId)")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let action = action {
                Text("Action: \(action)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button("Open Template") {
                // TODO: Navigate to template
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Hub Deep Link View

struct HubDeepLinkView: View {
    let hubId: String
    let action: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("Hub: \(hubId)")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let action = action {
                Text("Action: \(action)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button("Open Hub") {
                // TODO: Navigate to hub
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Marketplace Deep Link View

struct MarketplaceDeepLinkView: View {
    let category: String?
    let search: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "storefront.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Marketplace")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let category = category {
                Text("Category: \(category)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let search = search {
                Text("Search: \(search)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button("Browse Marketplace") {
                // TODO: Navigate to marketplace
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Onboarding Deep Link View

struct OnboardingDeepLinkView: View {
    let role: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Onboarding")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let role = role {
                Text("Role: \(role)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button("Start Onboarding") {
                // TODO: Navigate to onboarding
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Settings Deep Link View

struct SettingsDeepLinkView: View {
    let section: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let section = section {
                Text("Section: \(section)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button("Open Settings") {
                // TODO: Navigate to settings
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
