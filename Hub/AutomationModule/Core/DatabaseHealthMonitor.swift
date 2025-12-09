//
//  DatabaseHealthMonitor.swift
//  Hub
//
//  Automated database health monitoring and recovery system
//

import Foundation
import SQLite3

/// Monitors and maintains database health, automatically recovering from locks and corruption
actor DatabaseHealthMonitor {
    
    // MARK: - Properties
    
    private let derivedDataPath: String
    private let maxRecoveryAttempts = 3
    private var isMonitoring = false
    
    // MARK: - Initialization
    
    init() {
        // Get derived data path
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        self.derivedDataPath = "\(homeDir)/Library/Developer/Xcode/DerivedData"
    }
    
    // MARK: - Public Methods
    
    /// Perform a blocking preflight health check intended to run before starting work that may open databases
    /// Returns true if all databases are healthy or successfully recovered
    @discardableResult
    func preflightCheck() async -> Bool {
        // Run a single pass health check and return overall status
        let databases = findBuildDatabases()
        var allGood = true
        for dbPath in databases {
            // For preflight, perform the same logic as checkAndRecoverDatabase but track failures
            await checkAndRecoverDatabase(at: dbPath)
            let status = await checkDatabaseIntegrity(at: dbPath)
            switch status {
            case .healthy:
                break
            case .corrupted, .inaccessible:
                allGood = false
            }
        }
        return allGood
    }
    
    /// Convenience static preflight that can be called at app startup with timeout
    static func preflight() async {
        let monitor = DatabaseHealthMonitor()
        
        // Run preflight with a 5-second timeout to avoid blocking app startup
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await monitor.preflightCheck()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second timeout
                return false
            }
            
            // Return on first completion (either preflight or timeout)
            _ = await group.next()
            group.cancelAll()
        }
    }
    
    /// Start monitoring database health
    func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        print("🔍 [DatabaseHealthMonitor] Starting database health monitoring...")
        
        // Ensure we preflight check before periodic monitoring to avoid locks
        _ = await preflightCheck()
        
        // Run initial health check
        await performHealthCheck()
        
        // Schedule periodic checks
        Task {
            while isMonitoring {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Check every 60 seconds
                await performHealthCheck()
            }
        }
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        isMonitoring = false
        print("🛑 [DatabaseHealthMonitor] Stopped database health monitoring")
    }
    
    /// Perform a comprehensive health check and recovery if needed
    func performHealthCheck() async {
        print("🏥 [DatabaseHealthMonitor] Performing health check...")
        
        // Find all Xcode build databases
        let databases = findBuildDatabases()
        
        for dbPath in databases {
            await checkAndRecoverDatabase(at: dbPath)
        }
    }
    
    // MARK: - Private Methods
    
    /// Find all Xcode build databases
    private func findBuildDatabases() -> [String] {
        var databases: [String] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: URL(fileURLWithPath: derivedDataPath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return databases
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "build.db" {
                databases.append(fileURL.path)
            }
        }
        
        return databases
    }
    
    /// Check and recover a specific database
    private func checkAndRecoverDatabase(at path: String) async {
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        
        print("📊 [DatabaseHealthMonitor] Checking database: \(path)")
        
        // Step 1: Check if database is locked
        if await isDatabaseLocked(at: path) {
            print("🔒 [DatabaseHealthMonitor] Database is locked, attempting recovery...")
            await notifyUser(title: "Database Locked", message: "Attempting automatic recovery...")
            
            // Close any processes holding the database
            await closeProcessesHoldingDatabase(at: path)
            
            // Wait a moment for processes to close
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Retry open with a short busy timeout to see if lock clears without destructive actions
            if await tryOpenWithBusyTimeout(path: path, milliseconds: 2000) == false {
                // If still locked and not in use, remove WAL/SHM and retry
                let inUse = await isDatabaseInUseByProcesses(at: path)
                if !inUse {
                    let walPath = path + "-wal"
                    let shmPath = path + "-shm"
                    try? FileManager.default.removeItem(atPath: walPath)
                    try? FileManager.default.removeItem(atPath: shmPath)
                    print("🧹 [DatabaseHealthMonitor] Removed WAL/SHM for: \(path)")
                    // Try again with busy timeout
                    _ = await tryOpenWithBusyTimeout(path: path, milliseconds: 2000)
                }
            }
        }
        
        // Step 2: Check database integrity
        let integrityResult = await checkDatabaseIntegrity(at: path)
        
        switch integrityResult {
        case .healthy:
            print("✅ [DatabaseHealthMonitor] Database is healthy")
        case .corrupted(let error):
            print("⚠️ [DatabaseHealthMonitor] Database corruption detected: \(error)")
            await notifyUser(title: "Database Corruption", message: "Attempting automatic repair...")
            if await repairDatabase(at: path) {
                print("✅ [DatabaseHealthMonitor] Database repaired successfully")
                await notifyUser(title: "Database Repaired", message: "Database has been repaired successfully")
            } else {
                print("❌ [DatabaseHealthMonitor] Database repair failed, cleaning...")
                await cleanDatabase(at: path)
                await notifyUser(title: "Database Cleaned", message: "Database has been cleaned and will be rebuilt")
            }
        case .inaccessible:
            print("⚠️ [DatabaseHealthMonitor] Database is inaccessible")
            // If not in use, as a last resort, rename the DB to force rebuild
            let inUse = await isDatabaseInUseByProcesses(at: path)
            if !inUse {
                let backupPath = path + ".forced-backup-\(Int(Date().timeIntervalSince1970))"
                do {
                    try FileManager.default.moveItem(atPath: path, toPath: backupPath)
                    print("🧨 [DatabaseHealthMonitor] Renamed locked DB to: \(backupPath). Xcode will rebuild it.")
                    await notifyUser(title: "Build DB Rebuilt", message: "A locked build database was backed up and will be rebuilt.")
                } catch {
                    print("❌ [DatabaseHealthMonitor] Failed to rename locked DB: \(error)")
                }
            } else {
                await closeProcessesHoldingDatabase(at: path)
            }
        }
    }
    
    /// Check if database is locked
    private func isDatabaseLocked(at path: String) async -> Bool {
        // Try to open the database with a short timeout
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        
        let result = sqlite3_open_v2(path, &db, flags, nil)
        
        if result == SQLITE_OK {
            // Try to execute a simple query
            var stmt: OpaquePointer?
            let query = "SELECT 1;"
            
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_finalize(stmt)
                sqlite3_close(db)
                return false
            } else {
                sqlite3_close(db)
                return true
            }
        } else if result == SQLITE_BUSY || result == SQLITE_LOCKED {
            sqlite3_close(db)
            return true
        }
        
        sqlite3_close(db)
        return false
    }
    
    /// Check database integrity
    private func checkDatabaseIntegrity(at path: String) async -> DatabaseHealthStatus {
        var db: OpaquePointer?
        
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return .inaccessible
        }
        
        defer { sqlite3_close(db) }
        
        // Run integrity check
        var stmt: OpaquePointer?
        let query = "PRAGMA integrity_check;"
        
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
            return .inaccessible
        }
        
        defer { sqlite3_finalize(stmt) }
        
        var results: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cString = sqlite3_column_text(stmt, 0) {
                results.append(String(cString: cString))
            }
        }
        
        if results.isEmpty || results.first == "ok" {
            return .healthy
        } else {
            return .corrupted(results.joined(separator: ", "))
        }
    }
    
    /// Repair database
    private func repairDatabase(at path: String) async -> Bool {
        // Backup the database first
        let backupPath = path + ".backup"
        
        do {
            try FileManager.default.copyItem(atPath: path, toPath: backupPath)
            print("💾 [DatabaseHealthMonitor] Database backed up to: \(backupPath)")
        } catch {
            print("❌ [DatabaseHealthMonitor] Failed to backup database: \(error)")
            return false
        }
        
        // Try to repair using VACUUM
        var db: OpaquePointer?
        
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            return false
        }
        
        defer { sqlite3_close(db) }
        
        // Execute VACUUM
        let vacuumResult = sqlite3_exec(db, "VACUUM;", nil, nil, nil)
        
        if vacuumResult == SQLITE_OK {
            print("✅ [DatabaseHealthMonitor] VACUUM completed successfully")
            
            // Verify integrity after repair
            let integrityResult = await checkDatabaseIntegrity(at: path)
            
            if case .healthy = integrityResult {
                // Remove backup if repair was successful
                try? FileManager.default.removeItem(atPath: backupPath)
                return true
            }
        }
        
        // Restore backup if repair failed
        try? FileManager.default.removeItem(atPath: path)
        try? FileManager.default.moveItem(atPath: backupPath, toPath: path)
        
        return false
    }
    
    /// Clean database by removing it
    private func cleanDatabase(at path: String) async {
        do {
            // Remove the database file
            try FileManager.default.removeItem(atPath: path)
            print("🗑️ [DatabaseHealthMonitor] Database removed: \(path)")
            
            // Remove associated files
            let walPath = path + "-wal"
            let shmPath = path + "-shm"
            
            try? FileManager.default.removeItem(atPath: walPath)
            try? FileManager.default.removeItem(atPath: shmPath)
            
        } catch {
            print("❌ [DatabaseHealthMonitor] Failed to clean database: \(error)")
        }
    }
    
    /// Close processes holding the database
    private func closeProcessesHoldingDatabase(at path: String) async {
        print("🔪 [DatabaseHealthMonitor] Closing processes holding database...")
        
        // Use lsof to find processes
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = [path]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse PIDs from lsof output
            let lines = output.components(separatedBy: .newlines)
            var pids: Set<Int32> = []
            
            for line in lines.dropFirst() { // Skip header
                let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if components.count > 1, let pid = Int32(components[1]) {
                    pids.insert(pid)
                }
            }
            
            // Kill processes
            for pid in pids {
                print("🔪 [DatabaseHealthMonitor] Killing process: \(pid)")
                kill(pid, SIGKILL)
            }
            
            if !pids.isEmpty {
                print("✅ [DatabaseHealthMonitor] Closed \(pids.count) process(es)")
            }
            
        } catch {
            print("❌ [DatabaseHealthMonitor] Failed to find processes: \(error)")
        }
    }
    
    /// Check if any processes currently hold the database file
    private func isDatabaseInUseByProcesses(at path: String) async -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = [path]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            // If there are more than just the header line, it's in use
            let lines = output.components(separatedBy: .newlines)
            return lines.count > 1 && lines[1].isEmpty == false
        } catch {
            return false
        }
    }
    
    /// Attempt to open the DB with a busy timeout to test if lock persists
    private func tryOpenWithBusyTimeout(path: String, milliseconds: Int32) async -> Bool {
        var db: OpaquePointer?
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            return false
        }
        defer { sqlite3_close(db) }
        _ = sqlite3_busy_timeout(db, milliseconds)
        var stmt: OpaquePointer?
        let query = "SELECT 1;"
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_finalize(stmt)
            return true
        }
        return false
    }
    
    /// Notify user with system notification
    private func notifyUser(title: String, message: String) async {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e",
            "display notification \"\(message)\" with title \"\(title)\""
        ]
        
        try? task.run()
    }
    
    /// Run diagnostics
    func runDiagnostics() async -> DatabaseDiagnostics {
        var diagnostics = await DatabaseDiagnostics()
        
        // Check disk space
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: derivedDataPath),
           let freeSize = attributes[.systemFreeSize] as? Int64 {
            diagnostics.availableDiskSpace = freeSize
        }
        
        // Find all databases
        let databases = findBuildDatabases()
        diagnostics.databaseCount = databases.count
        
        // Check each database
        for dbPath in databases {
            let status = await checkDatabaseIntegrity(at: dbPath)
            diagnostics.databaseStatuses[dbPath] = status
        }
        
        // Check for Xcode processes
        diagnostics.xcodeProcessCount = await countXcodeProcesses()
        
        return diagnostics
    }
    
    /// Count Xcode-related processes
    private func countXcodeProcesses() async -> Int {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["aux"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let lines = output.components(separatedBy: .newlines)
            let xcodeLines = lines.filter { $0.lowercased().contains("xcode") && !$0.contains("grep") }
            
            return xcodeLines.count
        } catch {
            return 0
        }
    }
}

// MARK: - Supporting Types

enum DatabaseHealthStatus {
    case healthy
    case corrupted(String)
    case inaccessible
}

struct DatabaseDiagnostics {
    var availableDiskSpace: Int64 = 0
    var databaseCount: Int = 0
    var databaseStatuses: [String: DatabaseHealthStatus] = [:]
    var xcodeProcessCount: Int = 0
    
    var formattedDiskSpace: String {
        ByteCountFormatter.string(fromByteCount: availableDiskSpace, countStyle: .file)
    }
    
    var hasIssues: Bool {
        databaseStatuses.values.contains { status in
            if case .healthy = status {
                return false
            }
            return true
        }
    }
}

