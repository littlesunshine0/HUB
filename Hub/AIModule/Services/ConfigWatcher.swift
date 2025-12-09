//
//  ConfigWatcher.swift
//  Hub
//
//  Created by Offline Assistant Module
//  Monitors configuration file for external changes
//

import Foundation
import Combine

/// Monitors the configuration file for external changes and triggers callbacks
class ConfigWatcher {
    // MARK: - Properties
    
    private let fileURL: URL
    private let callback: (CrawlerConfig) -> Void
    private var fileMonitor: DispatchSourceFileSystemObject?
    private let monitorQueue = DispatchQueue(label: "com.hub.configwatcher", qos: .utility)
    private var lastModificationDate: Date?
    
    // MARK: - Initialization
    
    /// Initialize the config watcher
    /// - Parameters:
    ///   - fileURL: The URL of the configuration file to watch
    ///   - callback: The callback to invoke when the configuration changes
    init(fileURL: URL, callback: @escaping (CrawlerConfig) -> Void) {
        self.fileURL = fileURL
        self.callback = callback
        self.lastModificationDate = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring the configuration file
    func start() {
        // Ensure the file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ConfigWatcher: File does not exist at \(fileURL.path)")
            return
        }
        
        // Open the file descriptor
        guard let fileDescriptor = openFileDescriptor() else {
            print("ConfigWatcher: Failed to open file descriptor")
            return
        }
        
        // Create the dispatch source
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: monitorQueue
        )
        
        // Set up event handler
        source.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        // Set up cancellation handler to close the file descriptor
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        // Store and resume the source
        fileMonitor = source
        source.resume()
        
        print("ConfigWatcher: Started monitoring \(fileURL.lastPathComponent)")
    }
    
    /// Stop monitoring the configuration file
    func stop() {
        fileMonitor?.cancel()
        fileMonitor = nil
        print("ConfigWatcher: Stopped monitoring")
    }
    
    // MARK: - Private Methods
    
    private func openFileDescriptor() -> Int32? {
        let fd = open(fileURL.path, O_EVTONLY)
        return fd >= 0 ? fd : nil
    }
    
    private func handleFileSystemEvent() {
        // Check if file still exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ConfigWatcher: File was deleted")
            // File was deleted, stop monitoring
            stop()
            return
        }
        
        // Check modification date to avoid duplicate notifications
        guard let currentModDate = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date else {
            return
        }
        
        if let lastMod = lastModificationDate, currentModDate <= lastMod {
            // No actual change, ignore
            return
        }
        
        lastModificationDate = currentModDate
        
        // Load the new configuration
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let newConfig = try decoder.decode(CrawlerConfig.self, from: data)
            
            // Validate the new configuration
            let issues = newConfig.validate()
            let errors = issues.filter { $0.severity == .error }
            
            if errors.isEmpty {
                // Invoke callback on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.callback(newConfig)
                }
                print("ConfigWatcher: Configuration updated from external source")
            } else {
                print("ConfigWatcher: New configuration has validation errors, ignoring")
                for error in errors {
                    print("  - \(error.path): \(error.message)")
                }
            }
        } catch {
            print("ConfigWatcher: Failed to load configuration: \(error.localizedDescription)")
        }
    }
}

// MARK: - Config Watcher Manager

/// Manages multiple config watchers for different configuration files
@MainActor
class ConfigWatcherManager: ObservableObject {
    private var watchers: [String: ConfigWatcher] = [:]
    
    /// Register a watcher for a configuration file
    /// - Parameters:
    ///   - identifier: A unique identifier for this watcher
    ///   - fileURL: The URL of the configuration file to watch
    ///   - callback: The callback to invoke when the configuration changes
    func registerWatcher(identifier: String, fileURL: URL, callback: @escaping (CrawlerConfig) -> Void) {
        // Stop existing watcher if any
        watchers[identifier]?.stop()
        
        // Create and start new watcher
        let watcher = ConfigWatcher(fileURL: fileURL, callback: callback)
        watcher.start()
        watchers[identifier] = watcher
    }
    
    /// Unregister a watcher
    /// - Parameter identifier: The identifier of the watcher to remove
    func unregisterWatcher(identifier: String) {
        watchers[identifier]?.stop()
        watchers.removeValue(forKey: identifier)
    }
    
    /// Stop all watchers
    func stopAll() {
        for watcher in watchers.values {
            watcher.stop()
        }
        watchers.removeAll()
    }
}
