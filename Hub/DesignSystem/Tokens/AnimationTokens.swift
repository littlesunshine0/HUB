//
//  AnimationTokens.swift
//  Hub
//
//  Comprehensive animation system supporting all major animation types
//  Platform-fluid design for iOS, macOS, watchOS, and tvOS
//

import SwiftUI

// MARK: - Animation Tokens

public struct AnimationTokens {
    
    // MARK: - Timing Curves
    
    public static let easeIn = Animation.easeIn(duration: 0.3)
    public static let easeOut = Animation.easeOut(duration: 0.3)
    public static let easeInOut = Animation.easeInOut(duration: 0.3)
    public static let linear = Animation.linear(duration: 0.3)
    public static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    public static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    public static let springSmooth = Animation.spring(response: 0.3, dampingFraction: 0.8)
    
    // MARK: - Duration Tokens
    
    public static let instant: TimeInterval = 0.1
    public static let fast: TimeInterval = 0.2
    public static let normal: TimeInterval = 0.3
    public static let moderate: TimeInterval = 0.5
    public static let slow: TimeInterval = 0.8
    public static let verySlow: TimeInterval = 1.2
    
    // MARK: - Entrance Animations
    
    public enum EntranceAnimation {
        case fadeIn
        case slideInFromLeft
        case slideInFromRight
        case slideInFromTop
        case slideInFromBottom
        case scaleIn
        case rotateIn
        case bounceIn
        case expandIn
        
        public var animation: Animation {
            switch self {
            case .fadeIn, .slideInFromLeft, .slideInFromRight, .slideInFromTop, .slideInFromBottom:
                return .easeOut(duration: AnimationTokens.normal)
            case .scaleIn, .expandIn:
                return .spring(response: 0.4, dampingFraction: 0.7)
            case .rotateIn:
                return .easeInOut(duration: AnimationTokens.moderate)
            case .bounceIn:
                return .spring(response: 0.5, dampingFraction: 0.6)
            }
        }
    }
    
    // MARK: - Hover Animations
    
    public enum HoverAnimation {
        case lift
        case scale
        case glow
        case tilt
        case pulse
        case shimmer
        
        public var animation: Animation {
            switch self {
            case .lift, .scale, .tilt:
                return .spring(response: 0.3, dampingFraction: 0.7)
            case .glow:
                return .easeInOut(duration: 0.2)
            case .pulse:
                return .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
            case .shimmer:
                return .linear(duration: 1.5).repeatForever(autoreverses: false)
            }
        }
    }
    
    // MARK: - Loading Animations
    
    public enum LoadingAnimation {
        case spinner
        case dots
        case progressBar
        case skeleton
        case pulse
        case wave
        
        public var animation: Animation {
            switch self {
            case .spinner:
                return .linear(duration: 1.0).repeatForever(autoreverses: false)
            case .dots:
                return .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
            case .progressBar:
                return .linear(duration: 2.0)
            case .skeleton:
                return .linear(duration: 1.5).repeatForever(autoreverses: false)
            case .pulse:
                return .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
            case .wave:
                return .easeInOut(duration: 1.2).repeatForever(autoreverses: false)
            }
        }
    }
    
    // MARK: - Scrolling Animations
    
    public enum ScrollAnimation {
        case parallax(speed: Double)
        case reveal
        case fade
        case scale
        case sticky
        
        public func offset(for scrollOffset: CGFloat, itemPosition: CGFloat) -> CGFloat {
            switch self {
            case .parallax(let speed):
                return (scrollOffset - itemPosition) * CGFloat(speed)
            case .reveal:
                return max(0, scrollOffset - itemPosition)
            default:
                return 0
            }
        }
        
        public func opacity(for scrollOffset: CGFloat, itemPosition: CGFloat, threshold: CGFloat = 200) -> Double {
            switch self {
            case .fade:
                let distance = abs(scrollOffset - itemPosition)
                return max(0, 1 - Double(distance / threshold))
            default:
                return 1.0
            }
        }
    }
    
    // MARK: - Layout Animations
    
    public enum LayoutAnimation {
        case heroTransition
        case morphing
        case cardExpand
        case listReorder
        case gridToList
        case collapse
        
        public var animation: Animation {
            switch self {
            case .heroTransition:
                return .spring(response: 0.5, dampingFraction: 0.8)
            case .morphing:
                return .easeInOut(duration: 0.4)
            case .cardExpand:
                return .spring(response: 0.4, dampingFraction: 0.75)
            case .listReorder:
                return .spring(response: 0.3, dampingFraction: 0.8)
            case .gridToList:
                return .easeInOut(duration: 0.35)
            case .collapse:
                return .easeOut(duration: 0.25)
            }
        }
    }
    
    // MARK: - Motion Graphics
    
    public enum MotionGraphic {
        case logoReveal
        case textAppear
        case shapeTransform
        case pathAnimation
        case counterAnimation
        
        public var animation: Animation {
            switch self {
            case .logoReveal:
                return .easeOut(duration: 1.0)
            case .textAppear:
                return .spring(response: 0.6, dampingFraction: 0.8)
            case .shapeTransform:
                return .easeInOut(duration: 0.8)
            case .pathAnimation:
                return .easeInOut(duration: 1.2)
            case .counterAnimation:
                return .easeOut(duration: 0.5)
            }
        }
    }
    
    // MARK: - Accent Animations
    
    public enum AccentAnimation {
        case confetti
        case sparkle
        case ripple
        case particle
        case trail
        
        public var animation: Animation {
            switch self {
            case .confetti:
                return .easeOut(duration: 1.5)
            case .sparkle:
                return .easeInOut(duration: 0.8).repeatCount(3, autoreverses: true)
            case .ripple:
                return .easeOut(duration: 0.6)
            case .particle:
                return .linear(duration: 2.0)
            case .trail:
                return .easeOut(duration: 0.4)
            }
        }
    }
    
    // MARK: - Pixel Transition
    
    public enum PixelTransition {
        case dissolve
        case assemble
        case scatter
        case wave
        
        public var animation: Animation {
            switch self {
            case .dissolve:
                return .easeIn(duration: 0.6)
            case .assemble:
                return .spring(response: 0.8, dampingFraction: 0.7)
            case .scatter:
                return .easeOut(duration: 0.8)
            case .wave:
                return .easeInOut(duration: 1.0)
            }
        }
    }
}

// MARK: - View Modifiers for Animations

public extension View {
    
    // MARK: - Entrance Animations
    
    func entranceAnimation(_ type: AnimationTokens.EntranceAnimation, isPresented: Bool, delay: Double = 0) -> some View {
        modifier(EntranceAnimationModifier(type: type, isPresented: isPresented, delay: delay))
    }
    
    // MARK: - Hover Animations
    
    func hoverAnimation(_ type: AnimationTokens.HoverAnimation, isHovered: Bool) -> some View {
        modifier(HoverAnimationModifier(type: type, isHovered: isHovered))
    }
    
    // MARK: - Loading Animations
    
    func loadingAnimation(_ type: AnimationTokens.LoadingAnimation, isLoading: Bool) -> some View {
        modifier(LoadingAnimationModifier(type: type, isLoading: isLoading))
    }
    
    // MARK: - Parallax Effect
    
    func parallaxEffect(scrollOffset: CGFloat, speed: Double = 0.5) -> some View {
        self.offset(y: scrollOffset * CGFloat(speed))
    }
    
    // MARK: - Shimmer Effect
    
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
    
    // MARK: - Pulse Effect
    
    func pulse(isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }
    
    // MARK: - Skeleton Loading
    
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }
}

// MARK: - Animation Modifiers

struct EntranceAnimationModifier: ViewModifier {
    let type: AnimationTokens.EntranceAnimation
    let isPresented: Bool
    let delay: Double
    
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(x: offsetX, y: offsetY)
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .onAppear {
                withAnimation(type.animation.delay(delay)) {
                    appeared = true
                }
            }
            .onChange(of: isPresented) { _, newValue in
                withAnimation(type.animation) {
                    appeared = newValue
                }
            }
    }
    
    private var opacity: Double {
        switch type {
        case .fadeIn:
            return appeared ? 1 : 0
        default:
            return appeared ? 1 : 0
        }
    }
    
    private var offsetX: CGFloat {
        switch type {
        case .slideInFromLeft:
            return appeared ? 0 : -50
        case .slideInFromRight:
            return appeared ? 0 : 50
        default:
            return 0
        }
    }
    
    private var offsetY: CGFloat {
        switch type {
        case .slideInFromTop:
            return appeared ? 0 : -50
        case .slideInFromBottom:
            return appeared ? 0 : 50
        default:
            return 0
        }
    }
    
    private var scale: CGFloat {
        switch type {
        case .scaleIn, .bounceIn, .expandIn:
            return appeared ? 1 : 0.5
        default:
            return 1
        }
    }
    
    private var rotation: Angle {
        switch type {
        case .rotateIn:
            return appeared ? .degrees(0) : .degrees(-90)
        default:
            return .degrees(0)
        }
    }
}

struct HoverAnimationModifier: ViewModifier {
    let type: AnimationTokens.HoverAnimation
    let isHovered: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(y: offsetY)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .rotation3DEffect(rotation, axis: (x: rotationX, y: rotationY, z: 0))
            .animation(type.animation, value: isHovered)
    }
    
    private var scale: CGFloat {
        switch type {
        case .scale:
            return isHovered ? 1.05 : 1.0
        default:
            return 1.0
        }
    }
    
    private var offsetY: CGFloat {
        switch type {
        case .lift:
            return isHovered ? -4 : 0
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        switch type {
        case .lift, .glow:
            return isHovered ? Color.black.opacity(0.2) : Color.clear
        default:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch type {
        case .lift:
            return isHovered ? 12 : 0
        case .glow:
            return isHovered ? 20 : 0
        default:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch type {
        case .lift:
            return isHovered ? 8 : 0
        default:
            return 0
        }
    }
    
    private var rotation: Angle {
        switch type {
        case .tilt:
            return isHovered ? .degrees(2) : .degrees(0)
        default:
            return .degrees(0)
        }
    }
    
    private var rotationX: CGFloat {
        switch type {
        case .tilt:
            return 1
        default:
            return 0
        }
    }
    
    private var rotationY: CGFloat {
        switch type {
        case .tilt:
            return 0.5
        default:
            return 0
        }
    }
}

struct LoadingAnimationModifier: ViewModifier {
    let type: AnimationTokens.LoadingAnimation
    let isLoading: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                if isLoading {
                    startAnimation()
                }
            }
            .onChange(of: isLoading) { _, newValue in
                if newValue {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
    }
    
    private func startAnimation() {
        switch type {
        case .spinner:
            withAnimation(type.animation) {
                rotation = 360
            }
        case .pulse:
            withAnimation(type.animation) {
                scale = 1.1
            }
        default:
            break
        }
    }
    
    private func stopAnimation() {
        rotation = 0
        scale = 1.0
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                        .onAppear {
                            withAnimation(AnimationTokens.HoverAnimation.shimmer.animation) {
                                phase = 1
                            }
                        }
                    }
                }
            )
            .clipped()
    }
}

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if isActive {
                    withAnimation(AnimationTokens.HoverAnimation.pulse.animation) {
                        scale = 1.05
                    }
                }
            }
    }
}

struct SkeletonModifier: ViewModifier {
    let isLoading: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(isLoading ? 0.3 : 1)
            .overlay(
                Group {
                    if isLoading {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.5),
                                        Color.gray.opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: phase * 200)
                            .onAppear {
                                withAnimation(AnimationTokens.LoadingAnimation.skeleton.animation) {
                                    phase = 1
                                }
                            }
                    }
                }
            )
    }
}
