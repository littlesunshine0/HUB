//
//  AnalyticsSession.swift
//  Hub
//
//  Analytics session tracking for user interactions
//

import Foundation
import SwiftData
import Combine

/// Represents a user session for analytics tracking
@Model
class AnalyticsSession {
    @Attribute(.unique) var id: UUID
    var userId: UUID?
    var startTime: Date
    var endTime: Date?
    var deviceInfo: String
    var appVersion: String
    var osVersion: String
    var eventCount: Int
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        startTime: Date = Date(),
        deviceInfo: String = "",
        appVersion: String = "",
        osVersion: String = "",
        eventCount: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.eventCount = eventCount
        self.isActive = isActive
    }
    
    /// End the session
    func end() {
        self.endTime = Date()
        self.isActive = false
    }
    
    /// Get session duration
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Get current session duration (even if not ended)
    var currentDuration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

/// Session manager for tracking current analytics session
@MainActor
class AnalyticsSessionManager: ObservableObject {
    @Published private(set) var currentSession: AnalyticsSession?
    
    private static var _shared: AnalyticsSessionManager?
    static var shared: AnalyticsSessionManager {
        if _shared == nil {
            _shared = AnalyticsSessionManager()
        }
        return _shared!
    }
    
    private init() {}
    
    /// Start a new analytics session
    func startSession(userId: UUID? = nil) -> AnalyticsSession {
        // End current session if exists
        if let current = currentSession, current.isActive {
            current.end()
        }
        
        let session = AnalyticsSession(
            userId: userId,
            deviceInfo: getDeviceInfo(),
            appVersion: getAppVersion(),
            osVersion: getOSVersion()
        )
        
        currentSession = session
        return session
    }
    
    /// End the current session
    func endSession() {
        currentSession?.end()
    }
    
    /// Get or create current session
    func getCurrentSession(userId: UUID? = nil) -> AnalyticsSession {
        if let session = currentSession, session.isActive {
            return session
        }
        return startSession(userId: userId)
    }
    
    /// Increment event count for current session
    func incrementEventCount() {
        currentSession?.eventCount += 1
    }
    
    // MARK: - Device Info Helpers
    
    private func getDeviceInfo() -> String {
        #if os(macOS)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        #else
        return "Unknown"
        #endif
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}
