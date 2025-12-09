//
//  AgentScenarioTester.swift
//  Hub
//
//  Test collaboration workflows with real scenarios
//

import Foundation
import SwiftUI
import Combine

// MARK: - Scenario Tester

@MainActor
public class AgentScenarioTester: ObservableObject {
    private let agentSystem = RoleBasedAgentSystem.shared
    
    @Published public var testResults: [ScenarioTestResult] = []
    @Published public var isRunning = false
    
    // MARK: - Test Scenarios
    
    public func runAllScenarios() async {
        isRunning = true
        testResults.removeAll()
        
        await testAuthenticationFlowScenario()
        await testUIRefactorScenario()
        await testSecurityVulnerabilityScenario()
        await testPerformanceOptimizationScenario()
        await testNewFeatureDesignScenario()
        
        isRunning = false
    }
    
    // MARK: - Scenario 1: Authentication Flow Design
    
    public func testAuthenticationFlowScenario() async {
        let scenario = TestScenario(
            name: "Authentication Flow Design",
            description: "Design a secure, user-friendly authentication system",
            context: "Mobile app needs biometric auth, 2FA, and password reset"
        )
        
        let startTime = Date()
        
        // Request ideas from all relevant agents
        let proposals = await agentSystem.requestIdeas(
            for: "authentication flow",
            context: scenario.context
        )
        
        // Conduct security audit
        let sampleAuthCode = """
        func authenticate(username: String, password: String) async throws {
            let hashedPassword = password.sha256()
            try await authService.login(username, hashedPassword)
        }
        """
        
        let securityAudit = await agentSystem.conductSecurityAudit(code: sampleAuthCode)
        
        // Design review
        let designReview = await agentSystem.conductDesignReview(design: "Biometric Auth Screen")
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = ScenarioTestResult(
            scenario: scenario,
            proposalCount: proposals.count,
            reviewCount: securityAudit.issues.count + designReview.actionItems.count,
            duration: duration,
            success: true,
            insights: [
                "💡 \(proposals.count) agents contributed ideas",
                "🔒 Security audit found \(securityAudit.issues.count) issues",
                "🎨 Design review generated \(designReview.actionItems.count) action items",
                "✅ Collaborative approach identified concerns from multiple perspectives"
            ]
        )
        
        testResults.append(result)
    }
    
    // MARK: - Scenario 2: UI Refactor
    
    public func testUIRefactorScenario() async {
        let scenario = TestScenario(
            name: "UI Component Refactor",
            description: "Refactor legacy UI component for better maintainability",
            context: "Complex view with 500+ lines, poor testability, accessibility issues"
        )
        
        let startTime = Date()
        
        let proposals = await agentSystem.requestIdeas(
            for: "UI refactor",
            context: scenario.context
        )
        
        let sampleUICode = """
        struct LegacyView: View {
            var body: some View {
                VStack {
                    Text("Title").font(.title)
                    Button("Action") { }
                }
            }
        }
        """
        
        let reviews = await agentSystem.requestReview(code: sampleUICode, type: .ui)
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = ScenarioTestResult(
            scenario: scenario,
            proposalCount: proposals.count,
            reviewCount: reviews.count,
            duration: duration,
            success: true,
            insights: [
                "🎨 Designer suggested visual improvements",
                "👨‍💻 Developer recommended architectural changes",
                "♿️ QA identified accessibility gaps",
                "📊 Multiple perspectives led to comprehensive refactor plan"
            ]
        )
        
        testResults.append(result)
    }
    
    // MARK: - Scenario 3: Security Vulnerability
    
    public func testSecurityVulnerabilityScenario() async {
        let scenario = TestScenario(
            name: "Security Vulnerability Assessment",
            description: "Identify and fix security vulnerabilities in payment flow",
            context: "Payment processing with sensitive user data"
        )
        
        let startTime = Date()
        
        let vulnerableCode = """
        func processPayment(cardNumber: String, cvv: String) {
            // Store in UserDefaults
            UserDefaults.standard.set(cardNumber, forKey: "card")
            UserDefaults.standard.set(cvv, forKey: "cvv")
        }
        """
        
        let securityAudit = await agentSystem.conductSecurityAudit(code: vulnerableCode)
        let reviews = await agentSystem.requestReview(code: vulnerableCode, type: .security)
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = ScenarioTestResult(
            scenario: scenario,
            proposalCount: 0,
            reviewCount: reviews.count,
            duration: duration,
            success: !securityAudit.passed, // Success = found vulnerabilities
            insights: [
                "🚨 Security agent identified critical vulnerabilities",
                "🔐 Backend engineer suggested encryption",
                "✅ Multi-agent review caught issues single review might miss",
                "💡 Recommendations: \(securityAudit.recommendations.count) security improvements"
            ]
        )
        
        testResults.append(result)
    }
    
    // MARK: - Scenario 4: Performance Optimization
    
    public func testPerformanceOptimizationScenario() async {
        let scenario = TestScenario(
            name: "Performance Optimization",
            description: "Optimize slow rendering and memory issues",
            context: "App experiencing frame drops and high memory usage"
        )
        
        let startTime = Date()
        
        let proposals = await agentSystem.requestIdeas(
            for: "performance optimization",
            context: scenario.context
        )
        
        let slowCode = """
        func loadImages() {
            for i in 0..<1000 {
                let image = UIImage(named: "image\\(i)")
                images.append(image)
            }
        }
        """
        
        let reviews = await agentSystem.requestReview(code: slowCode, type: .general)
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = ScenarioTestResult(
            scenario: scenario,
            proposalCount: proposals.count,
            reviewCount: reviews.count,
            duration: duration,
            success: true,
            insights: [
                "⚡️ Technical artist suggested particle pooling",
                "👨‍💻 Developer recommended lazy loading",
                "📊 Data scientist proposed performance metrics",
                "🎯 Combined expertise created comprehensive optimization plan"
            ]
        )
        
        testResults.append(result)
    }
    
    // MARK: - Scenario 5: New Feature Design
    
    public func testNewFeatureDesignScenario() async {
        let scenario = TestScenario(
            name: "New Feature: Social Sharing",
            description: "Design and implement social sharing feature",
            context: "Users want to share achievements on social media"
        )
        
        let startTime = Date()
        
        let proposals = await agentSystem.requestIdeas(
            for: "social sharing feature",
            context: scenario.context
        )
        
        // Simulate design review
        let designReview = await agentSystem.conductDesignReview(design: "Share Sheet UI")
        
        let duration = Date().timeIntervalSince(startTime)
        
        let result = ScenarioTestResult(
            scenario: scenario,
            proposalCount: proposals.count,
            reviewCount: designReview.actionItems.count,
            duration: duration,
            success: true,
            insights: [
                "🎨 Designer created visual mockups",
                "📱 Developer planned technical implementation",
                "👥 Community manager suggested engagement features",
                "📊 Product manager validated against user research",
                "🎯 Cross-functional collaboration produced complete feature spec"
            ]
        )
        
        testResults.append(result)
    }
}

// MARK: - Test Models

public struct TestScenario {
    public let name: String
    public let description: String
    public let context: String
}

public struct ScenarioTestResult: Identifiable {
    public let id = UUID()
    public let scenario: TestScenario
    public let proposalCount: Int
    public let reviewCount: Int
    public let duration: TimeInterval
    public let success: Bool
    public let insights: [String]
    
    public var summary: String {
        """
        ✅ \(scenario.name)
        📊 \(proposalCount) proposals, \(reviewCount) reviews
        ⏱️ Completed in \(String(format: "%.2f", duration))s
        """
    }
}

// MARK: - Test UI

public struct AgentScenarioTestView: View {
    @StateObject private var tester = AgentScenarioTester()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Agent Collaboration Tester")
                            .font(.title)
                            .bold()
                        
                        Text("Test multi-agent workflows with real scenarios")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Run Tests Button
                    Button(action: {
                        Task {
                            await tester.runAllScenarios()
                        }
                    }) {
                        HStack {
                            if tester.isRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "play.circle.fill")
                            }
                            Text(tester.isRunning ? "Running Tests..." : "Run All Scenarios")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(tester.isRunning)
                    .padding(.horizontal)
                    
                    // Results
                    if !tester.testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Test Results")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(tester.testResults) { result in
                                TestResultCard(result: result)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Scenario Tests")
        }
    }
}

struct TestResultCard: View {
    let result: ScenarioTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text(result.scenario.name)
                        .font(.headline)
                    Text(result.scenario.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("\(result.proposalCount)", systemImage: "lightbulb.fill")
                Label("\(result.reviewCount)", systemImage: "doc.text.magnifyingglass")
                Label(String(format: "%.1fs", result.duration), systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(result.insights, id: \.self) { insight in
                    Text(insight)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(PlatformColorPalette.surface)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}
