import Foundation
import Combine

// MARK: - A/B Testing Framework
@MainActor
class ABTestingFramework: ObservableObject {
    static let shared = ABTestingFramework()
    
    @Published var activeTests: [ABTest] = []
    @Published var results: [String: ABTestResult] = [:]
    
    func createTest(name: String, variants: [String], trafficSplit: [Double]) -> ABTest {
        let test = ABTest(name: name, variants: variants, trafficSplit: trafficSplit)
        activeTests.append(test)
        return test
    }
    
    func getVariant(for testId: String, userId: String) -> String {
        guard let test = activeTests.first(where: { $0.id.uuidString == testId }) else {
            return "control"
        }
        
        let hash = abs(userId.hashValue) % 100
        var cumulative = 0.0
        
        for (index, split) in test.trafficSplit.enumerated() {
            cumulative += split * 100
            if Double(hash) < cumulative {
                return test.variants[index]
            }
        }
        
        return test.variants.first ?? "control"
    }
    
    func trackConversion(testId: String, variant: String, userId: String, value: Double = 1.0) {
        Task {
            let event = ABTestEvent(testId: testId, variant: variant, userId: userId, value: value)
            await recordEvent(event)
            await updateResults(for: testId)
        }
    }
    
    func getResults(for testId: String) async -> ABTestResult? {
        results[testId]
    }
    
    func endTest(testId: String) {
        activeTests.removeAll { $0.id.uuidString == testId }
    }
    
    private func recordEvent(_ event: ABTestEvent) async {
        // Store event
    }
    
    private func updateResults(for testId: String) async {
        // Calculate statistics
        results[testId] = ABTestResult(
            testId: testId,
            variantResults: [:],
            winner: nil,
            confidence: 0.0
        )
    }
}

struct ABTest: Identifiable {
    let id = UUID()
    let name: String
    let variants: [String]
    let trafficSplit: [Double]
    let createdAt = Date()
}

struct ABTestEvent {
    let testId: String
    let variant: String
    let userId: String
    let value: Double
    let timestamp = Date()
}

struct ABTestResult {
    let testId: String
    let variantResults: [String: VariantMetrics]
    let winner: String?
    let confidence: Double
}

struct VariantMetrics {
    let conversions: Int
    let totalUsers: Int
    let conversionRate: Double
    let averageValue: Double
}
