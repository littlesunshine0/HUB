import Foundation

// MARK: - Apple Framework Model

/// Represents an Apple framework with documentation and capabilities
public struct AppleFramework: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let category: FrameworkCategory
    public let minimumOS: String
    
    // Documentation
    public let appleDocURL: URL
    public let swiftDocURL: URL?
    public let wwdcSessions: [WWDCSession]
    
    // Capabilities
    public let capabilities: [FrameworkCapability]
    public let bestPractices: [FrameworkBestPractice]
    
    // Integration
    public let dependencies: [String]
    public let imports: [String]
    
    // Metadata
    public let lastCrawled: Date
    public let version: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: FrameworkCategory,
        minimumOS: String,
        appleDocURL: URL,
        swiftDocURL: URL? = nil,
        wwdcSessions: [WWDCSession] = [],
        capabilities: [FrameworkCapability] = [],
        bestPractices: [FrameworkBestPractice] = [],
        dependencies: [String] = [],
        imports: [String] = [],
        lastCrawled: Date = Date(),
        version: String = "1.0.0"
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.minimumOS = minimumOS
        self.appleDocURL = appleDocURL
        self.swiftDocURL = swiftDocURL
        self.wwdcSessions = wwdcSessions
        self.capabilities = capabilities
        self.bestPractices = bestPractices
        self.dependencies = dependencies
        self.imports = imports
        self.lastCrawled = lastCrawled
        self.version = version
    }
}

// MARK: - Framework Category

/// Categories for organizing Apple frameworks
public enum FrameworkCategory: String, Codable, CaseIterable {
    case ui = "User Interface"
    case data = "Data & Storage"
    case networking = "Networking"
    case media = "Media & Graphics"
    case ml = "Machine Learning"
    case ar = "Augmented Reality"
    case security = "Security & Privacy"
    case system = "System Services"
    
    public var icon: String {
        switch self {
        case .ui: return "rectangle.3.group"
        case .data: return "cylinder.fill"
        case .networking: return "network"
        case .media: return "photo.on.rectangle"
        case .ml: return "brain.head.profile"
        case .ar: return "arkit"
        case .security: return "lock.shield.fill"
        case .system: return "gearshape.2.fill"
        }
    }
}

// MARK: - Framework Capability

/// Represents a specific capability or feature of a framework
public struct FrameworkCapability: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let apiEndpoints: [String]
    public let codeExamples: [CodeExample]
    public let complexity: FrameworkComplexityLevel
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        apiEndpoints: [String] = [],
        codeExamples: [CodeExample] = [],
        complexity: FrameworkComplexityLevel = .intermediate
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.apiEndpoints = apiEndpoints
        self.codeExamples = codeExamples
        self.complexity = complexity
    }
}

// MARK: - Framework Complexity Level

/// Complexity level for framework capabilities
public enum FrameworkComplexityLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    
    public var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        case .expert: return "4.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .beginner: return "#34C759"
        case .intermediate: return "#007AFF"
        case .advanced: return "#FF9500"
        case .expert: return "#FF3B30"
        }
    }
}

// MARK: - Code Example

/// Represents a code example from documentation
public struct CodeExample: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let code: String
    public let language: String
    public let description: String
    public let sourceURL: URL?
    
    public init(
        id: UUID = UUID(),
        title: String,
        code: String,
        language: String = "swift",
        description: String = "",
        sourceURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.code = code
        self.language = language
        self.description = description
        self.sourceURL = sourceURL
    }
}

// MARK: - WWDC Session

/// Represents a WWDC session related to a framework
public struct WWDCSession: Codable, Identifiable {
    public let id: String // e.g., "wwdc2023-10154"
    public let year: Int
    public let title: String
    public let url: URL
    public let transcript: String?
    public let relevantTopics: [String]
    
    public init(
        id: String,
        year: Int,
        title: String,
        url: URL,
        transcript: String? = nil,
        relevantTopics: [String] = []
    ) {
        self.id = id
        self.year = year
        self.title = title
        self.url = url
        self.transcript = transcript
        self.relevantTopics = relevantTopics
    }
}

// MARK: - Framework Best Practice

/// Represents a best practice for using a framework
public struct FrameworkBestPractice: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: BestPracticeCategory
    public let codeExample: CodeExample?
    public let relatedAPIs: [String]
    public let sourceURL: URL?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: BestPracticeCategory,
        codeExample: CodeExample? = nil,
        relatedAPIs: [String] = [],
        sourceURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.codeExample = codeExample
        self.relatedAPIs = relatedAPIs
        self.sourceURL = sourceURL
    }
}

// MARK: - Best Practice Category

/// Categories for best practices
public enum BestPracticeCategory: String, Codable, CaseIterable {
    case performance = "Performance"
    case security = "Security"
    case accessibility = "Accessibility"
    case testing = "Testing"
    case architecture = "Architecture"
    case errorHandling = "Error Handling"
    case concurrency = "Concurrency"
    case memory = "Memory Management"
    
    public var icon: String {
        switch self {
        case .performance: return "speedometer"
        case .security: return "lock.shield"
        case .accessibility: return "accessibility"
        case .testing: return "checkmark.circle"
        case .architecture: return "building.columns"
        case .errorHandling: return "exclamationmark.triangle"
        case .concurrency: return "arrow.triangle.branch"
        case .memory: return "memorychip"
        }
    }
}

// MARK: - Framework Knowledge

/// Aggregated knowledge about a framework from documentation crawling
public struct FrameworkKnowledge: Codable, Identifiable {
    public let id: UUID
    public let framework: AppleFramework
    public let capabilities: [FrameworkCapability]
    public let patternNames: [String] // Store pattern names instead of enum to avoid circular dependency
    public let examples: [CodeExample]
    public let lastUpdated: Date
    
    public init(
        id: UUID = UUID(),
        framework: AppleFramework,
        capabilities: [FrameworkCapability] = [],
        patternNames: [String] = [],
        examples: [CodeExample] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.framework = framework
        self.capabilities = capabilities
        self.patternNames = patternNames
        self.examples = examples
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Predefined Frameworks

extension AppleFramework {
    /// All supported Apple frameworks
    public static var allCases: [AppleFramework] {
        return [
            .swiftUI,
            .swiftData,
            .combine,
            .cloudKit,
            .localAuthentication,
            .mapKit,
            .charts,
            .storeKit,
            .widgetKit,
            .appIntents,
            .realityKit,
            .avFoundation,
            .coreML,
            .vision,
            .naturalLanguage,
            .network,
            .cryptoKit,
            .accessibility,
            .xcTest,
            .instruments
        ]
    }
    
    // MARK: - SwiftUI
    
    public static let swiftUI: AppleFramework = AppleFramework(
        name: "SwiftUI",
        category: FrameworkCategory.ui,
        minimumOS: "macOS 10.15",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/swiftui")!,
        swiftDocURL: URL(string: "https://developer.apple.com/documentation/swiftui"),
        imports: ["SwiftUI"]
    )
    
    // MARK: - SwiftData
    
    public static let swiftData: AppleFramework = AppleFramework(
        name: "SwiftData",
        category: FrameworkCategory.data,
        minimumOS: "macOS 14.0",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/swiftdata")!,
        imports: ["SwiftData"]
    )
    
    // MARK: - Combine
    
    public static let combine: AppleFramework = AppleFramework(
        name: "Combine",
        category: FrameworkCategory.system,
        minimumOS: "macOS 10.15",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/combine")!,
        imports: ["Combine"]
    )
    
    // MARK: - CloudKit
    
    public static let cloudKit: AppleFramework = AppleFramework(
        name: "CloudKit",
        category: FrameworkCategory.data,
        minimumOS: "macOS 10.10",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/cloudkit")!,
        imports: ["CloudKit"]
    )
    
    // MARK: - LocalAuthentication
    
    public static let localAuthentication: AppleFramework = AppleFramework(
        name: "LocalAuthentication",
        category: FrameworkCategory.security,
        minimumOS: "macOS 10.10",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/localauthentication")!,
        imports: ["LocalAuthentication"]
    )
    
    // MARK: - MapKit
    
    public static let mapKit: AppleFramework = AppleFramework(
        name: "MapKit",
        category: FrameworkCategory.media,
        minimumOS: "macOS 10.9",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/mapkit")!,
        imports: ["MapKit"]
    )
    
    // MARK: - Charts
    
    public static let charts: AppleFramework = AppleFramework(
        name: "Charts",
        category: FrameworkCategory.ui,
        minimumOS: "macOS 13.0",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/charts")!,
        imports: ["Charts"]
    )
    
    // MARK: - StoreKit
    
    public static let storeKit: AppleFramework = AppleFramework(
        name: "StoreKit",
        category: FrameworkCategory.system,
        minimumOS: "macOS 10.7",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/storekit")!,
        imports: ["StoreKit"]
    )
    
    // MARK: - WidgetKit
    
    public static let widgetKit: AppleFramework = AppleFramework(
        name: "WidgetKit",
        category: FrameworkCategory.ui,
        minimumOS: "macOS 11.0",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/widgetkit")!,
        imports: ["WidgetKit"]
    )
    
    // MARK: - AppIntents
    
    public static let appIntents: AppleFramework = AppleFramework(
        name: "AppIntents",
        category: FrameworkCategory.system,
        minimumOS: "macOS 13.0",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/appintents")!,
        imports: ["AppIntents"]
    )
    
    // MARK: - RealityKit
    
    public static let realityKit: AppleFramework = AppleFramework(
        name: "RealityKit",
        category: FrameworkCategory.ar,
        minimumOS: "macOS 10.15",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/realitykit")!,
        imports: ["RealityKit"]
    )
    
    // MARK: - AVFoundation
    
    public static let avFoundation: AppleFramework = AppleFramework(
        name: "AVFoundation",
        category: FrameworkCategory.media,
        minimumOS: "macOS 10.7",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/avfoundation")!,
        imports: ["AVFoundation"]
    )
    
    // MARK: - CoreML
    
    public static let coreML: AppleFramework = AppleFramework(
        name: "CoreML",
        category: FrameworkCategory.ml,
        minimumOS: "macOS 10.13",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/coreml")!,
        imports: ["CoreML"]
    )
    
    // MARK: - Vision
    
    public static let vision: AppleFramework = AppleFramework(
        name: "Vision",
        category: FrameworkCategory.ml,
        minimumOS: "macOS 10.13",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/vision")!,
        imports: ["Vision"]
    )
    
    // MARK: - NaturalLanguage
    
    public static let naturalLanguage: AppleFramework = AppleFramework(
        name: "NaturalLanguage",
        category: FrameworkCategory.ml,
        minimumOS: "macOS 10.14",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/naturallanguage")!,
        imports: ["NaturalLanguage"]
    )
    
    // MARK: - Network
    
    public static let network: AppleFramework = AppleFramework(
        name: "Network",
        category: FrameworkCategory.networking,
        minimumOS: "macOS 10.14",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/network")!,
        imports: ["Network"]
    )
    
    // MARK: - CryptoKit
    
    public static let cryptoKit: AppleFramework = AppleFramework(
        name: "CryptoKit",
        category: FrameworkCategory.security,
        minimumOS: "macOS 10.15",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/cryptokit")!,
        imports: ["CryptoKit"]
    )
    
    // MARK: - Accessibility
    
    public static let accessibility: AppleFramework = AppleFramework(
        name: "Accessibility",
        category: FrameworkCategory.ui,
        minimumOS: "macOS 10.10",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/accessibility")!,
        imports: ["Accessibility"]
    )
    
    // MARK: - XCTest
    
    public static let xcTest: AppleFramework = AppleFramework(
        name: "XCTest",
        category: FrameworkCategory.system,
        minimumOS: "macOS 10.10",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/xctest")!,
        imports: ["XCTest"]
    )
    
    // MARK: - Instruments
    
    public static let instruments: AppleFramework = AppleFramework(
        name: "Instruments",
        category: FrameworkCategory.system,
        minimumOS: "macOS 10.10",
        appleDocURL: URL(string: "https://developer.apple.com/documentation/instruments")!,
        imports: []
    )
}
