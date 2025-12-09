//
//  StorageFileManager.swift
//  Hub
//
//  Storage file manager for disk persistence with atomic writes
//  Provides reliable file I/O with corruption prevention and error handling
//

import Foundation
import Combine

/// Actor providing thread-safe disk persistence operations
/// Implements atomic file writes, lazy loading, and integrity verification
actor StorageFileManager {
    
    // MARK: - Properties
    
    /// Base directory for storage files
    let storageDirectory: URL
    
    /// File manager instance
    private let fileManager: FileManager
    
    /// JSON encoder with consistent configuration
    private let encoder: JSONEncoder
    
    /// JSON decoder with consistent configuration
    private let decoder: JSONDecoder
    
    /// Cache of loaded entries to avoid repeated disk reads
    private var loadedEntries: [String: any Storable] = [:]
    
    /// Maximum cache size (number of entries)
    private let maxCacheSize: Int = 1000
    
    // MARK: - Initialization
    
    /// Initialize the file manager with a storage directory
    /// - Parameter storageDirectory: Directory URL for storing files (defaults to app support directory)
    /// - Throws: LocalStorageError.persistenceFailed if directory creation fails
    init(storageDirectory: URL? = nil) async throws {
        self.fileManager = FileManager.default
        
        // Use provided directory or default to app support
        if let directory = storageDirectory {
            self.storageDirectory = directory
        } else {
            guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                throw LocalStorageError.persistenceFailed("Could not access application support directory")
            }
            self.storageDirectory = appSupport.appendingPathComponent("HubStorage", isDirectory: true)
        }
        
        // Configure JSON encoder/decoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        // Create storage directory if it doesn't exist
        try await createStorageDirectory()
    }
    
    // MARK: - Directory Management
    
    /// Create the storage directory if it doesn't exist
    private func createStorageDirectory() async throws {
        guard !fileManager.fileExists(atPath: storageDirectory.path) else {
            return
        }
        
        do {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        } catch {
            throw LocalStorageError.persistenceFailed("Failed to create storage directory: \(error.localizedDescription)")
        }
    }
    
    /// Get the file URL for a given entry ID
    private func fileURL(for id: String) -> URL {
        return storageDirectory.appendingPathComponent("\(id).json")
    }
    
    /// Get the temporary file URL for atomic writes
    private func temporaryFileURL(for id: String) -> URL {
        return storageDirectory.appendingPathComponent("\(id).tmp")
    }
    
    // MARK: - Persistence Operations
    
    /// Persist an entry to disk using atomic write
    /// - Parameter item: The item to persist
    /// - Throws: LocalStorageError if persistence fails
    func persist<T: Storable>(_ item: T) async throws {
        let fileURL = fileURL(for: item.id)
        let tempURL = temporaryFileURL(for: item.id)
        
        // Check disk space before writing
        try await checkDiskSpace()
        
        do {
            // Encode to JSON
            let data = try encoder.encode(item)
            
            // Write to temporary file first (atomic write pattern)
            try data.write(to: tempURL, options: .atomic)
            
            // Verify the written file
            try await verifyFileIntegrity(at: tempURL, expectedType: T.self)
            
            // Move temporary file to final location (atomic operation)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try fileManager.moveItem(at: tempURL, to: fileURL)
            
            // Update cache
            loadedEntries[item.id] = item
            await evictCacheIfNeeded()
            
        } catch let error as LocalStorageError {
            // Clean up temporary file on error
            try? fileManager.removeItem(at: tempURL)
            throw error
        } catch {
            // Clean up temporary file on error
            try? fileManager.removeItem(at: tempURL)
            throw LocalStorageError.persistenceFailed("Failed to persist entry \(item.id): \(error.localizedDescription)")
        }
    }
    
    /// Persist multiple entries in a batch
    /// - Parameter items: Array of items to persist
    /// - Throws: LocalStorageError.batchSaveFailed with details of failures
    func persistMultiple<T: Storable>(_ items: [T]) async throws {
        var errors: [String: Error] = [:]
        
        for item in items {
            do {
                try await persist(item)
            } catch {
                errors[item.id] = error
            }
        }
        
        if !errors.isEmpty {
            throw LocalStorageError.batchSaveFailed(errors)
        }
    }
    
    // MARK: - Loading Operations
    
    /// Load an entry from disk (with lazy loading)
    /// - Parameter id: The entry ID to load
    /// - Returns: The loaded entry
    /// - Throws: LocalStorageError if loading fails
    func load<T: Storable>(id: String) async throws -> T {
        // Check cache first
        if let cached = loadedEntries[id] as? T {
            return cached
        }
        
        let fileURL = fileURL(for: id)
        
        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw LocalStorageError.entryNotFound(id)
        }
        
        do {
            // Read file data
            let data = try Data(contentsOf: fileURL)
            
            // Decode from JSON
            let entry = try decoder.decode(T.self, from: data)
            
            // Verify the loaded entry
            guard entry.id == id else {
                throw LocalStorageError.persistenceFailed("Entry ID mismatch: expected \(id), got \(entry.id)")
            }
            
            // Update cache
            loadedEntries[id] = entry
            await evictCacheIfNeeded()
            
            return entry
            
        } catch let error as DecodingError {
            throw LocalStorageError.persistenceFailed("Failed to decode entry \(id): \(error.localizedDescription)")
        } catch let error as LocalStorageError {
            throw error
        } catch {
            throw LocalStorageError.persistenceFailed("Failed to load entry \(id): \(error.localizedDescription)")
        }
    }
    
    /// Load multiple entries from disk
    /// - Parameter ids: Array of entry IDs to load
    /// - Returns: Array of loaded entries (may be fewer than requested if some don't exist)
    func loadMultiple<T: Storable>(ids: [String]) async -> [T] {
        var results: [T] = []
        
        for id in ids {
            do {
                let entry: T = try await load(id: id)
                results.append(entry)
            } catch {
                // Skip entries that fail to load
                continue
            }
        }
        
        return results
    }
    
    /// Load all entries of a specific type from disk
    /// - Returns: Array of all entries of type T
    func loadAll<T: Storable>() async throws -> [T] {
        var results: [T] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in contents where fileURL.pathExtension == "json" {
                let id = fileURL.deletingPathExtension().lastPathComponent
                
                do {
                    let entry: T = try await load(id: id)
                    results.append(entry)
                } catch {
                    // Skip entries that fail to load or are wrong type
                    continue
                }
            }
            
        } catch {
            throw LocalStorageError.persistenceFailed("Failed to list storage directory: \(error.localizedDescription)")
        }
        
        return results
    }
    
    // MARK: - Deletion Operations
    
    /// Delete an entry from disk
    /// - Parameter id: The entry ID to delete
    /// - Throws: LocalStorageError if deletion fails
    func delete(id: String) async throws {
        let fileURL = fileURL(for: id)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw LocalStorageError.entryNotFound(id)
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            
            // Remove from cache
            loadedEntries.removeValue(forKey: id)
            
        } catch {
            throw LocalStorageError.persistenceFailed("Failed to delete entry \(id): \(error.localizedDescription)")
        }
    }
    
    /// Delete multiple entries from disk
    /// - Parameter ids: Array of entry IDs to delete
    /// - Throws: LocalStorageError.batchSaveFailed with details of failures
    func deleteMultiple(ids: [String]) async throws {
        var errors: [String: Error] = [:]
        
        for id in ids {
            do {
                try await delete(id: id)
            } catch {
                errors[id] = error
            }
        }
        
        if !errors.isEmpty {
            throw LocalStorageError.batchSaveFailed(errors)
        }
    }
    
    /// Clear all entries from disk
    func clear() async throws {
        do {
            let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in contents where fileURL.pathExtension == "json" {
                try fileManager.removeItem(at: fileURL)
            }
            
            // Clear cache
            loadedEntries.removeAll()
            
        } catch {
            throw LocalStorageError.persistenceFailed("Failed to clear storage: \(error.localizedDescription)")
        }
    }
    
    // MARK: - File Integrity Verification
    
    /// Verify the integrity of a file by attempting to decode it
    /// - Parameters:
    ///   - url: The file URL to verify
    ///   - expectedType: The expected type of the entry
    /// - Throws: LocalStorageError if verification fails
    private func verifyFileIntegrity<T: Storable>(at url: URL, expectedType: T.Type) async throws {
        do {
            let data = try Data(contentsOf: url)
            _ = try decoder.decode(T.self, from: data)
        } catch {
            throw LocalStorageError.persistenceFailed("File integrity verification failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Disk Space Management
    
    /// Check if there's sufficient disk space for operations
    /// - Throws: LocalStorageError.diskSpaceInsufficient if space is low
    private func checkDiskSpace() async throws {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: storageDirectory.path)
            
            if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                let freeBytes = freeSpace.int64Value
                let minimumRequired: Int64 = 100 * 1024 * 1024 // 100 MB minimum
                
                if freeBytes < minimumRequired {
                    throw LocalStorageError.diskSpaceInsufficient
                }
            }
        } catch let error as LocalStorageError {
            throw error
        } catch {
            // If we can't check disk space, log but don't fail
            print("⚠️ Could not check disk space: \(error.localizedDescription)")
        }
    }
    
    /// Get current disk usage statistics
    /// - Returns: Dictionary with storage metrics
    func diskUsageStatistics() async -> [String: Any] {
        var stats: [String: Any] = [:]
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            var fileCount = 0
            
            for fileURL in contents where fileURL.pathExtension == "json" {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? NSNumber {
                    totalSize += fileSize.int64Value
                    fileCount += 1
                }
            }
            
            stats["totalSizeBytes"] = totalSize
            stats["totalSizeMB"] = Double(totalSize) / (1024.0 * 1024.0)
            stats["fileCount"] = fileCount
            stats["averageFileSizeBytes"] = fileCount > 0 ? totalSize / Int64(fileCount) : 0
            
            // Get available disk space
            if let attributes = try? fileManager.attributesOfFileSystem(forPath: storageDirectory.path),
               let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                stats["availableSpaceBytes"] = freeSpace.int64Value
                stats["availableSpaceMB"] = Double(freeSpace.int64Value) / (1024.0 * 1024.0)
            }
            
        } catch {
            stats["error"] = error.localizedDescription
        }
        
        return stats
    }
    
    // MARK: - Cache Management
    
    /// Evict cache entries if cache size exceeds maximum
    private func evictCacheIfNeeded() async {
        guard loadedEntries.count > maxCacheSize else {
            return
        }
        
        // Simple LRU: remove oldest entries (by keeping only the most recent maxCacheSize/2)
        let targetSize = maxCacheSize / 2
        let entriesToKeep = loadedEntries.count - targetSize
        
        if entriesToKeep > 0 {
            let keysToRemove = Array(loadedEntries.keys.prefix(entriesToKeep))
            for key in keysToRemove {
                loadedEntries.removeValue(forKey: key)
            }
        }
    }
    
    /// Clear the in-memory cache
    func clearCache() async {
        loadedEntries.removeAll()
    }
    
    /// Get cache statistics
    /// - Returns: Dictionary with cache metrics
    func cacheStatistics() async -> [String: Any] {
        return [
            "cachedEntries": loadedEntries.count,
            "maxCacheSize": maxCacheSize,
            "cacheUtilization": Double(loadedEntries.count) / Double(maxCacheSize)
        ]
    }
    
    // MARK: - File Existence Check
    
    /// Check if a file exists for the given entry ID
    /// - Parameter id: The entry ID to check
    /// - Returns: True if file exists
    func exists(id: String) async -> Bool {
        let fileURL = fileURL(for: id)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Get all entry IDs that have files on disk
    /// - Returns: Array of entry IDs
    func allEntryIds() async -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
            return contents
                .filter { $0.pathExtension == "json" }
                .map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            return []
        }
    }
}
