//
//  OnboardingState.swift
//  Hub
//
//  Created by Hub Onboarding Animation System
//  State management for onboarding flow persistence
//

import Foundation

/// State model for Hub onboarding flow
/// Tracks progress through 5-stage onboarding journey
/// Supports persistence, resume, and skip functionality
/// Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
struct OnboardingState: Codable {
    /// Whether this is the user's first run of the app
    var isFirstRun: Bool
    
    /// Current stage in the onboarding flow
    var currentStage: OnboardingStage
    
    /// User's selected setup plan (Import, New, Template, Remote)
    var selectedPlan: SetupPlan?
    
    /// Modules detected during project scan (AI, Terminal, Packages, etc.)
    var detectedModules: [String]
    
    /// Progress through the wizard configuration steps
    var wizardProgress: WizardProgress
    
    /// Timestamp when onboarding was completed
    var completedAt: Date?
    
    /// Whether user skipped onboarding
    var skipped: Bool
    
    // MARK: - Nested Types
    
    /// Stages in the onboarding flow
    enum OnboardingStage: String, Codable {
        case intro          // Stage 1: Brand moment with Nexus icon
        case planChoice     // Stage 2: Select setup path
        case scan           // Stage 3: Project detection (if Import selected)
        case wizard         // Stage 4: Configuration steps
        case reveal         // Stage 5: Workspace reveal
        case complete       // Onboarding finished
    }
    
    /// User's selected setup plan
    enum SetupPlan: String, Codable {
        case importProject  // Import existing project
        case newPackage     // Create new package
        case cloneTemplate  // Clone from template
        case connectRepo    // Connect remote repository
    }
    
    /// Progress tracking for wizard configuration steps
    struct WizardProgress: Codable {
        /// Current step index (0-based)
        var currentStep: Int
        
        /// Total number of wizard steps
        var totalSteps: Int
        
        /// Set of completed step indices
        var completedSteps: Set<Int>
        
        /// User's selected options (key: option identifier, value: enabled)
        var selectedOptions: [String: Bool]
        
        /// Initialize with default values
        init(currentStep: Int = 0, totalSteps: Int = 4, completedSteps: Set<Int> = [], selectedOptions: [String: Bool] = [:]) {
            self.currentStep = currentStep
            self.totalSteps = totalSteps
            self.completedSteps = completedSteps
            self.selectedOptions = selectedOptions
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize with default first-run state
    init(
        isFirstRun: Bool = true,
        currentStage: OnboardingStage = .intro,
        selectedPlan: SetupPlan? = nil,
        detectedModules: [String] = [],
        wizardProgress: WizardProgress = WizardProgress(),
        completedAt: Date? = nil,
        skipped: Bool = false
    ) {
        self.isFirstRun = isFirstRun
        self.currentStage = currentStage
        self.selectedPlan = selectedPlan
        self.detectedModules = detectedModules
        self.wizardProgress = wizardProgress
        self.completedAt = completedAt
        self.skipped = skipped
    }
    
    // MARK: - Default State
    
    /// Default state for first-time users
    static var `default`: OnboardingState {
        OnboardingState(
            isFirstRun: true,
            currentStage: .intro,
            selectedPlan: nil,
            detectedModules: [],
            wizardProgress: WizardProgress(),
            completedAt: nil,
            skipped: false
        )
    }
    
    // MARK: - State Queries
    
    /// Whether onboarding is complete
    var isComplete: Bool {
        currentStage == .complete || completedAt != nil
    }
    
    /// Whether onboarding is in progress
    var isInProgress: Bool {
        isFirstRun && !isComplete && !skipped
    }
    
    /// Whether user can resume onboarding
    var canResume: Bool {
        isInProgress && currentStage != .intro
    }
    
    /// Progress percentage through onboarding (0.0 to 1.0)
    var progressPercentage: Double {
        let stageWeights: [OnboardingStage: Double] = [
            .intro: 0.0,
            .planChoice: 0.2,
            .scan: 0.4,
            .wizard: 0.6,
            .reveal: 0.8,
            .complete: 1.0
        ]
        
        guard let baseProgress = stageWeights[currentStage] else { return 0.0 }
        
        // Add wizard sub-progress if in wizard stage
        if currentStage == .wizard && wizardProgress.totalSteps > 0 {
            let wizardWeight = 0.2 // wizard stage is 20% of total
            let wizardSubProgress = Double(wizardProgress.currentStep) / Double(wizardProgress.totalSteps)
            return baseProgress + (wizardSubProgress * wizardWeight)
        }
        
        return baseProgress
    }
}

// MARK: - Codable Conformance

extension OnboardingState {
    enum CodingKeys: String, CodingKey {
        case isFirstRun
        case currentStage
        case selectedPlan
        case detectedModules
        case wizardProgress
        case completedAt
        case skipped
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isFirstRun = try container.decode(Bool.self, forKey: .isFirstRun)
        currentStage = try container.decode(OnboardingStage.self, forKey: .currentStage)
        selectedPlan = try container.decodeIfPresent(SetupPlan.self, forKey: .selectedPlan)
        detectedModules = try container.decode([String].self, forKey: .detectedModules)
        wizardProgress = try container.decode(WizardProgress.self, forKey: .wizardProgress)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        skipped = try container.decode(Bool.self, forKey: .skipped)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isFirstRun, forKey: .isFirstRun)
        try container.encode(currentStage, forKey: .currentStage)
        try container.encodeIfPresent(selectedPlan, forKey: .selectedPlan)
        try container.encode(detectedModules, forKey: .detectedModules)
        try container.encode(wizardProgress, forKey: .wizardProgress)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(skipped, forKey: .skipped)
    }
}

// MARK: - WizardProgress Codable

extension OnboardingState.WizardProgress {
    enum CodingKeys: String, CodingKey {
        case currentStep
        case totalSteps
        case completedSteps
        case selectedOptions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        currentStep = try container.decode(Int.self, forKey: .currentStep)
        totalSteps = try container.decode(Int.self, forKey: .totalSteps)
        
        // Decode Set<Int> from array
        let stepsArray = try container.decode([Int].self, forKey: .completedSteps)
        completedSteps = Set(stepsArray)
        
        selectedOptions = try container.decode([String: Bool].self, forKey: .selectedOptions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(currentStep, forKey: .currentStep)
        try container.encode(totalSteps, forKey: .totalSteps)
        
        // Encode Set<Int> as array
        try container.encode(Array(completedSteps), forKey: .completedSteps)
        
        try container.encode(selectedOptions, forKey: .selectedOptions)
    }
}

// MARK: - Equatable

extension OnboardingState: Equatable {
    static func == (lhs: OnboardingState, rhs: OnboardingState) -> Bool {
        lhs.isFirstRun == rhs.isFirstRun &&
        lhs.currentStage == rhs.currentStage &&
        lhs.selectedPlan == rhs.selectedPlan &&
        lhs.detectedModules == rhs.detectedModules &&
        lhs.wizardProgress == rhs.wizardProgress &&
        lhs.completedAt == rhs.completedAt &&
        lhs.skipped == rhs.skipped
    }
}

extension OnboardingState.WizardProgress: Equatable {
    static func == (lhs: OnboardingState.WizardProgress, rhs: OnboardingState.WizardProgress) -> Bool {
        lhs.currentStep == rhs.currentStep &&
        lhs.totalSteps == rhs.totalSteps &&
        lhs.completedSteps == rhs.completedSteps &&
        lhs.selectedOptions == rhs.selectedOptions
    }
}
