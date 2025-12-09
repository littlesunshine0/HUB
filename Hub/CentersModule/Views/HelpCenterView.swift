//
//  HelpCenterView.swift
//  Hub
//
//  Documentation, FAQs, and support center
//

import SwiftUI

struct HelpCenterView: View {
    @State private var searchQuery = ""
    @State private var selectedCategory: HelpCategory?
    
    enum HelpCategory: String, CaseIterable, Identifiable {
        case gettingStarted = "Getting Started"
        case features = "Features"
        case troubleshooting = "Troubleshooting"
        case faq = "FAQ"
        case contact = "Contact Support"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .gettingStarted: return "play.circle"
            case .features: return "star.circle"
            case .troubleshooting: return "wrench.and.screwdriver"
            case .faq: return "questionmark.circle"
            case .contact: return "envelope"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(HelpCategory.allCases, selection: $selectedCategory) { category in
                Label(category.rawValue, systemImage: category.icon)
                    .tag(category as HelpCategory?)
            }
            .navigationTitle("Help Center")
            .searchable(text: $searchQuery, prompt: "Search help articles...")
        } detail: {
            if let category = selectedCategory {
                categoryContent(for: category)
            } else {
                helpOverview
            }
        }
    }
    
    private var helpOverview: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green.gradient)
                    
                    Text("How can we help?")
                        .font(.largeTitle.bold())
                    
                    Text("Browse categories or search for specific topics")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Quick Links
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(HelpCategory.allCases) { category in
                        HelpCategoryCard(category: category) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
                
                // Popular Articles
                popularArticlesSection
            }
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func categoryContent(for category: HelpCategory) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Category Header
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.green.gradient)
                    
                    VStack(alignment: .leading) {
                        Text(category.rawValue)
                            .font(.title.bold())
                        Text("Learn about \(category.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Content
                switch category {
                case .gettingStarted:
                    gettingStartedContent
                case .features:
                    featuresContent
                case .troubleshooting:
                    troubleshootingContent
                case .faq:
                    faqContent
                case .contact:
                    contactContent
                }
            }
            .padding()
        }
    }
    
    private var gettingStartedContent: some View {
        VStack(spacing: 16) {
            HelpArticle(
                title: "Welcome to Hub",
                description: "Learn the basics of creating and managing hubs",
                icon: "hand.wave",
                readTime: "5 min"
            )
            HelpArticle(
                title: "Creating Your First Hub",
                description: "Step-by-step guide to building your first hub",
                icon: "plus.circle",
                readTime: "10 min"
            )
            HelpArticle(
                title: "Understanding Templates",
                description: "How to use templates to speed up development",
                icon: "doc.on.doc",
                readTime: "7 min"
            )
            HelpArticle(
                title: "Customizing Your Workspace",
                description: "Personalize your Hub experience",
                icon: "paintbrush",
                readTime: "5 min"
            )
        }
    }
    
    private var featuresContent: some View {
        VStack(spacing: 16) {
            HelpArticle(
                title: "Visual Editor",
                description: "Build interfaces with drag-and-drop",
                icon: "square.and.pencil",
                readTime: "8 min"
            )
            HelpArticle(
                title: "Code Generator",
                description: "Generate production-ready code",
                icon: "chevron.left.forwardslash.chevron.right",
                readTime: "12 min"
            )
            HelpArticle(
                title: "Real-Time Collaboration",
                description: "Work together with your team",
                icon: "person.2",
                readTime: "6 min"
            )
            HelpArticle(
                title: "Cloud Sync",
                description: "Keep your hubs synced across devices",
                icon: "icloud",
                readTime: "5 min"
            )
        }
    }
    
    private var troubleshootingContent: some View {
        VStack(spacing: 16) {
            HelpArticle(
                title: "Sync Issues",
                description: "Resolve synchronization problems",
                icon: "exclamationmark.triangle",
                readTime: "4 min"
            )
            HelpArticle(
                title: "Performance Optimization",
                description: "Speed up your Hub experience",
                icon: "speedometer",
                readTime: "6 min"
            )
            HelpArticle(
                title: "Build Errors",
                description: "Common build issues and solutions",
                icon: "xmark.circle",
                readTime: "8 min"
            )
            HelpArticle(
                title: "Storage Management",
                description: "Manage disk space and cache",
                icon: "externaldrive",
                readTime: "5 min"
            )
        }
    }
    
    private var faqContent: some View {
        VStack(spacing: 16) {
            HelpFAQItem(
                question: "How do I share my hub with others?",
                answer: "You can share hubs through the Marketplace or use local sharing for direct transfers."
            )
            HelpFAQItem(
                question: "Can I use Hub offline?",
                answer: "Yes! Hub works fully offline with local-first architecture. Sync happens when you're back online."
            )
            HelpFAQItem(
                question: "How do I backup my hubs?",
                answer: "Hubs are automatically backed up to iCloud if enabled. You can also export hubs manually."
            )
            HelpFAQItem(
                question: "What's the difference between a hub and a template?",
                answer: "Templates are reusable blueprints, while hubs are your actual projects built from templates."
            )
        }
    }
    
    private var contactContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                Text("Get in Touch")
                    .font(.title.bold())
                
                Text("Our support team is here to help")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ContactOption(icon: "envelope.fill", title: "Email Support", subtitle: "support@hub.app")
                ContactOption(icon: "message.fill", title: "Live Chat", subtitle: "Available 9am-5pm EST")
                ContactOption(icon: "phone.fill", title: "Phone Support", subtitle: "+1 (555) 123-4567")
                ContactOption(icon: "bubble.left.and.bubble.right.fill", title: "Community Forum", subtitle: "Ask the community")
            }
        }
    }
    
    private var popularArticlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Articles")
                .font(.title2.bold())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HelpArticle(
                    title: "Getting Started with Hub",
                    description: "Everything you need to know to begin",
                    icon: "play.circle",
                    readTime: "5 min"
                )
                HelpArticle(
                    title: "Building Your First App",
                    description: "Step-by-step tutorial",
                    icon: "hammer",
                    readTime: "15 min"
                )
                HelpArticle(
                    title: "Collaboration Best Practices",
                    description: "Work effectively with your team",
                    icon: "person.2",
                    readTime: "8 min"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct HelpCategoryCard: View {
    let category: HelpCenterView.HelpCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.green.gradient)
                
                Text(category.rawValue)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct HelpArticle: View {
    let title: String
    let description: String
    let icon: String
    let readTime: String
    
    var body: some View {
        Button {
            // Open article
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.green)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(readTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct HelpFAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ContactOption: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        Button {
            // Contact action
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HelpCenterView()
}
