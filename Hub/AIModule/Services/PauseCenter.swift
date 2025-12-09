//
//  PauseCenter.swift
//  Hub
//
//  Created by Offline Assistant Module
//  Thread-safe pause/resume control for crawling operations
//

import Foundation
import Combine

/// Thread-safe pause/resume control for crawling operations
/// Implemented as an actor to ensure thread-safe state management across concurrent operations
actor PauseCenter {
    
    // MARK: - Private Properties
    
    /// Current pause state
    private var isPausedState: Bool = false
    
    /// Total number of pause requests made (for diagnostics)
    private var pauseRequests: Int = 0
    
    /// Subject for emitting pause state change events
    private let stateChangeSubject = PassthroughSubject<PauseStateChange, Never>()
    
    // MARK: - Public Properties
    
    /// Publisher for pause state change events
    /// Allows external components to observe pause/resume events
    nonisolated var stateChangePublisher: AnyPublisher<PauseStateChange, Never> {
        stateChangeSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize with unpaused state
    }
    
    // MARK: - Public Methods
    
    /// Sets the pause state and emits a state change event
    /// - Parameter paused: The new pause state (true to pause, false to resume)
    func setPaused(_ paused: Bool) {
        let previousState = isPausedState
        isPausedState = paused
        
        if paused {
            pauseRequests += 1
        }
        
        // Emit event if state actually changed
        if previousState != paused {
            let event = PauseStateChange(
                isPaused: paused,
                timestamp: Date(),
                totalPauseRequests: pauseRequests
            )
            stateChangeSubject.send(event)
        }
    }
    
    /// Returns the current pause state
    /// - Returns: true if currently paused, false otherwise
    func isPaused() -> Bool {
        return isPausedState
    }
    
    /// Blocks execution while paused, checking every 100ms
    /// This method allows crawling operations to wait until resume is called
    func waitIfPaused() async {
        while await isPaused() {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
    
    /// Returns the total number of pause requests made
    /// Useful for diagnostics and monitoring
    /// - Returns: Total count of pause requests
    func getPauseCount() -> Int {
        return pauseRequests
    }
    
    /// Resets the pause request counter
    /// Useful for testing or diagnostics reset
    func resetPauseCount() {
        pauseRequests = 0
    }
    
    /// Returns a snapshot of the current state for diagnostics
    /// - Returns: A snapshot containing current state and metrics
    func getSnapshot() -> PauseCenterSnapshot {
        return PauseCenterSnapshot(
            isPaused: isPausedState,
            totalPauseRequests: pauseRequests,
            timestamp: Date()
        )
    }
}

// MARK: - Supporting Types

/// Represents a pause state change event
struct PauseStateChange {
    /// The new pause state
    let isPaused: Bool
    
    /// When the state change occurred
    let timestamp: Date
    
    /// Total number of pause requests at the time of this change
    let totalPauseRequests: Int
}

/// Snapshot of PauseCenter state for diagnostics
struct PauseCenterSnapshot {
    /// Current pause state
    let isPaused: Bool
    
    /// Total number of pause requests
    let totalPauseRequests: Int
    
    /// When this snapshot was taken
    let timestamp: Date
}
