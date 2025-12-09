import SwiftUI
import Combine
/// Hub app icon as a SwiftUI view
/// Connection motif (network of nodes and links) inside a gradient hexagon
/// Can be used in UI, not the actual app icon file
public struct HubIconView: View {
    public var size: CGFloat = 100
    public var showMonogram: Bool = true
    
    public init(size: CGFloat = 100, showMonogram: Bool = true) {
        self.size = size
        self.showMonogram = showMonogram
    }
    
    public var body: some View {
        ZStack {
            // Hexagon shape with gradient
            HexagonShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "5AC8FA"), // Light Blue
                            Color(hex: "0A84FF"), // macOS Blue
                            Color(hex: "004999")  // Dark Blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(
                    color: .black.opacity(0.3),
                    radius: size * 0.08,
                    x: 0,
                    y: size * 0.04
                )
            
            // Connection glyph (network of nodes)
            HubGlyphWhite(size: size)
        }
    }
}

/// Network/connection glyph (monochrome white)
public struct HubGlyphWhite: View {
    let size: CGFloat

    // Node positions as fractions of the available rect
    private var nodes: [CGPoint] {
        [
            CGPoint(x: 0.20, y: 0.30),
            CGPoint(x: 0.80, y: 0.28),
            CGPoint(x: 0.72, y: 0.70),
            CGPoint(x: 0.30, y: 0.75),
            CGPoint(x: 0.50, y: 0.50)
        ]
    }

    // Links between node indices
    private let links: [(Int, Int)] = [
        (0, 4), (1, 4), (2, 4), (3, 4),
        (0, 1), (1, 2), (2, 3), (3, 0)
    ]

    public init(size: CGFloat) { self.size = size }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let strokeWidth = max(2, min(w, h) * 0.05)
            let nodeRadius = max(3, min(w, h) * 0.06)

            ZStack {
                // Links
                ForEach(0..<links.count, id: \.self) { idx in
                    let (a, b) = links[idx]
                    let p1 = CGPoint(x: nodes[a].x * w, y: nodes[a].y * h)
                    let p2 = CGPoint(x: nodes[b].x * w, y: nodes[b].y * h)
                    Path { path in
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(.white.opacity(0.95))
                    .opacity(0.95)
                }

                // Nodes
                ForEach(0..<nodes.count, id: \.self) { i in
                    let p = CGPoint(x: nodes[i].x * w, y: nodes[i].y * h)
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: nodeRadius * 2, height: nodeRadius * 2)
                        .position(p)
                        .opacity(0.95)
                }
            }
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .shadow(color: .black.opacity(0.15), radius: size * 0.04, y: size * 0.02)
    }
}

/// Network/connection glyph (SF Symbol styled gradient)
public struct HubGlyphSymbol: View {
    let size: CGFloat

    public init(size: CGFloat) { self.size = size }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let strokeWidth = max(2, min(w, h) * 0.10)
            let nodeRadius = max(2, min(w, h) * 0.12)

            let nodes: [CGPoint] = [
                CGPoint(x: 0.20 * w, y: 0.30 * h),
                CGPoint(x: 0.80 * w, y: 0.28 * h),
                CGPoint(x: 0.72 * w, y: 0.70 * h),
                CGPoint(x: 0.30 * w, y: 0.75 * h),
                CGPoint(x: 0.50 * w, y: 0.50 * h)
            ]
            let links: [(Int, Int)] = [(0,4),(1,4),(2,4),(3,4),(0,1),(1,2),(2,3),(3,0)]

            let gradient = LinearGradient(
                colors: [
                    Color(hex: "5AC8FA"),
                    Color(hex: "0A84FF"),
                    Color(hex: "004999")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ZStack {
                // Links
                ForEach(0..<links.count, id: \.self) { idx in
                    let (a, b) = links[idx]
                    Path { path in
                        path.move(to: nodes[a])
                        path.addLine(to: nodes[b])
                    }
                    .stroke(gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .opacity(0.95)
                }

                // Nodes
                ForEach(0..<nodes.count, id: \.self) { i in
                    Circle()
                        .fill(gradient)
                        .frame(width: nodeRadius * 2, height: nodeRadius * 2)
                        .position(nodes[i])
                        .shadow(color: .black.opacity(0.15), radius: nodeRadius * 0.5, y: nodeRadius * 0.25)
                }
            }
            .padding(size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

/// Hexagon shape for the Hub icon
public struct HexagonShape: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let radius = min(width, height) / 2
        
        // Draw hexagon with 6 points
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2 // Start from top
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

/// Alternative: Simple SF Symbol based icon
public struct HubIconSymbol: View {
    public var size: CGFloat = 100
    
    public init(size: CGFloat = 100) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Hexagon outline matching the icon shape
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "5AC8FA"),
                            Color(hex: "0A84FF"),
                            Color(hex: "004999")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(2, size * 0.10)
                )
                .frame(width: size, height: size)
            
            HubGlyphSymbol(size: size)
        }
        .frame(width: size, height: size)
    }
}

/// Alternative: 3D Cube icon
public struct HubIconCube: View {
    public var size: CGFloat = 100
    
    public init(size: CGFloat = 100) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Top face
            Path { path in
                path.move(to: CGPoint(x: size * 0.5, y: size * 0.2))
                path.addLine(to: CGPoint(x: size * 0.8, y: size * 0.35))
                path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.35))
                path.closeSubpath()
            }
            .fill(Color(hex: "5AC8FA"))
            
            // Left face
            Path { path in
                path.move(to: CGPoint(x: size * 0.2, y: size * 0.35))
                path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.8))
                path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.65))
                path.closeSubpath()
            }
            .fill(Color(hex: "0A84FF"))
            
            // Right face
            Path { path in
                path.move(to: CGPoint(x: size * 0.5, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.8, y: size * 0.35))
                path.addLine(to: CGPoint(x: size * 0.8, y: size * 0.65))
                path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.8))
                path.closeSubpath()
            }
            .fill(Color(hex: "004999"))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: size * 0.08, y: size * 0.04)
    }
}

// MARK: - Preview

#Preview("Hexagon Icon") {
    VStack(spacing: 32) {
        HubIconView(size: 200, showMonogram: true)
        HubIconView(size: 128, showMonogram: true)
        HubIconView(size: 64, showMonogram: false)
        HubIconView(size: 32, showMonogram: false)
    }
    .padding()
}

#Preview("SF Symbol Icon") {
    VStack(spacing: 32) {
        HubIconSymbol(size: 200)
        HubIconSymbol(size: 128)
        HubIconSymbol(size: 64)
        HubIconSymbol(size: 32)
    }
    .padding()
}

#Preview("Cube Icon") {
    VStack(spacing: 32) {
        HubIconCube(size: 200)
        HubIconCube(size: 128)
        HubIconCube(size: 64)
        HubIconCube(size: 32)
    }
    .padding()
}

#Preview("All Variants") {
    HStack(spacing: 32) {
        VStack {
            HubIconView(size: 100)
            Text("Hexagon")
                .font(.caption)
        }
        
        VStack {
            HubIconSymbol(size: 100)
            Text("SF Symbol")
                .font(.caption)
        }
        
        VStack {
            HubIconCube(size: 100)
            Text("3D Cube")
                .font(.caption)
        }
    }
    .padding()
}

#Preview("Glyphs Separated") {
    HStack(spacing: 40) {
        VStack {
            HubGlyphWhite(size: 120)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text("White Glyph").font(.caption)
        }
        VStack {
            HubGlyphSymbol(size: 120)
            Text("SF Symbol Glyph").font(.caption)
        }
    }
    .padding()
}

