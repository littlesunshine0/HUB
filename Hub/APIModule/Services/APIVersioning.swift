//
//  APIVersioning.swift
//  Hub
//
//  API versioning and compatibility management
//

import Foundation

// MARK: - API Version

public struct APIVersion: Comparable, Codable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    
    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    public init?(string: String) {
        let components = string.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        self.major = components[0]
        self.minor = components[1]
        self.patch = components[2]
    }
    
    public var string: String {
        "\(major).\(minor).\(patch)"
    }
    
    public static func < (lhs: APIVersion, rhs: APIVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
    
    public func isCompatible(with version: APIVersion) -> Bool {
        // Major version must match for compatibility
        return self.major == version.major
    }
}

// MARK: - Version Manager

public class APIVersionManager {
    public static let shared = APIVersionManager()
    
    public let currentVersion = APIVersion(major: 1, minor: 0, patch: 0)
    public let minimumSupportedVersion = APIVersion(major: 1, minor: 0, patch: 0)
    
    private var deprecatedEndpoints: [String: APIVersion] = [:]
    private var removedEndpoints: [String: APIVersion] = [:]
    
    private init() {}
    
    // MARK: - Version Checking
    
    public func checkCompatibility(clientVersion: APIVersion) throws {
        guard clientVersion >= minimumSupportedVersion else {
            throw APIError(
                code: "VERSION_TOO_OLD",
                message: "Client version \(clientVersion.string) is no longer supported. Minimum version: \(minimumSupportedVersion.string)"
            )
        }
        
        guard clientVersion.isCompatible(with: currentVersion) else {
            throw APIError(
                code: "VERSION_INCOMPATIBLE",
                message: "Client version \(clientVersion.string) is not compatible with server version \(currentVersion.string)"
            )
        }
    }
    
    // MARK: - Deprecation Management
    
    public func markDeprecated(endpoint: String, since version: APIVersion) {
        deprecatedEndpoints[endpoint] = version
    }
    
    public func markRemoved(endpoint: String, in version: APIVersion) {
        removedEndpoints[endpoint] = version
    }
    
    public func isDeprecated(endpoint: String) -> Bool {
        return deprecatedEndpoints[endpoint] != nil
    }
    
    public func isRemoved(endpoint: String, in version: APIVersion) -> Bool {
        guard let removedVersion = removedEndpoints[endpoint] else {
            return false
        }
        return version >= removedVersion
    }
    
    public func getDeprecationWarning(for endpoint: String) -> String? {
        guard let deprecatedVersion = deprecatedEndpoints[endpoint] else {
            return nil
        }
        return "Endpoint '\(endpoint)' has been deprecated since version \(deprecatedVersion.string)"
    }
}

// MARK: - Version Negotiation

public struct VersionNegotiator {
    public static func negotiate(
        clientVersion: APIVersion,
        serverVersion: APIVersion
    ) -> APIVersion? {
        // Use the lower version that's still compatible
        if clientVersion.isCompatible(with: serverVersion) {
            return min(clientVersion, serverVersion)
        }
        return nil
    }
    
    public static func selectBestVersion(
        clientVersions: [APIVersion],
        serverVersions: [APIVersion]
    ) -> APIVersion? {
        // Find the highest compatible version
        let compatibleVersions = clientVersions.filter { clientVersion in
            serverVersions.contains { serverVersion in
                clientVersion.isCompatible(with: serverVersion)
            }
        }
        
        return compatibleVersions.max()
    }
}

// MARK: - Migration Support

public protocol APIMigration {
    var fromVersion: APIVersion { get }
    var toVersion: APIVersion { get }
    
    func migrate(request: Any) throws -> Any
    func migrate(response: Any) throws -> Any
}

public class MigrationManager {
    public static let shared = MigrationManager()
    
    private var migrations: [APIMigration] = []
    
    private init() {}
    
    public func register(migration: APIMigration) {
        migrations.append(migration)
    }
    
    public func migrate(
        request: Any,
        from: APIVersion,
        to: APIVersion
    ) throws -> Any {
        var current = request
        var currentVersion = from
        
        while currentVersion < to {
            guard let migration = findMigration(from: currentVersion, to: to) else {
                throw APIError(
                    code: "NO_MIGRATION_PATH",
                    message: "No migration path from \(currentVersion.string) to \(to.string)"
                )
            }
            
            current = try migration.migrate(request: current)
            currentVersion = migration.toVersion
        }
        
        return current
    }
    
    private func findMigration(from: APIVersion, to: APIVersion) -> APIMigration? {
        return migrations.first { migration in
            migration.fromVersion == from && migration.toVersion <= to
        }
    }
}
