//
//  BuddyTheDogView.swift
//  Hub
//
//  Enhanced with Core Animation for smoother, hardware-accelerated animations
//

import SwiftUI
import Combine
import QuartzCore

// MARK: - Buddy's Design Tokens
private enum BuddyColor {
    static let primaryOrange = Color(hex: "#FF9500")
    static let furGold = Color(hex: "#FFD60A")
    static let darkBrown = Color(hex: "#6D4C41")
    static let paperWhite = Color(hex: "#F5F5F5")
    static let paperLines = Color.gray.opacity(0.3)
    
    // CGColor versions for Core Animation
    static let primaryOrangeCG = NSColor(Color(hex: "#FF9500")).cgColor
    static let furGoldCG = NSColor(Color(hex: "#FFD60A")).cgColor
    static let darkBrownCG = NSColor(Color(hex: "#6D4C41")).cgColor
}

// MARK: - Animation State Controller
enum BuddyAnimationState: Equatable {
    case idle
    case organizing
    case alert
    case success
}

// MARK: - Enhanced Buddy View with Core Animation
struct BuddyTheDogView: View {
    @Binding var state: BuddyAnimationState
    
    var body: some View {
        #if os(macOS)
        BuddyAnimatedLayer_macOS(state: $state)
            .frame(height: 350)
        #else
        BuddyAnimatedLayer_iOS(state: $state)
            .frame(height: 350)
        #endif
    }
}

// MARK: - Core Animation Layer Wrapper (macOS)
#if os(macOS)
private struct BuddyAnimatedLayer_macOS: NSViewRepresentable {
    @Binding var state: BuddyAnimationState
    
    func makeNSView(context: Context) -> BuddyContainerView {
        let view = BuddyContainerView()
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        return view
    }
    
    func updateNSView(_ nsView: BuddyContainerView, context: Context) {
        nsView.updateAnimation(for: state)
    }
}
#endif

// MARK: - Core Animation Layer Wrapper (iOS)
#if os(iOS) || os(visionOS)
private struct BuddyAnimatedLayer_iOS: UIViewRepresentable {
    @Binding var state: BuddyAnimationState
    
    func makeUIView(context: Context) -> BuddyContainerView_iOS {
        let view = BuddyContainerView_iOS()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: BuddyContainerView_iOS, context: Context) {
        uiView.updateAnimation(for: state)
    }
}
#endif

// MARK: - Container View for Core Animation Layers (macOS)
#if os(macOS)
private class BuddyContainerView: NSView {
    private var buddyLayer: BuddyDogLayer?
    private var emitterLayer: CAEmitterLayer?
    private var didSetupLayers = false
    
    // Flip coordinate system so Y increases upward (standard for drawing)
    override var isFlipped: Bool { return true }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Don't setup layers here - wait for non-zero bounds in layout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Don't setup layers here - wait for non-zero bounds in layout()
    }
    
    private func setupLayers() {
        guard let layer = self.layer else { return }
        guard buddyLayer == nil else { return } // Already setup
        
        // Create Buddy dog layer
        let buddy = BuddyDogLayer()
        buddy.frame = CGRect(x: 0, y: 0, width: 400, height: 350)
        buddy.position = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.addSublayer(buddy)
        self.buddyLayer = buddy
        
        // Create emitter layer for receipts
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = CGSize(width: 50, height: 50)
        emitter.renderMode = .additive
        layer.addSublayer(emitter)
        self.emitterLayer = emitter
        
        didSetupLayers = true
    }
    
    override func layout() {
        super.layout()
        
        // Setup layers on first layout pass when we have non-zero bounds
        if !didSetupLayers && bounds.size != .zero {
            setupLayers()
        }
        
        // Update positions
        buddyLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer?.frame = bounds
        emitterLayer?.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func updateAnimation(for state: BuddyAnimationState) {
        buddyLayer?.animate(to: state)
        
        // Handle receipt particles for organizing state
        if state == .organizing {
            startReceiptEmitter()
        } else {
            stopReceiptEmitter()
        }
    }
    
    private func startReceiptEmitter() {
        guard let emitter = emitterLayer else { return }
        
        let cell = CAEmitterCell()
        cell.contents = createReceiptImage()
        cell.birthRate = 10
        cell.lifetime = 2.0
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2
        cell.spin = 2
        cell.spinRange = 4
        cell.scale = 0.3
        cell.scaleRange = 0.1
        cell.alphaSpeed = -0.5
        
        emitter.emitterCells = [cell]
    }
    
    private func stopReceiptEmitter() {
        emitterLayer?.emitterCells = nil
    }
    
    private func createReceiptImage() -> CGImage? {
        let size = CGSize(width: 80, height: 120)
        let renderer = NSGraphicsImageRenderer(size: size)
        
        let image = renderer.image { ctx in
            // Draw receipt
            NSColor.white.setFill()
            let rect = CGRect(origin: .zero, size: size)
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            
            // Draw lines
            NSColor.gray.withAlphaComponent(0.3).setFill()
            for i in 0..<6 {
                let lineRect = CGRect(x: 10, y: 10 + CGFloat(i) * 15, 
                                     width: CGFloat.random(in: 40...60), height: 4)
                NSBezierPath(roundedRect: lineRect, xRadius: 2, yRadius: 2).fill()
            }
        }
        
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
#endif

// MARK: - Container View for Core Animation Layers (iOS)
#if os(iOS) || os(visionOS)
private class BuddyContainerView_iOS: UIView {
    private var buddyLayer: BuddyDogLayer?
    private var emitterLayer: CAEmitterLayer?
    private var didSetupLayers = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Don't setup layers here - wait for non-zero bounds in layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Don't setup layers here - wait for non-zero bounds in layoutSubviews()
    }
    
    private func setupLayers() {
        guard buddyLayer == nil else { return } // Already setup
        
        // Create Buddy dog layer
        let buddy = BuddyDogLayer()
        buddy.frame = CGRect(x: 0, y: 0, width: 400, height: 350)
        buddy.position = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.addSublayer(buddy)
        self.buddyLayer = buddy
        
        // Create emitter layer for receipts
        let emitter = CAEmitterLayer()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = CGSize(width: 50, height: 50)
        emitter.renderMode = .additive
        layer.addSublayer(emitter)
        self.emitterLayer = emitter
        
        didSetupLayers = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Setup layers on first layout pass when we have non-zero bounds
        if !didSetupLayers && bounds.size != .zero {
            setupLayers()
        }
        
        // Update positions
        buddyLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer?.frame = bounds
        emitterLayer?.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    func updateAnimation(for state: BuddyAnimationState) {
        buddyLayer?.animate(to: state)
        
        // Handle receipt particles for organizing state
        if state == .organizing {
            startReceiptEmitter()
        } else {
            stopReceiptEmitter()
        }
    }
    
    private func startReceiptEmitter() {
        guard let emitter = emitterLayer else { return }
        
        let cell = CAEmitterCell()
        cell.contents = createReceiptImage()
        cell.birthRate = 10
        cell.lifetime = 2.0
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2
        cell.spin = 2
        cell.spinRange = 4
        cell.scale = 0.3
        cell.scaleRange = 0.1
        cell.alphaSpeed = -0.5
        
        emitter.emitterCells = [cell]
    }
    
    private func stopReceiptEmitter() {
        emitterLayer?.emitterCells = nil
    }
    
    private func createReceiptImage() -> CGImage? {
        let size = CGSize(width: 80, height: 120)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { ctx in
            // Draw receipt
            UIColor.white.setFill()
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
            
            // Draw lines
            UIColor.gray.withAlphaComponent(0.3).setFill()
            for i in 0..<6 {
                let lineRect = CGRect(x: 10, y: 10 + CGFloat(i) * 15, 
                                     width: CGFloat.random(in: 40...60), height: 4)
                UIBezierPath(roundedRect: lineRect, cornerRadius: 2).fill()
            }
        }
        
        return image.cgImage
    }
}
#endif

// MARK: - Buddy Dog Layer (Core Animation)
private class BuddyDogLayer: CALayer {
    private var tailLayer: CAShapeLayer!
    private var bodyLayer: CAShapeLayer!
    private var tummyPatchLayer: CAShapeLayer!
    private var headLayer: CAShapeLayer!
    private var snoutLayer: CAShapeLayer!
    private var noseLayer: CAShapeLayer!
    private var mouthLayer: CAShapeLayer!
    private var leftEyeLayer: CAShapeLayer!
    private var rightEyeLayer: CAShapeLayer!
    private var leftEyeHighlightLayer: CAShapeLayer!
    private var rightEyeHighlightLayer: CAShapeLayer!
    private var leftEarLayer: CAShapeLayer!
    private var rightEarLayer: CAShapeLayer!
    private var leftPawLayer: CAShapeLayer!
    private var rightPawLayer: CAShapeLayer!
    private var leftPawPadLayer: CAShapeLayer!
    private var rightPawPadLayer: CAShapeLayer!
    private var barkLayer: CAShapeLayer!
    
    override init() {
        super.init()
        setupBodyParts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBodyParts()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    private func setupBodyParts() {
        // Z-order stacking (back to front):
        // 0-9: Background (ears, tail)
        // 10-19: Body parts
        // 20-29: Head
        // 30-39: Face details
        // 40-49: Eyes and highlights
        
        // Ears (behind head) - z: 0-1
        leftEarLayer = createShapeLayer(color: BuddyColor.primaryOrangeCG)
        leftEarLayer.path = createEarPath()
        leftEarLayer.frame = CGRect(x: 115, y: 40, width: 45, height: 80)
        leftEarLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        leftEarLayer.transform = CATransform3DMakeRotation(-0.17, 0, 0, 1) // -10 degrees
        leftEarLayer.zPosition = 0
        addSublayer(leftEarLayer)
        
        rightEarLayer = createShapeLayer(color: BuddyColor.primaryOrangeCG)
        rightEarLayer.path = createEarPath()
        rightEarLayer.frame = CGRect(x: 240, y: 40, width: 45, height: 80)
        rightEarLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        rightEarLayer.transform = CATransform3DMakeRotation(0.17, 0, 0, 1) // +10 degrees
        rightEarLayer.zPosition = 1
        addSublayer(rightEarLayer)
        
        // Tail - z: 5
        tailLayer = createShapeLayer(color: BuddyColor.primaryOrangeCG)
        tailLayer.path = createTailPath()
        tailLayer.frame = CGRect(x: 285, y: 200, width: 80, height: 90)
        tailLayer.anchorPoint = CGPoint(x: 1.0, y: 1.0) // Rotate from base
        tailLayer.transform = CATransform3DMakeRotation(0.1, 0, 0, 1) // Slight upward angle
        tailLayer.zPosition = 5
        addSublayer(tailLayer)
        
        // Body - z: 10
        bodyLayer = createShapeLayer(color: BuddyColor.primaryOrangeCG)
        bodyLayer.path = createBodyPath()
        bodyLayer.frame = CGRect(x: 100, y: 170, width: 200, height: 120)
        bodyLayer.zPosition = 10
        addSublayer(bodyLayer)
        
        // Tummy patch - z: 11
        tummyPatchLayer = createShapeLayer(color: BuddyColor.furGoldCG)
        tummyPatchLayer.path = createTummyPatchPath()
        tummyPatchLayer.frame = CGRect(x: 140, y: 200, width: 120, height: 70)
        tummyPatchLayer.opacity = 0.8
        tummyPatchLayer.zPosition = 11
        addSublayer(tummyPatchLayer)
        
        // Paws - z: 12-13
        leftPawLayer = createShapeLayer(color: BuddyColor.furGoldCG)
        leftPawLayer.path = createPawPath()
        leftPawLayer.frame = CGRect(x: 130, y: 260, width: 40, height: 70)
        leftPawLayer.zPosition = 12
        addSublayer(leftPawLayer)
        
        rightPawLayer = createShapeLayer(color: BuddyColor.furGoldCG)
        rightPawLayer.path = createPawPath()
        rightPawLayer.frame = CGRect(x: 230, y: 260, width: 40, height: 70)
        rightPawLayer.zPosition = 13
        addSublayer(rightPawLayer)
        
        // Paw pads - z: 14-15
        leftPawPadLayer = createShapeLayer(color: BuddyColor.darkBrownCG)
        leftPawPadLayer.path = createPawPadPath()
        leftPawPadLayer.frame = CGRect(x: 135, y: 310, width: 30, height: 15)
        leftPawPadLayer.opacity = 0.6
        leftPawPadLayer.zPosition = 14
        addSublayer(leftPawPadLayer)
        
        rightPawPadLayer = createShapeLayer(color: BuddyColor.darkBrownCG)
        rightPawPadLayer.path = createPawPadPath()
        rightPawPadLayer.frame = CGRect(x: 235, y: 310, width: 30, height: 15)
        rightPawPadLayer.opacity = 0.6
        rightPawPadLayer.zPosition = 15
        addSublayer(rightPawPadLayer)
        
        // Head - z: 20
        headLayer = createShapeLayer(color: BuddyColor.primaryOrangeCG)
        headLayer.path = createHeadPath()
        headLayer.frame = CGRect(x: 120, y: 55, width: 160, height: 120)
        headLayer.zPosition = 20
        addSublayer(headLayer)
        
        // Snout - z: 30
        snoutLayer = createShapeLayer(color: BuddyColor.furGoldCG)
        snoutLayer.path = createSnoutPath()
        snoutLayer.frame = CGRect(x: 150, y: 115, width: 130, height: 75)
        snoutLayer.zPosition = 30
        addSublayer(snoutLayer)
        
        // Nose - z: 35
        noseLayer = createShapeLayer(color: BuddyColor.darkBrownCG)
        noseLayer.path = createNosePath()
        noseLayer.frame = CGRect(x: 192, y: 125, width: 28, height: 25)
        noseLayer.zPosition = 35
        addSublayer(noseLayer)
        
        // Mouth - z: 36
        mouthLayer = createShapeLayer(color: BuddyColor.darkBrownCG, filled: false)
        mouthLayer.path = createMouthPath()
        mouthLayer.frame = CGRect(x: 185, y: 145, width: 40, height: 20)
        mouthLayer.lineWidth = 2.5
        mouthLayer.lineCap = .round
        mouthLayer.zPosition = 36
        addSublayer(mouthLayer)
        
        // Eyes - z: 40-41
        leftEyeLayer = createShapeLayer(color: BuddyColor.darkBrownCG)
        leftEyeLayer.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 20, height: 20), transform: nil)
        leftEyeLayer.frame = CGRect(x: 165, y: 85, width: 20, height: 20)
        leftEyeLayer.zPosition = 40
        addSublayer(leftEyeLayer)
        
        rightEyeLayer = createShapeLayer(color: BuddyColor.darkBrownCG)
        rightEyeLayer.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 20, height: 20), transform: nil)
        rightEyeLayer.frame = CGRect(x: 215, y: 85, width: 20, height: 20)
        rightEyeLayer.zPosition = 41
        addSublayer(rightEyeLayer)
        
        // Eye highlights - z: 45-46 (on top of eyes)
        leftEyeHighlightLayer = createShapeLayer(color: NSColor.white.cgColor)
        leftEyeHighlightLayer.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 6, height: 6), transform: nil)
        leftEyeHighlightLayer.frame = CGRect(x: 170, y: 88, width: 6, height: 6)
        leftEyeHighlightLayer.zPosition = 45
        addSublayer(leftEyeHighlightLayer)
        
        rightEyeHighlightLayer = createShapeLayer(color: NSColor.white.cgColor)
        rightEyeHighlightLayer.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 6, height: 6), transform: nil)
        rightEyeHighlightLayer.frame = CGRect(x: 220, y: 88, width: 6, height: 6)
        rightEyeHighlightLayer.zPosition = 46
        addSublayer(rightEyeHighlightLayer)
        addSublayer(rightEarLayer)
        
        // Bark indicator (hidden by default) - z: 50
        barkLayer = createShapeLayer(color: BuddyColor.darkBrownCG, filled: false)
        barkLayer.path = createBarkPath()
        barkLayer.frame = CGRect(x: 50, y: 80, width: 60, height: 60)
        barkLayer.opacity = 0
        barkLayer.lineWidth = 3
        barkLayer.zPosition = 50
        addSublayer(barkLayer)
    }
    
    private func createShapeLayer(color: CGColor, filled: Bool = true) -> CAShapeLayer {
        let layer = CAShapeLayer()
        if filled {
            layer.fillColor = color
            layer.strokeColor = nil
        } else {
            layer.fillColor = nil
            layer.strokeColor = color
        }
        return layer
    }
    
    // MARK: - Path Creation
    private func createTailPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 80, y: 90))
        path.addCurve(to: CGPoint(x: 0, y: 0),
                     control1: CGPoint(x: 0, y: 90),
                     control2: CGPoint(x: 10, y: 45))
        path.addQuadCurve(to: CGPoint(x: 40, y: 10), control: CGPoint(x: 32, y: 0))
        path.closeSubpath()
        return path
    }
    
    private func createBodyPath() -> CGPath {
        return CGPath(roundedRect: CGRect(x: 0, y: 0, width: 200, height: 120),
                     cornerWidth: 60, cornerHeight: 60, transform: nil)
    }
    
    private func createPawPath() -> CGPath {
        return CGPath(roundedRect: CGRect(x: 0, y: 0, width: 40, height: 80),
                     cornerWidth: 20, cornerHeight: 20, transform: nil)
    }
    
    private func createHeadPath() -> CGPath {
        // Wider, shorter head for muzzle-forward look
        return CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 160, height: 120), transform: nil)
    }
    
    private func createSnoutPath() -> CGPath {
        // Protruding snout
        return CGPath(roundedRect: CGRect(x: 0, y: 0, width: 130, height: 75),
                     cornerWidth: 35, cornerHeight: 35, transform: nil)
    }
    
    private func createNosePath() -> CGPath {
        // Heart/triangular nose
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 14, y: 0)) // Top center
        path.addQuadCurve(to: CGPoint(x: 0, y: 10), control: CGPoint(x: 3, y: 3))
        path.addQuadCurve(to: CGPoint(x: 14, y: 25), control: CGPoint(x: 5, y: 20))
        path.addQuadCurve(to: CGPoint(x: 28, y: 10), control: CGPoint(x: 23, y: 20))
        path.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 25, y: 3))
        path.closeSubpath()
        return path
    }
    
    private func createMouthPath() -> CGPath {
        // Smile curve
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: 20, y: 8), control: CGPoint(x: 10, y: 10))
        path.addQuadCurve(to: CGPoint(x: 40, y: 0), control: CGPoint(x: 30, y: 10))
        return path
    }
    
    private func createTummyPatchPath() -> CGPath {
        // Lighter belly patch
        return CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 120, height: 70), transform: nil)
    }
    
    private func createPawPadPath() -> CGPath {
        // Paw pad (semi-oval)
        return CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 30, height: 20), transform: nil)
    }
    
    private func createEarPath() -> CGPath {
        // Floppy ear shape
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 22.5, y: 0))
        path.addQuadCurve(to: CGPoint(x: 45, y: 80), control: CGPoint(x: 45, y: 40))
        path.addQuadCurve(to: CGPoint(x: 0, y: 80), control: CGPoint(x: 22.5, y: 90))
        path.addQuadCurve(to: CGPoint(x: 22.5, y: 0), control: CGPoint(x: 0, y: 40))
        return path
    }
    
    private func createBarkPath() -> CGPath {
        let path = CGMutablePath()
        for i in 0..<3 {
            let radius = CGFloat(i) * 15 + 15
            path.addArc(center: CGPoint(x: 30, y: 30), radius: radius,
                       startAngle: -.pi / 4, endAngle: .pi / 4, clockwise: false)
        }
        return path
    }
    
    // MARK: - Animation Methods
    func animate(to state: BuddyAnimationState) {
        removeAllAnimations()
        
        switch state {
        case .idle:
            animateIdle()
        case .organizing:
            animateOrganizing()
        case .alert:
            animateAlert()
        case .success:
            animateSuccess()
        }
    }
    
    private func animateIdle() {
        // Gentle tail wag
        let wagAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        wagAnimation.fromValue = -0.2
        wagAnimation.toValue = 0.2
        wagAnimation.duration = 0.4
        wagAnimation.autoreverses = true
        wagAnimation.repeatCount = .infinity
        wagAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        tailLayer.add(wagAnimation, forKey: "tailWag")
    }
    
    private func animateOrganizing() {
        // Fast tail wag
        let wagAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        wagAnimation.fromValue = -0.3
        wagAnimation.toValue = 0.3
        wagAnimation.duration = 0.2
        wagAnimation.autoreverses = true
        wagAnimation.repeatCount = .infinity
        tailLayer.add(wagAnimation, forKey: "tailWag")
        
        // Head bobbing
        let bobAnimation = CABasicAnimation(keyPath: "position.y")
        bobAnimation.fromValue = headLayer.position.y
        bobAnimation.toValue = headLayer.position.y - 10
        bobAnimation.duration = 0.3
        bobAnimation.autoreverses = true
        bobAnimation.repeatCount = .infinity
        headLayer.add(bobAnimation, forKey: "headBob")
    }
    
    private func animateAlert() {
        // Ear perk with spring
        let perkLeft = CASpringAnimation(keyPath: "transform.rotation.z")
        perkLeft.fromValue = 0
        perkLeft.toValue = -0.3
        perkLeft.damping = 10
        perkLeft.stiffness = 300
        perkLeft.mass = 1
        perkLeft.duration = perkLeft.settlingDuration
        leftEarLayer.add(perkLeft, forKey: "earPerk")
        
        let perkRight = CASpringAnimation(keyPath: "transform.rotation.z")
        perkRight.fromValue = 0
        perkRight.toValue = 0.3
        perkRight.damping = 10
        perkRight.stiffness = 300
        perkRight.mass = 1
        perkRight.duration = perkRight.settlingDuration
        rightEarLayer.add(perkRight, forKey: "earPerk")
        
        // Bark animation
        let barkFade = CAKeyframeAnimation(keyPath: "opacity")
        barkFade.values = [0, 1, 1, 0]
        barkFade.keyTimes = [0, 0.2, 0.8, 1]
        barkFade.duration = 0.6
        barkLayer.add(barkFade, forKey: "bark")
        
        let barkScale = CAKeyframeAnimation(keyPath: "transform.scale")
        barkScale.values = [0.5, 1.2, 1.2, 1.5]
        barkScale.keyTimes = [0, 0.2, 0.8, 1]
        barkScale.duration = 0.6
        barkLayer.add(barkScale, forKey: "barkScale")
    }
    
    private func animateSuccess() {
        // Enthusiastic tail wag
        let wagAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        wagAnimation.fromValue = -0.4
        wagAnimation.toValue = 0.4
        wagAnimation.duration = 0.15
        wagAnimation.autoreverses = true
        wagAnimation.repeatCount = .infinity
        tailLayer.add(wagAnimation, forKey: "tailWag")
        
        // Happy bounce
        let bounceAnimation = CASpringAnimation(keyPath: "position.y")
        bounceAnimation.fromValue = position.y
        bounceAnimation.toValue = position.y - 20
        bounceAnimation.damping = 5
        bounceAnimation.stiffness = 200
        bounceAnimation.mass = 1
        bounceAnimation.duration = 0.5
        bounceAnimation.autoreverses = true
        bounceAnimation.repeatCount = .infinity
        add(bounceAnimation, forKey: "bounce")
    }
}

// MARK: - Preview
struct BuddyTheDogView_Previews: PreviewProvider {
    struct PreviewHarness: View {
        @State var state: BuddyAnimationState = .idle
        
        var body: some View {
            VStack {
                Spacer()
                
                BuddyTheDogView(state: $state)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Animate Buddy")
                        .font(.headline)
                    
                    HStack {
                        Button("Idle") { state = .idle }
                        Button("Organize") { state = .organizing }
                    }
                    
                    HStack {
                        Button("Alert") { state = .alert }
                        Button("Success") { state = .success }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(BuddyColor.primaryOrange)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding()
            }
        }
    }
    
    static var previews: some View {
        PreviewHarness()
    }
}


// MARK: - NSGraphicsImageRenderer Helper
private class NSGraphicsImageRenderer {
    let size: CGSize
    
    init(size: CGSize) {
        self.size = size
    }
    
    func image(actions: (NSGraphicsContext) -> Void) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        if let context = NSGraphicsContext.current {
            actions(context)
        }
        image.unlockFocus()
        return image
    }
}
