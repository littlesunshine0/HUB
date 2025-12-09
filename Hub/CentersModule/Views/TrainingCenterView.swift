//
//  TrainingCenterView.swift
//  Hub
//
//  Advanced training and learning platform with AI assistance
//

import SwiftUI

struct TrainingCenterView: View {
    @State private var selectedPath: LearningPath?
    @State private var searchQuery = ""
    @State private var showAIAssistant = false
    @State private var userProgress: [String: Double] = [:]
    
    var body: some View {
        NavigationSplitView {
            List {
                Section("Learning Paths") {
                    ForEach(LearningPath.allPaths) { path in
                        NavigationLink(value: path) {
                            LearningPathRow(path: path, progress: userProgress[path.id] ?? 0)
                        }
                    }
                }
                
                Section("Quick Access") {
                    NavigationLink {
                        LiveWebinarsView()
                    } label: {
                        Label("Live Webinars", systemImage: "video.fill")
                    }
                    
                    NavigationLink {
                        CommunityForumView()
                    } label: {
                        Label("Community Forum", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    
                    NavigationLink {
                        CertificationView()
                    } label: {
                        Label("Certifications", systemImage: "rosette")
                    }
                }
            }
            .navigationTitle("Training Center")
            .searchable(text: $searchQuery, prompt: "Search courses...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAIAssistant.toggle()
                    } label: {
                        Label("AI Assistant", systemImage: "sparkles")
                    }
                }
            }
        } detail: {
            if let path = selectedPath {
                LearningPathDetailView(path: path)
            } else {
                trainingOverview
            }
        }
        .sheet(isPresented: $showAIAssistant) {
            AILearningAssistantView()
        }
    }
    
    private var trainingOverview: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Master Hub Development")
                        .font(.largeTitle.bold())
                    
                    Text("Interactive courses, live webinars, and AI-powered learning")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Stats
                HStack(spacing: 24) {
                    TrainingStatCard(value: "50+", label: "Courses", icon: "book.fill")
                    TrainingStatCard(value: "10K+", label: "Students", icon: "person.3.fill")
                    TrainingStatCard(value: "95%", label: "Satisfaction", icon: "star.fill")
                }
                .padding(.horizontal)
                
                // Featured Learning Paths
                VStack(alignment: .leading, spacing: 16) {
                    Text("Featured Learning Paths")
                        .font(.title2.bold())
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(LearningPath.allPaths.prefix(3)) { path in
                                LearningPathCard(path: path)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Live Webinars
                upcomingWebinarsSection
                
                // Community Highlights
                communityHighlightsSection
            }
            .padding(.bottom, 40)
        }
    }
    
    private var upcomingWebinarsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Webinars")
                    .font(.title2.bold())
                Spacer()
                Button("View All") {}
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                WebinarCard(
                    title: "Building Production Apps",
                    presenter: "Sarah Chen",
                    date: "Nov 25, 2025",
                    time: "2:00 PM EST",
                    attendees: 234
                )
                WebinarCard(
                    title: "Advanced AI Integration",
                    presenter: "Marcus Johnson",
                    date: "Nov 27, 2025",
                    time: "3:00 PM EST",
                    attendees: 189
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var communityHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Community Highlights")
                    .font(.title2.bold())
                Spacer()
                Button("Join Forum") {}
                    .font(.subheadline)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                CommunityPostCard(
                    title: "How I built a marketplace in 2 days",
                    author: "Alex Rivera",
                    replies: 45,
                    likes: 128
                )
                CommunityPostCard(
                    title: "Best practices for CRDT sync",
                    author: "Jamie Lee",
                    replies: 23,
                    likes: 67
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Learning Path Models

struct LearningPath: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let level: Level
    let duration: String
    let modules: [Module]
    let icon: String
    
    enum Level: String, Hashable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .blue
            case .advanced: return .orange
            case .expert: return .purple
            }
        }
    }
    
    struct Module: Identifiable, Hashable {
        let id: String
        let title: String
        let lessons: [Lesson]
        let quiz: Quiz?
    }
    
    struct Lesson: Identifiable, Hashable {
        let id: String
        let title: String
        let type: LessonType
        let duration: Int // minutes
        let content: String
    }
    
    enum LessonType: Hashable {
        case video
        case interactive
        case reading
        case coding
        case project
    }
    
    struct Quiz: Identifiable, Hashable {
        let id: String
        let questions: [Question]
    }
    
    struct Question: Identifiable, Hashable {
        let id: String
        let text: String
        let options: [String]
        let correctAnswer: Int
    }
    
    static let allPaths: [LearningPath] = [
        LearningPath(
            id: "beginner",
            title: "Hub Fundamentals",
            description: "Start your journey with Hub basics",
            level: .beginner,
            duration: "4 hours",
            modules: [],
            icon: "play.circle.fill"
        ),
        LearningPath(
            id: "intermediate",
            title: "Building Real Apps",
            description: "Create production-ready applications",
            level: .intermediate,
            duration: "8 hours",
            modules: [],
            icon: "hammer.fill"
        ),
        LearningPath(
            id: "advanced",
            title: "Advanced Patterns",
            description: "Master complex architectures",
            level: .advanced,
            duration: "12 hours",
            modules: [],
            icon: "star.fill"
        ),
        LearningPath(
            id: "ai",
            title: "AI Integration",
            description: "Build intelligent applications",
            level: .intermediate,
            duration: "6 hours",
            modules: [],
            icon: "brain.head.profile"
        )
    ]
}

// MARK: - Supporting Views

struct LearningPathRow: View {
    let path: LearningPath
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: path.icon)
                    .foregroundStyle(path.level.color)
                Text(path.title)
                    .font(.headline)
            }
            
            Text(path.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(path.level.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(path.level.color.opacity(0.2))
                    .foregroundStyle(path.level.color)
                    .cornerRadius(4)
                
                Text(path.duration)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if progress > 0 {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if progress > 0 {
                ProgressView(value: progress)
                    .tint(path.level.color)
            }
        }
    }
}

struct LearningPathCard: View {
    let path: LearningPath
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: path.icon)
                .font(.system(size: 40))
                .foregroundStyle(path.level.color.gradient)
            
            Text(path.title)
                .font(.headline)
            
            Text(path.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(path.level.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(path.level.color.opacity(0.2))
                    .foregroundStyle(path.level.color)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(path.duration)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 250)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TrainingStatCard: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct WebinarCard: View {
    let title: String
    let presenter: String
    let date: String
    let time: String
    let attendees: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "video.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("with \(presenter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Label(date, systemImage: "calendar")
                    Label(time, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Button("Register") {}
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Text("\(attendees) registered")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CommunityPostCard: View {
    let title: String
    let author: String
    let replies: Int
    let likes: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.purple.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("by \(author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Label("\(replies)", systemImage: "bubble.left")
                    Label("\(likes)", systemImage: "heart")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Detail Views

struct LearningPathDetailView: View {
    let path: LearningPath
    @State private var completedLessons: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: path.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(path.level.color.gradient)
                        
                        VStack(alignment: .leading) {
                            Text(path.title)
                                .font(.largeTitle.bold())
                            Text(path.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(path.level.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(path.level.color.opacity(0.2))
                            .foregroundStyle(path.level.color)
                            .cornerRadius(6)
                        
                        Label(path.duration, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(12)
                
                // Modules
                Text("Course Modules")
                    .font(.title2.bold())
                
                // Placeholder modules
                ForEach(0..<4) { index in
                    ModuleCard(
                        title: "Module \(index + 1)",
                        lessons: 5,
                        duration: "45 min"
                    )
                }
            }
            .padding()
        }
    }
}

struct ModuleCard: View {
    let title: String
    let lessons: Int
    let duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            HStack {
                Label("\(lessons) lessons", systemImage: "play.circle")
                Label(duration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct LiveWebinarsView: View {
    var body: some View {
        Text("Live Webinars")
            .font(.largeTitle)
    }
}

struct CommunityForumView: View {
    var body: some View {
        Text("Community Forum")
            .font(.largeTitle)
    }
}

struct CertificationView: View {
    var body: some View {
        Text("Certifications")
            .font(.largeTitle)
    }
}

struct AILearningAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @State private var question = ""
    @State private var messages: [ChatMessage] = []
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser { Spacer() }
                                
                                Text(message.text)
                                    .padding()
                                    .background(message.isUser ? Color.blue : Color(.controlBackgroundColor))
                                    .foregroundStyle(message.isUser ? .white : .primary)
                                    .cornerRadius(12)
                                
                                if !message.isUser { Spacer() }
                            }
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Ask me anything...", text: $question)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(question.isEmpty)
                }
                .padding()
            }
            .navigationTitle("AI Learning Assistant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        messages.append(ChatMessage(text: question, isUser: true))
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append(ChatMessage(
                text: "I can help you with that! Let me search the documentation...",
                isUser: false
            ))
        }
        question = ""
    }
}

#Preview {
    TrainingCenterView()
}
