//
//  HubOnboardingAnimation.swift
//  Hub
//
//  Created for Hub Onboarding Animation System
//

import SwiftUI

// MARK: - Hub Onboarding Animation

/// Named animations for the Hub onboarding flow
/// Each case represents one of the 15 choreographed animations across 5 stages
public enum HubOnboardingAnimation: String, CaseIterable {
    // Stage 1: Intro & Brand Moment
    case hubOnboardingIntro
    case hubNexusIntro // Alias for hubOnboardingIntro
    case backgroundFade
    case iconToHeader
    case canvasFadeIn
    
    // Stage 2: Plan Selection
    case onboardingPlanGridStagger
    case planCardEntrance // Alias for onboardingPlanGridStagger
    case onboardingPlanHover
    case planCardHover // Alias for onboardingPlanHover
    case onboardingPlanSelect
    case planCardSelect // Alias for onboardingPlanSelect
    
    // Stage 3: Project Scan & Detection
    case projectScanSweep
    case scanSweep // Alias for projectScanSweep
    case moduleDetectionPop
    case moduleChipPop // Alias for moduleDetectionPop
    case scanCompleteCheck
    case scanComplete // Alias for scanCompleteCheck
    
    // Stage 4: Wizard Flow
    case wizardEnter
    case wizardSlideIn // Alias for wizardEnter
    case wizardStepTransition
    case stepTransition // Alias for wizardStepTransition
    case wizardProgressIndicator
    case wizardOptionToggle
    case wizardStepCompletePulse
    
    // Stage 5: Workspace Reveal
    case workspaceRevealFromOnboarding
    case wizardCollapse // Alias for workspaceRevealFromOnboarding
    case moduleOrbit
    case sidebarSlideIn
    case inspectorSlideIn
    case editorFocus
    case firstRunTipsOverlay
    case tooltipFade // Alias for firstRunTipsOverlay
    case keyboardOnboardingHint
    case keyboardHint // Alias for keyboardOnboardingHint
    
    // MARK: - Animation Spec
    
    /// Get the complete AnimationSpec for this animation
    public var spec: AnimationSpec {
        switch self {
        case .hubOnboardingIntro, .hubNexusIntro:
            return Self.createIntroSpec()
        case .backgroundFade:
            return Self.createBackgroundFadeSpec()
        case .iconToHeader:
            return Self.createIconToHeaderSpec()
        case .canvasFadeIn:
            return Self.createCanvasFadeInSpec()
        case .onboardingPlanGridStagger, .planCardEntrance:
            return Self.createPlanGridStaggerSpec()
        case .onboardingPlanHover, .planCardHover:
            return Self.createPlanHoverSpec()
        case .onboardingPlanSelect, .planCardSelect:
            return Self.createPlanSelectSpec()
        case .projectScanSweep, .scanSweep:
            return Self.createScanSweepSpec()
        case .moduleDetectionPop, .moduleChipPop:
            return Self.createModuleDetectionPopSpec()
        case .scanCompleteCheck, .scanComplete:
            return Self.createScanCompleteCheckSpec()
        case .wizardEnter, .wizardSlideIn:
            return Self.createWizardEnterSpec()
        case .wizardStepTransition, .stepTransition:
            return Self.createWizardStepTransitionSpec()
        case .wizardProgressIndicator:
            return Self.createWizardProgressIndicatorSpec()
        case .wizardOptionToggle:
            return Self.createWizardOptionToggleSpec()
        case .wizardStepCompletePulse:
            return Self.createWizardStepCompletePulseSpec()
        case .workspaceRevealFromOnboarding, .wizardCollapse:
            return Self.createWorkspaceRevealSpec()
        case .moduleOrbit:
            return Self.createModuleOrbitSpec()
        case .sidebarSlideIn:
            return Self.createSidebarSlideInSpec()
        case .inspectorSlideIn:
            return Self.createInspectorSlideInSpec()
        case .editorFocus:
            return Self.createEditorFocusSpec()
        case .firstRunTipsOverlay, .tooltipFade:
            return Self.createFirstRunTipsOverlaySpec()
        case .keyboardOnboardingHint, .keyboardHint:
            return Self.createKeyboardOnboardingHintSpec()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get animation duration
    var duration: TimeInterval {
        return spec.duration
    }
    
    /// Get animation easing
    var easing: AnimationEasing {
        return spec.easing
    }
    
    /// Check if reduce motion alternative exists
    var hasReduceMotion: Bool {
        return spec.hasReduceMotionAlternative
    }
    
    /// Get SwiftUI animation
    var animation: Animation {
        return spec.animation
    }
    
    /// Get stagger delay if applicable
    var stagger: TimeInterval? {
        return spec.stagger
    }
    
    /// Check if animation is repeatable
    var isRepeatable: Bool {
        return spec.repeatable
    }
}

// MARK: - Animation Spec Factories

extension HubOnboardingAnimation {
    
    // MARK: Stage 1: Intro
    
    private static func createIntroSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "hubOnboardingIntro",
            duration: 0.7,
            easing: .easeOutCubic,
            size: .fullScreen,
            description: "App launches, Nexus icon resolves in, then compresses to header",
            visualBehavior: [
                "nexusIcon": [
                    VisualBehaviorStep(type: .scale, fromValue: 0.8, toValue: 1.05, at: 0.0),
                    VisualBehaviorStep(type: .scale, fromValue: 1.05, toValue: 1.0, at: 0.4),
                    VisualBehaviorStep(type: .glow, at: 0.3, intensity: 0.6),
                    VisualBehaviorStep(type: .slideToPosition, at: 0.5, duration: 0.2)
                ],
                "background": [
                    VisualBehaviorStep(type: .fade, duration: 0.7)
                ],
                "onboardingCanvas": [
                    VisualBehaviorStep(type: .fade, fromValue: 0, toValue: 1, at: 0.5, duration: 0.2)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "nexusIcon": [
                        VisualBehaviorStep(type: .fade, fromValue: 0, toValue: 1, duration: 0.3)
                    ],
                    "background": [
                        VisualBehaviorStep(type: .instant)
                    ],
                    "onboardingCanvas": [
                        VisualBehaviorStep(type: .fade, fromValue: 0, toValue: 1, duration: 0.3)
                    ]
                ]
            )
        )
    }
    
    // MARK: Stage 2: Plan Selection
    
    private static func createPlanGridStaggerSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "onboardingPlanGridStagger",
            duration: 0.4,
            easing: .easeOutCubic,
            size: .region,
            description: "Plan cards slide up and fade in with stagger",
            visualBehavior: [
                "planCard": [
                    VisualBehaviorStep(type: .translateY, fromValue: 16, toValue: 0),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1),
                    VisualBehaviorStep(type: .shadow, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "planCard": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            ),
            stagger: 0.05
        )
    }
    
    private static func createPlanHoverSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "onboardingPlanHover",
            duration: 0.18,
            easing: .easeInOutQuad,
            size: .element,
            description: "Hover/tap focus on a plan card",
            visualBehavior: [
                "planCard": [
                    VisualBehaviorStep(type: .scale, fromValue: 1.0, toValue: 1.03),
                    VisualBehaviorStep(type: .border, color: "accent", intensity: 2)
                ],
                "icon": [
                    VisualBehaviorStep(type: .translateY, fromValue: 0, toValue: -4),
                    VisualBehaviorStep(type: .glow, intensity: 0.3)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "planCard": [
                        VisualBehaviorStep(type: .border, color: "accent", intensity: 2)
                    ]
                ]
            ),
            platformAdaptations: [
                PlatformAdaptation(platform: .macOS, trigger: .onMouseEnter),
                PlatformAdaptation(platform: .iOS, trigger: .onTouchDown),
                PlatformAdaptation(platform: .tvOS, trigger: .onFocus)
            ]
        )
    }
    
    private static func createPlanSelectSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "onboardingPlanSelect",
            duration: 0.25,
            easing: .easeOutBack,
            size: .region,
            description: "Selected card locks in, others dim and slide back",
            visualBehavior: [
                "selectedCard": [
                    VisualBehaviorStep(type: .scale, fromValue: 1.03, toValue: 1.0),
                    VisualBehaviorStep(type: .highlight, duration: 0.15)
                ],
                "nonSelectedCards": [
                    VisualBehaviorStep(type: .opacity, fromValue: 1.0, toValue: 0.4),
                    VisualBehaviorStep(type: .translateY, fromValue: 0, toValue: 6)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "selectedCard": [
                        VisualBehaviorStep(type: .highlight, color: "accent")
                    ],
                    "nonSelectedCards": [
                        VisualBehaviorStep(type: .opacity, fromValue: 1.0, toValue: 0.4, duration: 0.15)
                    ]
                ]
            )
        )
    }
    
    // MARK: Stage 3: Scan & Detection
    
    private static func createScanSweepSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "projectScanSweep",
            duration: 0.8,
            easing: .easeInOutSine,
            size: .region,
            description: "Horizontal scan bar sweeps while indexing",
            visualBehavior: [
                "scanBar": [
                    VisualBehaviorStep(type: .translateX, fromValue: -1.0, toValue: 1.0),
                    VisualBehaviorStep(type: .gradient),
                    VisualBehaviorStep(type: .opacity, fromValue: 0.6, toValue: 0.6)
                ],
                "fileIcons": [
                    VisualBehaviorStep(type: .fadeIn)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "scanBar": [
                        VisualBehaviorStep(type: .hidden)
                    ],
                    "fileIcons": [
                        VisualBehaviorStep(type: .fadeIn)
                    ]
                ]
            ),
            repeatable: true
        )
    }
    
    private static func createModuleDetectionPopSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "moduleDetectionPop",
            duration: 0.2,
            easing: .easeOutBack,
            size: .element,
            description: "Detected modules appear as chips with pop",
            visualBehavior: [
                "moduleChip": [
                    VisualBehaviorStep(type: .scale, fromValue: 0.9, toValue: 1.05, at: 0.0),
                    VisualBehaviorStep(type: .scale, fromValue: 1.05, toValue: 1.0, at: 0.12),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "moduleChip": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.15)
                    ]
                ]
            ),
            stagger: 0.06
        )
    }
    
    private static func createScanCompleteCheckSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "scanCompleteCheck",
            duration: 0.3,
            easing: .easeOutBack,
            size: .element,
            description: "Checkmark with 'Workspace Ready' message",
            visualBehavior: [
                "checkmark": [
                    VisualBehaviorStep(type: .strokeDraw, fromValue: 0, toValue: 1, duration: 0.2),
                    VisualBehaviorStep(type: .glow, at: 0.2, color: "green", intensity: 0.5)
                ],
                "label": [
                    VisualBehaviorStep(type: .fadeIn, at: 0.15, duration: 0.15)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "checkmark": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ],
                    "label": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            )
        )
    }
    
    // MARK: Stage 4: Wizard Flow
    
    private static func createWizardEnterSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "wizardEnter",
            duration: 0.35,
            easing: .easeOutCubic,
            size: .region,
            description: "Wizard overlay slides in and settles",
            visualBehavior: [
                "wizardContainer": [
                    VisualBehaviorStep(type: .translateY, fromValue: 20, toValue: 0),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ],
                "backdrop": [
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 0.45),
                    VisualBehaviorStep(type: .blur, fromValue: 0, toValue: 20)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "wizardContainer": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ],
                    "backdrop": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 0.45, duration: 0.2)
                    ]
                ]
            )
        )
    }
    
    private static func createWizardStepTransitionSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "wizardStepTransition",
            duration: 0.28,
            easing: .easeInOutQuad,
            size: .region,
            description: "Content slides and crossfades between steps",
            visualBehavior: [
                "currentStep": [
                    VisualBehaviorStep(type: .translateX, fromValue: 0, toValue: -40),
                    VisualBehaviorStep(type: .opacity, fromValue: 1, toValue: 0)
                ],
                "nextStep": [
                    VisualBehaviorStep(type: .translateX, fromValue: 40, toValue: 0),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "currentStep": [
                        VisualBehaviorStep(type: .opacity, fromValue: 1, toValue: 0, duration: 0.15)
                    ],
                    "nextStep": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.15)
                    ]
                ]
            )
        )
    }
    
    private static func createWizardProgressIndicatorSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "wizardProgressIndicator",
            duration: 0.4,
            easing: .easeOutCubic,
            size: .element,
            description: "Progress bar/dots animate on step change",
            visualBehavior: [
                "progressBar": [
                    VisualBehaviorStep(type: .fillWidth, duration: 0.4),
                    VisualBehaviorStep(type: .glow, at: 0.2, color: "accent", intensity: 0.4)
                ],
                "progressDot": [
                    VisualBehaviorStep(type: .jump, duration: 0.15, distance: 1.2),
                    VisualBehaviorStep(type: .checkmark, at: 0.2)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "progressBar": [
                        VisualBehaviorStep(type: .fillWidth)
                    ],
                    "progressDot": [
                        VisualBehaviorStep(type: .checkmark)
                    ]
                ]
            )
        )
    }
    
    private static func createWizardOptionToggleSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "wizardOptionToggle",
            duration: 0.16,
            easing: .easeInOutQuad,
            size: .element,
            description: "Micro feedback for option toggles",
            visualBehavior: [
                "switchThumb": [
                    VisualBehaviorStep(type: .slide),
                    VisualBehaviorStep(type: .scale, fromValue: 1.0, toValue: 1.1, at: 0.05),
                    VisualBehaviorStep(type: .scale, fromValue: 1.1, toValue: 1.0, at: 0.11)
                ],
                "label": [
                    VisualBehaviorStep(type: .tint, fromValue: 0.5, toValue: 1.0)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "switchThumb": [
                        VisualBehaviorStep(type: .slide)
                    ],
                    "label": [
                        VisualBehaviorStep(type: .tint, fromValue: 0.5, toValue: 1.0)
                    ]
                ]
            ),
            platformAdaptations: [
                PlatformAdaptation(platform: .iOS, enabled: true),
                PlatformAdaptation(platform: .macOS, enabled: true)
            ]
        )
    }
    
    private static func createWizardStepCompletePulseSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "wizardStepCompletePulse",
            duration: 0.22,
            easing: .easeOutBack,
            size: .element,
            description: "Step header pulses when validated",
            visualBehavior: [
                "stepHeader": [
                    VisualBehaviorStep(type: .glow, duration: 0.15, intensity: 0.5)
                ],
                "checkmark": [
                    VisualBehaviorStep(type: .scale, fromValue: 0, toValue: 1.2, at: 0.0),
                    VisualBehaviorStep(type: .scale, fromValue: 1.2, toValue: 1.0, at: 0.15)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "stepHeader": [
                        VisualBehaviorStep(type: .highlight, duration: 0.15, color: "accent")
                    ],
                    "checkmark": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.15)
                    ]
                ]
            )
        )
    }
    
    // MARK: Stage 5: Workspace Reveal
    
    private static func createWorkspaceRevealSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "workspaceRevealFromOnboarding",
            duration: 0.6,
            easing: .easeOutQuart,
            size: .fullScreen,
            description: "Wizard collapses, workspace modules orbit in",
            visualBehavior: [
                "wizardCard": [
                    VisualBehaviorStep(type: .scale, fromValue: 1.0, toValue: 0.95),
                    VisualBehaviorStep(type: .opacity, fromValue: 1, toValue: 0)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "wizardCard": [
                        VisualBehaviorStep(type: .opacity, fromValue: 1, toValue: 0, duration: 0.2)
                    ],
                    "workspace": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.3)
                    ]
                ]
            )
        )
    }
    
    private static func createFirstRunTipsOverlaySpec() -> AnimationSpec {
        return AnimationSpec(
            name: "firstRunTipsOverlay",
            duration: 0.3,
            easing: .easeOutCubic,
            size: .element,
            description: "Optional tooltips for core areas",
            visualBehavior: [
                "tooltip": [
                    VisualBehaviorStep(type: .fadeIn, duration: 0.3),
                    VisualBehaviorStep(type: .slide, distance: 8)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "tooltip": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            ),
            stagger: 0.2
        )
    }
    
    private static func createKeyboardOnboardingHintSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "keyboardOnboardingHint",
            duration: 0.25,
            easing: .easeOutCubic,
            size: .element,
            description: "Floating hint pill for keyboard shortcuts",
            visualBehavior: [
                "hintPill": [
                    VisualBehaviorStep(type: .slide, distance: 20, direction: "bottomRight"),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "hintPill": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            ),
            platformAdaptations: [
                PlatformAdaptation(platform: .macOS, enabled: true),
                PlatformAdaptation(platform: .iOS, enabled: false),
                PlatformAdaptation(platform: .iPad, enabled: true, condition: "keyboardConnected")
            ]
        )
    }
    
    // MARK: Additional Stage 1 Specs
    
    private static func createBackgroundFadeSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "backgroundFade",
            duration: 0.7,
            easing: .easeInOutQuad,
            size: .fullScreen,
            description: "Background fades from black to gradient",
            visualBehavior: [
                "background": [
                    VisualBehaviorStep(type: .fade, fromValue: 0, toValue: 1, duration: 0.7)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "background": [
                        VisualBehaviorStep(type: .instant)
                    ]
                ]
            )
        )
    }
    
    private static func createIconToHeaderSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "iconToHeader",
            duration: 0.5,
            easing: .easeInOutCubic,
            size: .element,
            description: "Icon transitions to header position",
            visualBehavior: [
                "icon": [
                    VisualBehaviorStep(type: .translateY, fromValue: 0, toValue: -200),
                    VisualBehaviorStep(type: .scale, fromValue: 1.0, toValue: 0.5)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "icon": [
                        VisualBehaviorStep(type: .opacity, fromValue: 1, toValue: 0, duration: 0.2)
                    ]
                ]
            )
        )
    }
    
    private static func createCanvasFadeInSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "canvasFadeIn",
            duration: 0.4,
            easing: .easeOut,
            size: .fullScreen,
            description: "Onboarding canvas fades in",
            visualBehavior: [
                "canvas": [
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "canvas": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            )
        )
    }
    
    // MARK: Additional Stage 5 Specs
    
    private static func createModuleOrbitSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "moduleOrbit",
            duration: 1.2,
            easing: .easeInOutQuad,
            size: .region,
            description: "Modules orbit into position",
            visualBehavior: [
                "module": [
                    VisualBehaviorStep(type: .orbit, duration: 1.2),
                    VisualBehaviorStep(type: .fadeIn, duration: 0.3)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "module": [
                        VisualBehaviorStep(type: .fadeIn, duration: 0.3)
                    ]
                ]
            )
        )
    }
    
    private static func createSidebarSlideInSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "sidebarSlideIn",
            duration: 0.5,
            easing: .easeOutCubic,
            size: .region,
            description: "Sidebar slides in from left",
            visualBehavior: [
                "sidebar": [
                    VisualBehaviorStep(type: .translateX, fromValue: -300, toValue: 0),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "sidebar": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            )
        )
    }
    
    private static func createInspectorSlideInSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "inspectorSlideIn",
            duration: 0.5,
            easing: .easeOutCubic,
            size: .region,
            description: "Inspector slides in from right",
            visualBehavior: [
                "inspector": [
                    VisualBehaviorStep(type: .translateX, fromValue: 300, toValue: 0),
                    VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "inspector": [
                        VisualBehaviorStep(type: .opacity, fromValue: 0, toValue: 1, duration: 0.2)
                    ]
                ]
            )
        )
    }
    
    private static func createEditorFocusSpec() -> AnimationSpec {
        return AnimationSpec(
            name: "editorFocus",
            duration: 0.4,
            easing: .easeOut,
            size: .region,
            description: "Editor area receives focus effect",
            visualBehavior: [
                "editor": [
                    VisualBehaviorStep(type: .glow, duration: 0.4, intensity: 0.3),
                    VisualBehaviorStep(type: .highlight, duration: 0.2)
                ]
            ],
            reduceMotionBehavior: ReduceMotionBehavior(
                replacementSteps: [
                    "editor": [
                        VisualBehaviorStep(type: .highlight, duration: 0.2)
                    ]
                ]
            )
        )
    }
}
