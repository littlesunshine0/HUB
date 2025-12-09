import SwiftUI

// MARK: - Hub Workspace Animation System
// Complete animation specification for Hub developer workspace
// Covers: AI, Terminal, Packages, Builds, Community, Visual Editor

/// Hub-specific animation definitions extending the base animation system
public enum HubAnimation: String, CaseIterable {
    // MARK: - Core Workspace & Nexus (15)
    case hubNexusPulse
    case moduleOrbitConnect
    case workspaceLayoutTransition
    case panelSlide
    case editorFocusHighlight
    case fileOpen
    case diffHighlightSweep
    case codeLintSweep
    case quickActionPalettePop
    case sidebarStagger
    case inspectorReveal
    case workspaceSnapshot
    case globalSearchHighlight
    case themeSwitchCrossfade
    case hubLiquidGlass
    
    // MARK: - AI & Knowledge (10)
    case aiTyping
    case aiResponseReveal
    case inlineSuggestion
    case refactorPreviewMorph
    case knowledgeGraphExpansion
    case promptHistoryStack
    case aiErrorGlitch
    case insightPulse
    case docLinkHover
    case aiAutocompleteAccept
    
    // MARK: - Terminal & Build Pipeline (10)
    case terminalCursorBlink
    case terminalLineInsert
    case buildPipelineProgress
    case buildSuccessBurst
    case buildFailureShake
    case logStreamFade
    case commandHistoryReveal
    case backgroundTaskSpinner
    case jobQueueFlow
    case gitStatusSweep
    
    // MARK: - Packages & Dependencies (5)
    case packageHover
    case dependencyGraphLayout
    case versionTagPulse
    case publishToHub
    case installPackage
    
    // MARK: - Community & Collaboration (5)
    case presenceDot
    case activityPing
    case commentExpand
    case mergeCelebration
    case liveCursorTrail
    
    // MARK: - Micro-Interactions (5)
    case toolIconBounce
    case hubToastNotification
    case shortcutHint
    case dragDock
    case reducedMotionFallback
    
    // MARK: - Template Gallery (7)
    case templateGalleryIntro
    case templateCardStagger
    case templateCardHover
    case templatePreviewOpen
    case templatePreviewSwitch
    case templateApplyPulse
    case templateFilterChipSelect
    
    // MARK: - Hub Browser (6)
    case browserPanelReveal
    case browserTreeExpand
    case browserTabOpen
    case browserTabClose
    case browserSearchHighlight
    case browserBreadcrumbShift
    
    // MARK: - Marketplace (6)
    case marketplaceIntroHero
    case marketplaceCardHover
    case marketplaceInstallProgress
    case marketplaceInstallComplete
    case marketplaceFilterChipSelect
    case marketplaceSectionExpand
    
    // MARK: - Achievements (6)
    case achievementsPanelIntro
    case achievementUnlockBurst
    case achievementListStagger
    case achievementProgressRing
    case achievementSetComplete
    case achievementToast
    
    // MARK: - Settings (6)
    case settingsPanelReveal
    case settingsSectionExpand
    case settingsToggleChange
    case settingsDangerConfirm
    case settingsSearchHighlight
    case settingsLivePreviewChange
}

// MARK: - Hub Animation Specifications

public struct HubAnimationSpec {
    let animation: HubAnimation
    let duration: TimeInterval
    let easing: AnimationEasing
    let size: AnimationSize
    let context: String
    let reducedMotionFallback: Bool
    
    public enum AnimationSize {
        case micro(CGFloat)           // < 32pt
        case small(CGFloat)            // 32-64pt
        case medium(CGFloat)           // 64-220pt
        case large(CGFloat)            // 220-400pt
        case viewport                  // Full screen/panel
        case adaptive                  // Context-dependent
    }
    
    /// Get SwiftUI Animation for this spec
    public var swiftUIAnimation: Animation {
        return easing.animation(duration: duration)
    }
    
    /// Get reduced motion variant
    public var reducedMotion: Animation {
        return .easeInOut(duration: min(duration, 0.2))
    }
}

// MARK: - Hub Animation Library

public struct HubAnimationLibrary {
    public static let shared = HubAnimationLibrary()
    
    private init() {}
    
    // MARK: - Core Workspace Animations
    
    public let hubNexusPulse = HubAnimationSpec(
        animation: .hubNexusPulse,
        duration: 1.4,
        easing: .easeInOutSine,
        size: .adaptive,
        context: "App launch, main dashboard, workspace overview",
        reducedMotionFallback: true
    )
    
    public let moduleOrbitConnect = HubAnimationSpec(
        animation: .moduleOrbitConnect,
        duration: 0.8,
        easing: .easeOutCubic,
        size: .large(220),
        context: "Module activation, workspace switch",
        reducedMotionFallback: true
    )
    
    public let workspaceLayoutTransition = HubAnimationSpec(
        animation: .workspaceLayoutTransition,
        duration: 0.4,
        easing: .easeInOutQuad,
        size: .viewport,
        context: "Layout changes, panel rearrangement",
        reducedMotionFallback: true
    )
    
    public let panelSlide = HubAnimationSpec(
        animation: .panelSlide,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .medium(200),
        context: "Sidebar/inspector toggle",
        reducedMotionFallback: true
    )
    
    public let editorFocusHighlight = HubAnimationSpec(
        animation: .editorFocusHighlight,
        duration: 0.2,
        easing: .easeOutQuad,
        size: .viewport,
        context: "Editor focus change",
        reducedMotionFallback: true
    )
    
    public let fileOpen = HubAnimationSpec(
        animation: .fileOpen,
        duration: 0.22,
        easing: .easeOutCubic,
        size: .viewport,
        context: "Opening files",
        reducedMotionFallback: true
    )
    
    public let diffHighlightSweep = HubAnimationSpec(
        animation: .diffHighlightSweep,
        duration: 0.45,
        easing: .easeInOutSine,
        size: .viewport,
        context: "Code changes, git diff",
        reducedMotionFallback: true
    )
    
    public let codeLintSweep = HubAnimationSpec(
        animation: .codeLintSweep,
        duration: 0.6,
        easing: .easeOutQuart,
        size: .viewport,
        context: "Linting, validation",
        reducedMotionFallback: true
    )
    
    public let quickActionPalettePop = HubAnimationSpec(
        animation: .quickActionPalettePop,
        duration: 0.2,
        easing: .easeOutBack,
        size: .medium(300),
        context: "Command palette, quick actions",
        reducedMotionFallback: true
    )
    
    public let sidebarStagger = HubAnimationSpec(
        animation: .sidebarStagger,
        duration: 0.35,
        easing: .easeOutCubic,
        size: .medium(200),
        context: "Sidebar item reveal",
        reducedMotionFallback: true
    )
    
    public let inspectorReveal = HubAnimationSpec(
        animation: .inspectorReveal,
        duration: 0.25,
        easing: .easeOutQuad,
        size: .medium(250),
        context: "Inspector panel reveal",
        reducedMotionFallback: true
    )
    
    public let workspaceSnapshot = HubAnimationSpec(
        animation: .workspaceSnapshot,
        duration: 0.3,
        easing: .easeInOutSine,
        size: .micro(20),
        context: "Auto-save indicator",
        reducedMotionFallback: true
    )
    
    public let globalSearchHighlight = HubAnimationSpec(
        animation: .globalSearchHighlight,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .small(40),
        context: "Search results",
        reducedMotionFallback: true
    )
    
    public let themeSwitchCrossfade = HubAnimationSpec(
        animation: .themeSwitchCrossfade,
        duration: 0.3,
        easing: .easeInOutQuad,
        size: .viewport,
        context: "Theme switching",
        reducedMotionFallback: true
    )
    
    public let hubLiquidGlass = HubAnimationSpec(
        animation: .hubLiquidGlass,
        duration: 0.2,
        easing: .easeInOutQuad,
        size: .medium(120),
        context: "Hover effects on cards",
        reducedMotionFallback: true
    )
    
    // MARK: - AI & Knowledge Animations
    
    public let aiTyping = HubAnimationSpec(
        animation: .aiTyping,
        duration: 1.2,
        easing: .easeInOutSine,
        size: .micro(8),
        context: "AI response pending",
        reducedMotionFallback: true
    )
    
    public let aiResponseReveal = HubAnimationSpec(
        animation: .aiResponseReveal,
        duration: 0.35,
        easing: .easeOutCubic,
        size: .viewport,
        context: "AI answer display",
        reducedMotionFallback: true
    )
    
    public let inlineSuggestion = HubAnimationSpec(
        animation: .inlineSuggestion,
        duration: 0.2,
        easing: .easeOutQuad,
        size: .small(40),
        context: "Inline completion",
        reducedMotionFallback: true
    )
    
    public let refactorPreviewMorph = HubAnimationSpec(
        animation: .refactorPreviewMorph,
        duration: 0.5,
        easing: .easeInOutCubic,
        size: .viewport,
        context: "Refactor preview",
        reducedMotionFallback: true
    )
    
    public let knowledgeGraphExpansion = HubAnimationSpec(
        animation: .knowledgeGraphExpansion,
        duration: 0.7,
        easing: .easeOutQuint,
        size: .viewport,
        context: "Knowledge graph reveal",
        reducedMotionFallback: true
    )
    
    public let promptHistoryStack = HubAnimationSpec(
        animation: .promptHistoryStack,
        duration: 0.3,
        easing: .easeOutBack,
        size: .medium(200),
        context: "Prompt history",
        reducedMotionFallback: true
    )
    
    public let aiErrorGlitch = HubAnimationSpec(
        animation: .aiErrorGlitch,
        duration: 0.25,
        easing: .easeOutExpo,
        size: .small(40),
        context: "AI error state",
        reducedMotionFallback: true
    )
    
    public let insightPulse = HubAnimationSpec(
        animation: .insightPulse,
        duration: 0.8,
        easing: .easeInOutSine,
        size: .small(32),
        context: "AI insights",
        reducedMotionFallback: true
    )
    
    public let docLinkHover = HubAnimationSpec(
        animation: .docLinkHover,
        duration: 0.15,
        easing: .easeOutQuad,
        size: .micro(16),
        context: "Documentation links",
        reducedMotionFallback: true
    )
    
    public let aiAutocompleteAccept = HubAnimationSpec(
        animation: .aiAutocompleteAccept,
        duration: 0.2,
        easing: .easeOutCubic,
        size: .small(40),
        context: "Accepting completion",
        reducedMotionFallback: true
    )
    
    // MARK: - Terminal & Build Animations
    
    public let terminalCursorBlink = HubAnimationSpec(
        animation: .terminalCursorBlink,
        duration: 1.0,
        easing: .linear,
        size: .micro(8),
        context: "Terminal cursor",
        reducedMotionFallback: false
    )
    
    public let terminalLineInsert = HubAnimationSpec(
        animation: .terminalLineInsert,
        duration: 0.15,
        easing: .easeOutQuad,
        size: .small(40),
        context: "Terminal output",
        reducedMotionFallback: true
    )
    
    public let buildPipelineProgress = HubAnimationSpec(
        animation: .buildPipelineProgress,
        duration: 1.0,
        easing: .easeInOutSine,
        size: .medium(200),
        context: "Build progress",
        reducedMotionFallback: true
    )
    
    public let buildSuccessBurst = HubAnimationSpec(
        animation: .buildSuccessBurst,
        duration: 0.5,
        easing: .easeOutBack,
        size: .small(48),
        context: "Build success",
        reducedMotionFallback: true
    )
    
    public let buildFailureShake = HubAnimationSpec(
        animation: .buildFailureShake,
        duration: 0.45,
        easing: .easeInOutSine,
        size: .medium(100),
        context: "Build failure",
        reducedMotionFallback: true
    )
    
    public let logStreamFade = HubAnimationSpec(
        animation: .logStreamFade,
        duration: 0.15,
        easing: .linear,
        size: .viewport,
        context: "Log streaming",
        reducedMotionFallback: true
    )
    
    public let commandHistoryReveal = HubAnimationSpec(
        animation: .commandHistoryReveal,
        duration: 0.22,
        easing: .easeOutCubic,
        size: .medium(150),
        context: "Command history",
        reducedMotionFallback: true
    )
    
    public let backgroundTaskSpinner = HubAnimationSpec(
        animation: .backgroundTaskSpinner,
        duration: 0.9,
        easing: .linear,
        size: .micro(18),
        context: "Background tasks",
        reducedMotionFallback: true
    )
    
    public let jobQueueFlow = HubAnimationSpec(
        animation: .jobQueueFlow,
        duration: 0.6,
        easing: .easeInOutSine,
        size: .medium(200),
        context: "Job queue",
        reducedMotionFallback: true
    )
    
    public let gitStatusSweep = HubAnimationSpec(
        animation: .gitStatusSweep,
        duration: 0.5,
        easing: .easeOutQuad,
        size: .viewport,
        context: "Git status refresh",
        reducedMotionFallback: true
    )
    
    // MARK: - Package & Dependency Animations
    
    public let packageHover = HubAnimationSpec(
        animation: .packageHover,
        duration: 0.18,
        easing: .easeInOutQuad,
        size: .medium(120),
        context: "Package card hover",
        reducedMotionFallback: true
    )
    
    public let dependencyGraphLayout = HubAnimationSpec(
        animation: .dependencyGraphLayout,
        duration: 1.0,
        easing: .easeInOutCubic,
        size: .viewport,
        context: "Dependency graph",
        reducedMotionFallback: true
    )
    
    public let versionTagPulse = HubAnimationSpec(
        animation: .versionTagPulse,
        duration: 0.5,
        easing: .easeInOutSine,
        size: .micro(24),
        context: "Version badges",
        reducedMotionFallback: true
    )
    
    public let publishToHub = HubAnimationSpec(
        animation: .publishToHub,
        duration: 0.9,
        easing: .easeOutExpo,
        size: .medium(150),
        context: "Publishing packages",
        reducedMotionFallback: true
    )
    
    public let installPackage = HubAnimationSpec(
        animation: .installPackage,
        duration: 0.7,
        easing: .easeOutCubic,
        size: .medium(100),
        context: "Installing packages",
        reducedMotionFallback: true
    )
    
    // MARK: - Community & Collaboration Animations
    
    public let presenceDot = HubAnimationSpec(
        animation: .presenceDot,
        duration: 1.2,
        easing: .easeInOutSine,
        size: .micro(10),
        context: "User presence",
        reducedMotionFallback: true
    )
    
    public let activityPing = HubAnimationSpec(
        animation: .activityPing,
        duration: 0.6,
        easing: .easeOutQuad,
        size: .small(40),
        context: "Activity notifications",
        reducedMotionFallback: true
    )
    
    public let commentExpand = HubAnimationSpec(
        animation: .commentExpand,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .medium(200),
        context: "Comment threads",
        reducedMotionFallback: true
    )
    
    public let mergeCelebration = HubAnimationSpec(
        animation: .mergeCelebration,
        duration: 0.9,
        easing: .easeOutBack,
        size: .medium(100),
        context: "Merge success",
        reducedMotionFallback: true
    )
    
    public let liveCursorTrail = HubAnimationSpec(
        animation: .liveCursorTrail,
        duration: 0.3,
        easing: .easeOutQuad,
        size: .micro(12),
        context: "Live collaboration",
        reducedMotionFallback: true
    )
    
    // MARK: - Micro-Interactions
    
    public let toolIconBounce = HubAnimationSpec(
        animation: .toolIconBounce,
        duration: 0.18,
        easing: .easeOutBack,
        size: .small(32),
        context: "Toolbar interactions",
        reducedMotionFallback: true
    )
    
    public let hubToastNotification = HubAnimationSpec(
        animation: .hubToastNotification,
        duration: 0.35,
        easing: .easeOutExpo,
        size: .medium(200),
        context: "Toast notifications",
        reducedMotionFallback: true
    )
    
    public let shortcutHint = HubAnimationSpec(
        animation: .shortcutHint,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .small(60),
        context: "Keyboard hints",
        reducedMotionFallback: true
    )
    
    public let dragDock = HubAnimationSpec(
        animation: .dragDock,
        duration: 0.2,
        easing: .easeOutQuad,
        size: .medium(100),
        context: "Drag and drop",
        reducedMotionFallback: true
    )
    
    // MARK: - Template Gallery Animations
    
    public let templateGalleryIntro = HubAnimationSpec(
        animation: .templateGalleryIntro,
        duration: 0.5,
        easing: .easeOutCubic,
        size: .viewport,
        context: "Gallery initial load",
        reducedMotionFallback: true
    )
    
    public let templateCardStagger = HubAnimationSpec(
        animation: .templateCardStagger,
        duration: 0.28,
        easing: .easeOutCubic,
        size: .medium(120),
        context: "Template cards cascade",
        reducedMotionFallback: true
    )
    
    public let templateCardHover = HubAnimationSpec(
        animation: .templateCardHover,
        duration: 0.16,
        easing: .easeInOutQuad,
        size: .medium(120),
        context: "Template card hover",
        reducedMotionFallback: true
    )
    
    public let templatePreviewOpen = HubAnimationSpec(
        animation: .templatePreviewOpen,
        duration: 0.32,
        easing: .easeOutQuart,
        size: .large(400),
        context: "Template preview sheet",
        reducedMotionFallback: true
    )
    
    public let templatePreviewSwitch = HubAnimationSpec(
        animation: .templatePreviewSwitch,
        duration: 0.25,
        easing: .easeInOutQuad,
        size: .viewport,
        context: "Preview navigation",
        reducedMotionFallback: true
    )
    
    public let templateApplyPulse = HubAnimationSpec(
        animation: .templateApplyPulse,
        duration: 0.22,
        easing: .easeOutBack,
        size: .small(48),
        context: "Template applied",
        reducedMotionFallback: true
    )
    
    public let templateFilterChipSelect = HubAnimationSpec(
        animation: .templateFilterChipSelect,
        duration: 0.14,
        easing: .easeInOutQuad,
        size: .small(60),
        context: "Filter selection",
        reducedMotionFallback: true
    )
    
    // MARK: - Hub Browser Animations
    
    public let browserPanelReveal = HubAnimationSpec(
        animation: .browserPanelReveal,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .medium(250),
        context: "Browser panel toggle",
        reducedMotionFallback: true
    )
    
    public let browserTreeExpand = HubAnimationSpec(
        animation: .browserTreeExpand,
        duration: 0.18,
        easing: .easeOutQuad,
        size: .medium(200),
        context: "Tree node expansion",
        reducedMotionFallback: true
    )
    
    public let browserTabOpen = HubAnimationSpec(
        animation: .browserTabOpen,
        duration: 0.2,
        easing: .easeOutCubic,
        size: .small(40),
        context: "New tab open",
        reducedMotionFallback: true
    )
    
    public let browserTabClose = HubAnimationSpec(
        animation: .browserTabClose,
        duration: 0.18,
        easing: .easeInOutQuad,
        size: .small(40),
        context: "Tab close",
        reducedMotionFallback: true
    )
    
    public let browserSearchHighlight = HubAnimationSpec(
        animation: .browserSearchHighlight,
        duration: 0.35,
        easing: .easeOutCubic,
        size: .small(40),
        context: "Search result highlight",
        reducedMotionFallback: true
    )
    
    public let browserBreadcrumbShift = HubAnimationSpec(
        animation: .browserBreadcrumbShift,
        duration: 0.22,
        easing: .easeInOutQuad,
        size: .medium(200),
        context: "Breadcrumb navigation",
        reducedMotionFallback: true
    )
    
    // MARK: - Marketplace Animations
    
    public let marketplaceIntroHero = HubAnimationSpec(
        animation: .marketplaceIntroHero,
        duration: 0.45,
        easing: .easeOutCubic,
        size: .viewport,
        context: "Marketplace intro",
        reducedMotionFallback: true
    )
    
    public let marketplaceCardHover = HubAnimationSpec(
        animation: .marketplaceCardHover,
        duration: 0.18,
        easing: .easeInOutQuad,
        size: .medium(150),
        context: "Marketplace card hover",
        reducedMotionFallback: true
    )
    
    public let marketplaceInstallProgress = HubAnimationSpec(
        animation: .marketplaceInstallProgress,
        duration: 0.6,
        easing: .easeInOutCubic,
        size: .medium(100),
        context: "Install progress",
        reducedMotionFallback: true
    )
    
    public let marketplaceInstallComplete = HubAnimationSpec(
        animation: .marketplaceInstallComplete,
        duration: 0.3,
        easing: .easeOutBack,
        size: .small(48),
        context: "Install success",
        reducedMotionFallback: true
    )
    
    public let marketplaceFilterChipSelect = HubAnimationSpec(
        animation: .marketplaceFilterChipSelect,
        duration: 0.14,
        easing: .easeInOutQuad,
        size: .small(60),
        context: "Marketplace filter",
        reducedMotionFallback: true
    )
    
    public let marketplaceSectionExpand = HubAnimationSpec(
        animation: .marketplaceSectionExpand,
        duration: 0.24,
        easing: .easeOutQuad,
        size: .medium(200),
        context: "Section expand/collapse",
        reducedMotionFallback: true
    )
    
    // MARK: - Achievements Animations
    
    public let achievementsPanelIntro = HubAnimationSpec(
        animation: .achievementsPanelIntro,
        duration: 0.35,
        easing: .easeOutCubic,
        size: .viewport,
        context: "Achievements panel",
        reducedMotionFallback: true
    )
    
    public let achievementUnlockBurst = HubAnimationSpec(
        animation: .achievementUnlockBurst,
        duration: 0.9,
        easing: .easeOutBack,
        size: .medium(100),
        context: "Achievement unlock",
        reducedMotionFallback: true
    )
    
    public let achievementListStagger = HubAnimationSpec(
        animation: .achievementListStagger,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .small(40),
        context: "Achievement list reveal",
        reducedMotionFallback: true
    )
    
    public let achievementProgressRing = HubAnimationSpec(
        animation: .achievementProgressRing,
        duration: 0.7,
        easing: .easeOutCubic,
        size: .medium(80),
        context: "Progress ring fill",
        reducedMotionFallback: true
    )
    
    public let achievementSetComplete = HubAnimationSpec(
        animation: .achievementSetComplete,
        duration: 0.6,
        easing: .easeOutBack,
        size: .medium(120),
        context: "Achievement set complete",
        reducedMotionFallback: true
    )
    
    public let achievementToast = HubAnimationSpec(
        animation: .achievementToast,
        duration: 0.4,
        easing: .easeOutExpo,
        size: .medium(200),
        context: "Achievement notification",
        reducedMotionFallback: true
    )
    
    // MARK: - Settings Animations
    
    public let settingsPanelReveal = HubAnimationSpec(
        animation: .settingsPanelReveal,
        duration: 0.25,
        easing: .easeOutCubic,
        size: .viewport,
        context: "Settings panel open",
        reducedMotionFallback: true
    )
    
    public let settingsSectionExpand = HubAnimationSpec(
        animation: .settingsSectionExpand,
        duration: 0.22,
        easing: .easeOutQuad,
        size: .medium(200),
        context: "Settings section expand",
        reducedMotionFallback: true
    )
    
    public let settingsToggleChange = HubAnimationSpec(
        animation: .settingsToggleChange,
        duration: 0.14,
        easing: .easeInOutQuad,
        size: .small(32),
        context: "Toggle interaction",
        reducedMotionFallback: true
    )
    
    public let settingsDangerConfirm = HubAnimationSpec(
        animation: .settingsDangerConfirm,
        duration: 0.22,
        easing: .easeInOutSine,
        size: .medium(100),
        context: "Destructive action",
        reducedMotionFallback: true
    )
    
    public let settingsSearchHighlight = HubAnimationSpec(
        animation: .settingsSearchHighlight,
        duration: 0.3,
        easing: .easeOutCubic,
        size: .small(40),
        context: "Settings search result",
        reducedMotionFallback: true
    )
    
    public let settingsLivePreviewChange = HubAnimationSpec(
        animation: .settingsLivePreviewChange,
        duration: 0.4,
        easing: .easeInOutQuad,
        size: .viewport,
        context: "Live preview update",
        reducedMotionFallback: true
    )
    
    // MARK: - Helper Methods
    
    /// Get animation spec by name
    public func spec(for animation: HubAnimation) -> HubAnimationSpec {
        switch animation {
        // Core Workspace
        case .hubNexusPulse: return hubNexusPulse
        case .moduleOrbitConnect: return moduleOrbitConnect
        case .workspaceLayoutTransition: return workspaceLayoutTransition
        case .panelSlide: return panelSlide
        case .editorFocusHighlight: return editorFocusHighlight
        case .fileOpen: return fileOpen
        case .diffHighlightSweep: return diffHighlightSweep
        case .codeLintSweep: return codeLintSweep
        case .quickActionPalettePop: return quickActionPalettePop
        case .sidebarStagger: return sidebarStagger
        case .inspectorReveal: return inspectorReveal
        case .workspaceSnapshot: return workspaceSnapshot
        case .globalSearchHighlight: return globalSearchHighlight
        case .themeSwitchCrossfade: return themeSwitchCrossfade
        case .hubLiquidGlass: return hubLiquidGlass
        
        // AI & Knowledge
        case .aiTyping: return aiTyping
        case .aiResponseReveal: return aiResponseReveal
        case .inlineSuggestion: return inlineSuggestion
        case .refactorPreviewMorph: return refactorPreviewMorph
        case .knowledgeGraphExpansion: return knowledgeGraphExpansion
        case .promptHistoryStack: return promptHistoryStack
        case .aiErrorGlitch: return aiErrorGlitch
        case .insightPulse: return insightPulse
        case .docLinkHover: return docLinkHover
        case .aiAutocompleteAccept: return aiAutocompleteAccept
        
        // Terminal & Build
        case .terminalCursorBlink: return terminalCursorBlink
        case .terminalLineInsert: return terminalLineInsert
        case .buildPipelineProgress: return buildPipelineProgress
        case .buildSuccessBurst: return buildSuccessBurst
        case .buildFailureShake: return buildFailureShake
        case .logStreamFade: return logStreamFade
        case .commandHistoryReveal: return commandHistoryReveal
        case .backgroundTaskSpinner: return backgroundTaskSpinner
        case .jobQueueFlow: return jobQueueFlow
        case .gitStatusSweep: return gitStatusSweep
        
        // Packages & Dependencies
        case .packageHover: return packageHover
        case .dependencyGraphLayout: return dependencyGraphLayout
        case .versionTagPulse: return versionTagPulse
        case .publishToHub: return publishToHub
        case .installPackage: return installPackage
        
        // Community & Collaboration
        case .presenceDot: return presenceDot
        case .activityPing: return activityPing
        case .commentExpand: return commentExpand
        case .mergeCelebration: return mergeCelebration
        case .liveCursorTrail: return liveCursorTrail
        
        // Micro-Interactions
        case .toolIconBounce: return toolIconBounce
        case .hubToastNotification: return hubToastNotification
        case .shortcutHint: return shortcutHint
        case .dragDock: return dragDock
        case .reducedMotionFallback: return hubToastNotification // Fallback
        
        // Template Gallery
        case .templateGalleryIntro: return templateGalleryIntro
        case .templateCardStagger: return templateCardStagger
        case .templateCardHover: return templateCardHover
        case .templatePreviewOpen: return templatePreviewOpen
        case .templatePreviewSwitch: return templatePreviewSwitch
        case .templateApplyPulse: return templateApplyPulse
        case .templateFilterChipSelect: return templateFilterChipSelect
        
        // Hub Browser
        case .browserPanelReveal: return browserPanelReveal
        case .browserTreeExpand: return browserTreeExpand
        case .browserTabOpen: return browserTabOpen
        case .browserTabClose: return browserTabClose
        case .browserSearchHighlight: return browserSearchHighlight
        case .browserBreadcrumbShift: return browserBreadcrumbShift
        
        // Marketplace
        case .marketplaceIntroHero: return marketplaceIntroHero
        case .marketplaceCardHover: return marketplaceCardHover
        case .marketplaceInstallProgress: return marketplaceInstallProgress
        case .marketplaceInstallComplete: return marketplaceInstallComplete
        case .marketplaceFilterChipSelect: return marketplaceFilterChipSelect
        case .marketplaceSectionExpand: return marketplaceSectionExpand
        
        // Achievements
        case .achievementsPanelIntro: return achievementsPanelIntro
        case .achievementUnlockBurst: return achievementUnlockBurst
        case .achievementListStagger: return achievementListStagger
        case .achievementProgressRing: return achievementProgressRing
        case .achievementSetComplete: return achievementSetComplete
        case .achievementToast: return achievementToast
        
        // Settings
        case .settingsPanelReveal: return settingsPanelReveal
        case .settingsSectionExpand: return settingsSectionExpand
        case .settingsToggleChange: return settingsToggleChange
        case .settingsDangerConfirm: return settingsDangerConfirm
        case .settingsSearchHighlight: return settingsSearchHighlight
        case .settingsLivePreviewChange: return settingsLivePreviewChange
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Apply Hub animation with automatic reduced motion support
    public func hubAnimation(_ animation: HubAnimation, value: some Equatable) -> some View {
        let spec = HubAnimationLibrary.shared.spec(for: animation)
        let shouldReduceMotion = Self.isReduceMotionEnabled()
        
        return self.animation(
            shouldReduceMotion && spec.reducedMotionFallback ? spec.reducedMotion : spec.swiftUIAnimation,
            value: value
        )
    }
    
    /// Apply Hub animation on appear
    public func hubAnimationOnAppear(_ animation: HubAnimation) -> some View {
        let spec = HubAnimationLibrary.shared.spec(for: animation)
        let shouldReduceMotion = Self.isReduceMotionEnabled()
        
        return self.animation(
            shouldReduceMotion && spec.reducedMotionFallback ? spec.reducedMotion : spec.swiftUIAnimation
        )
    }
    
    /// Check if reduce motion is enabled across platforms
    private static func isReduceMotionEnabled() -> Bool {
        #if os(macOS)
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #elseif os(iOS) || os(tvOS) || os(watchOS)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
}

