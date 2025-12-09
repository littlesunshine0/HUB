import Foundation

// MARK: - Enterprise Preferences

public struct EnterprisePreferences: Codable, Equatable, Sendable {
    // Team Management
    var organizationID: String?
    var teamName: String
    var maxTeamMembers: Int
    var enableTeamSync: Bool
    
    // Automation Settings
    var enableAutomatedQualityControl: Bool
    var enableAutomatedDeployment: Bool
    var enableAutomatedTesting: Bool
    var automationLevel: AutomationLevel
    
    // Analytics & Monitoring
    var enableAnalytics: Bool
    var analyticsRetentionDays: Int
    var enablePerformanceMonitoring: Bool
    var enableErrorTracking: Bool
    
    // Security & Compliance
    var requireTwoFactorAuth: Bool
    var sessionTimeoutMinutes: Int
    var enableAuditLogging: Bool
    var dataResidencyRegion: DataRegion
    
    // SLA & Support
    var slaLevel: SLALevel
    var prioritySupport: Bool
    var dedicatedAccountManager: Bool
    
    // Licensing
    var licenseType: LicenseType
    var seatCount: Int
    var volumeDiscountTier: VolumeTier
    
    // Custom Settings
    var customComplianceRules: [String]
    var customIntegrations: [String: String]
    
    // MARK: - Nested Types
    
    enum AutomationLevel: String, Codable, CaseIterable, Sendable {
        case manual = "Manual"
        case assisted = "Assisted"
        case full = "Full"
        
        var description: String {
            switch self {
            case .manual: return "Manual approval required for all actions"
            case .assisted: return "AI suggests actions, human approves"
            case .full: return "Fully autonomous with human oversight"
            }
        }
    }
    
    enum DataRegion: String, Codable, CaseIterable, Sendable {
        case us = "US"
        case eu = "EU"
        case apac = "APAC"
        case global = "Global"
        
        var description: String {
            switch self {
            case .us: return "United States"
            case .eu: return "European Union"
            case .apac: return "Asia-Pacific"
            case .global: return "Global (multi-region)"
            }
        }
    }
    
    enum SLALevel: String, Codable, CaseIterable, Sendable {
        case standard = "Standard"
        case business = "Business"
        case enterprise = "Enterprise"
        case premium = "Premium"
        
        var uptimeGuarantee: Double {
            switch self {
            case .standard: return 99.0
            case .business: return 99.5
            case .enterprise: return 99.9
            case .premium: return 99.99
            }
        }
        
        var responseTime: String {
            switch self {
            case .standard: return "24 hours"
            case .business: return "4 hours"
            case .enterprise: return "1 hour"
            case .premium: return "15 minutes"
            }
        }
    }
    
    enum LicenseType: String, Codable, CaseIterable, Sendable {
        case trial = "Trial"
        case standard = "Standard"
        case professional = "Professional"
        case enterprise = "Enterprise"
        case unlimited = "Unlimited"
        
        var features: [String] {
            switch self {
            case .trial:
                return ["Basic features", "3 projects", "Community support"]
            case .standard:
                return ["All basic features", "10 projects", "Email support"]
            case .professional:
                return ["All features", "Unlimited projects", "Priority support", "AI assistance"]
            case .enterprise:
                return ["All features", "Unlimited projects", "24/7 support", "Custom integrations", "SLA"]
            case .unlimited:
                return ["Everything", "White-label", "Dedicated infrastructure", "Custom development"]
            }
        }
    }
    
    enum VolumeTier: String, Codable, CaseIterable, Sendable {
        case none = "None"
        case tier1 = "Tier 1 (10-49 seats)"
        case tier2 = "Tier 2 (50-99 seats)"
        case tier3 = "Tier 3 (100-499 seats)"
        case tier4 = "Tier 4 (500+ seats)"
        
        var discountPercentage: Double {
            switch self {
            case .none: return 0
            case .tier1: return 10
            case .tier2: return 20
            case .tier3: return 30
            case .tier4: return 40
            }
        }
    }
    
    // MARK: - Initializer
    
    init(
        organizationID: String? = nil,
        teamName: String = "",
        maxTeamMembers: Int = 10,
        enableTeamSync: Bool = false,
        enableAutomatedQualityControl: Bool = false,
        enableAutomatedDeployment: Bool = false,
        enableAutomatedTesting: Bool = true,
        automationLevel: AutomationLevel = .manual,
        enableAnalytics: Bool = true,
        analyticsRetentionDays: Int = 90,
        enablePerformanceMonitoring: Bool = true,
        enableErrorTracking: Bool = true,
        requireTwoFactorAuth: Bool = false,
        sessionTimeoutMinutes: Int = 60,
        enableAuditLogging: Bool = false,
        dataResidencyRegion: DataRegion = .us,
        slaLevel: SLALevel = .standard,
        prioritySupport: Bool = false,
        dedicatedAccountManager: Bool = false,
        licenseType: LicenseType = .trial,
        seatCount: Int = 1,
        volumeDiscountTier: VolumeTier = .none,
        customComplianceRules: [String] = [],
        customIntegrations: [String: String] = [:]
    ) {
        self.organizationID = organizationID
        self.teamName = teamName
        self.maxTeamMembers = maxTeamMembers
        self.enableTeamSync = enableTeamSync
        self.enableAutomatedQualityControl = enableAutomatedQualityControl
        self.enableAutomatedDeployment = enableAutomatedDeployment
        self.enableAutomatedTesting = enableAutomatedTesting
        self.automationLevel = automationLevel
        self.enableAnalytics = enableAnalytics
        self.analyticsRetentionDays = analyticsRetentionDays
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.enableErrorTracking = enableErrorTracking
        self.requireTwoFactorAuth = requireTwoFactorAuth
        self.sessionTimeoutMinutes = sessionTimeoutMinutes
        self.enableAuditLogging = enableAuditLogging
        self.dataResidencyRegion = dataResidencyRegion
        self.slaLevel = slaLevel
        self.prioritySupport = prioritySupport
        self.dedicatedAccountManager = dedicatedAccountManager
        self.licenseType = licenseType
        self.seatCount = seatCount
        self.volumeDiscountTier = volumeDiscountTier
        self.customComplianceRules = customComplianceRules
        self.customIntegrations = customIntegrations
    }
}
