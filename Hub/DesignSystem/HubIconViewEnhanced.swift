import SwiftUI
import Combine

// MARK: - Enhanced Hub Icon with Pro Visual Effects

/// Enhanced Hub Icon with glass effects, depth, and modern visual treatments
public struct EnhancedHubIconView: View {
    public var size: CGFloat = 100
    public var showMonogram: Bool = true
    @State private var isAnimating = false
    
    public init(size: CGFloat = 100, showMonogram: Bool = true) {
        self.size = size
        self.showMonogram = showMonogram
    }
    
    public var body: some View {
        ZStack {
            // Layered Glass Hexagon with Angular Gradient
            HexagonShape()
                .fill(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "5AC8FA"), location: 0.0),
                            .init(color: Color(hex: "0A84FF"), location: 0.35),
                            .init(color: Color(hex: "004999"), location: 0.7),
                            .init(color: Color(hex: "5AC8FA"), location: 1.0)
                        ]),
                        center: .center
                    )
                )
                .frame(width: size, height: size)
                // Multi-layer shadow for depth
                .shadow(color: .black.opacity(0.20), radius: size * 0.06, y: size * 0.03)
                .shadow(color: Color(hex: "0A84FF").opacity(0.4), radius: size * 0.12, y: size * 0.06)
                .overlay(
                    // Glass highlight - simulated light reflection
                    HexagonShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size * 0.07
                        )
                        .blur(radius: size * 0.07)
                )
                .overlay(
                    // Diagonal light sweep
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.25, height: size * 0.8)
                        .rotationEffect(.degrees(-25))
                        .offset(x: -size * 0.15, y: -size * 0.05)
                        .blur(radius: size * 0.05)
                        .clipShape(HexagonShape())
                )
            
            // Enhanced glyph with node glows
            EnhancedHubGlyph(size: size * 0.77, isAnimating: isAnimating)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

/// Enhanced glyph with backlit node glows and liquid highlights
struct EnhancedHubGlyph: View {
    let size: CGFloat
    let isAnimating: Bool
    
    private var nodes: [CGPoint] {
        [
            CGPoint(x: 0.20, y: 0.30),
            CGPoint(x: 0.80, y: 0.28),
            CGPoint(x: 0.72, y: 0.70),
            CGPoint(x: 0.30, y: 0.75),
            CGPoint(x: 0.50, y: 0.50)
        ]
    }
    
    private let links: [(Int, Int)] = [
        (0, 4), (1, 4), (2, 4), (3, 4),
        (0, 1), (1, 2), (2, 3), (3, 0)
    ]
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let strokeWidth = max(2, min(w, h) * 0.05)
            let nodeRadius = max(3, min(w, h) * 0.06)
            
            ZStack {
                // Backlit node glows (activated network effect)
                ForEach(0..<nodes.count, id: \.self) { i in
                    let p = CGPoint(x: nodes[i].x * w, y: nodes[i].y * h)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(isAnimating ? 0.45 : 0.35),
                                    Color.cyan.opacity(0.15),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: nodeRadius * 3.5
                            )
                        )
                        .frame(width: nodeRadius * 7, height: nodeRadius * 7)
                        .position(p)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                // Links with duotone effect
                ForEach(0..<links.count, id: \.self) { idx in
                    let (a, b) = links[idx]
                    let p1 = CGPoint(x: nodes[a].x * w, y: nodes[a].y * h)
                    let p2 = CGPoint(x: nodes[b].x * w, y: nodes[b].y * h)
                    
                    // Base link
                    Path { path in
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(
                        style: StrokeStyle(
                            lineWidth: strokeWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .foregroundStyle(.white.opacity(0.95))
                    
                    // Highlight overlay for depth
                    Path { path in
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: strokeWidth * 0.5,
                            lineCap: .round
                        )
                    )
                }
                
                // Nodes with liquid glass highlights
                ForEach(0..<nodes.count, id: \.self) { i in
                    let p = CGPoint(x: nodes[i].x * w, y: nodes[i].y * h)
                    ZStack {
                        // Base node
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: nodeRadius * 2, height: nodeRadius * 2)
                        
                        // Liquid highlight (droplet effect)
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: nodeRadius * 1.2
                                )
                            )
                            .frame(width: nodeRadius * 1.6, height: nodeRadius * 1.6)
                            .offset(x: -nodeRadius * 0.25, y: -nodeRadius * 0.25)
                            .blur(radius: nodeRadius * 0.15)
                        
                        // Inner glow
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            .frame(width: nodeRadius * 1.4, height: nodeRadius * 1.4)
                            .blur(radius: 1)
                    }
                    .position(p)
                }
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.15), radius: size * 0.04, y: size * 0.02)
    }
}

// MARK: - Animated Variants

/// Hub Icon with pulsing glow animation
public struct AnimatedHubIconView: View {
    public var size: CGFloat = 100
    @State private var glowIntensity: CGFloat = 0.3
    
    public init(size: CGFloat = 100) {
        self.size = size
    }
    
    public var body: some View {
        EnhancedHubIconView(size: size)
            .shadow(
                color: Color(hex: "0A84FF").opacity(glowIntensity),
                radius: size * 0.2,
                y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
    }
}

/// Hub Icon with rotation animation
public struct RotatingHubIconView: View {
    public var size: CGFloat = 100
    @State private var rotation: Double = 0
    
    public init(size: CGFloat = 100) {
        self.size = size
    }
    
    public var body: some View {
        EnhancedHubIconView(size: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - State Variants

/// Hub Icon with success state (green glow)
public struct SuccessHubIconView: View {
    public var size: CGFloat = 100
    @State private var showSuccess = false
    
    public init(size: CGFloat = 100) {
        self.size = size
    }
    
    public var body: some View {
        EnhancedHubIconView(size: size)
            .overlay(
                HexagonShape()
                    .stroke(Color.green, lineWidth: size * 0.05)
                    .blur(radius: size * 0.08)
                    .opacity(showSuccess ? 1 : 0)
            )
            .shadow(
                color: Color.green.opacity(showSuccess ? 0.6 : 0),
                radius: size * 0.15,
                y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSuccess = true
                }
            }
    }
}

/// Hub Icon with active/selected state (blue glow)
public struct ActiveHubIconView: View {
    public var size: CGFloat = 100
    public var isActive: Bool
    
    public init(size: CGFloat = 100, isActive: Bool = true) {
        self.size = size
        self.isActive = isActive
    }
    
    public var body: some View {
        EnhancedHubIconView(size: size)
            .overlay(
                HexagonShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.04
                    )
                    .blur(radius: size * 0.06)
                    .opacity(isActive ? 1 : 0)
            )
            .shadow(
                color: Color.blue.opacity(isActive ? 0.7 : 0),
                radius: size * 0.18,
                y: 0
            )
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

// MARK: - Previews

#Preview("Enhanced Icon") {
    VStack(spacing: 32) {
        EnhancedHubIconView(size: 200)
        EnhancedHubIconView(size: 128)
        EnhancedHubIconView(size: 64)
        EnhancedHubIconView(size: 32)
    }
    .padding()
    .background(Color.black.opacity(0.05))
}

#Preview("Animated Variants") {
    HStack(spacing: 40) {
        VStack {
            AnimatedHubIconView(size: 120)
            Text("Pulsing Glow")
                .font(.caption)
        }
        
        VStack {
            RotatingHubIconView(size: 120)
            Text("Rotating")
                .font(.caption)
        }
    }
    .padding()
}

#Preview("State Variants") {
    HStack(spacing: 40) {
        VStack {
            EnhancedHubIconView(size: 100)
            Text("Default")
                .font(.caption)
        }
        
        VStack {
            ActiveHubIconView(size: 100, isActive: true)
            Text("Active")
                .font(.caption)
        }
        
        VStack {
            SuccessHubIconView(size: 100)
            Text("Success")
                .font(.caption)
        }
    }
    .padding()
}

#Preview("Size Comparison") {
    VStack(spacing: 24) {
        HStack(spacing: 40) {
            VStack {
                HubIconView(size: 100)
                Text("Original")
                    .font(.caption)
            }
            
            VStack {
                EnhancedHubIconView(size: 100)
                Text("Enhanced")
                    .font(.caption)
            }
        }
        
        Divider()
        
        HStack(spacing: 40) {
            VStack {
                HubIconView(size: 64)
                Text("Original 64px")
                    .font(.caption2)
            }
            
            VStack {
                EnhancedHubIconView(size: 64)
                Text("Enhanced 64px")
                    .font(.caption2)
            }
        }
    }
    .padding()
}

#Preview("Dark Background") {
    VStack(spacing: 32) {
        EnhancedHubIconView(size: 150)
        AnimatedHubIconView(size: 150)
        ActiveHubIconView(size: 150, isActive: true)
    }
    .padding(40)
    .background(Color.black)
}

#Preview("Light Background") {
    VStack(spacing: 32) {
        EnhancedHubIconView(size: 150)
        AnimatedHubIconView(size: 150)
        ActiveHubIconView(size: 150, isActive: true)
    }
    .padding(40)
    .background(Color.white)
}
