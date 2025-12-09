import Foundation

// MARK: - Builder Preferences

public struct BuilderPreferences: Codable, Equatable, Sendable {
    var customCompilerFlags: String
    var clearCacheOnBuild: Bool
    var optimizationLevel: OptimizationLevel
    var enableDebugSymbols: Bool
    var parallelBuild: Bool
    var buildOutputVerbosity: BuildVerbosity
    var autoLaunchAfterBuild: Bool
    
    enum OptimizationLevel: String, Codable, CaseIterable, Sendable {
        case none = "None"
        case speed = "Speed"
        case size = "Size"
        
        var compilerFlag: String {
            switch self {
            case .none: return "-Onone"
            case .speed: return "-O"
            case .size: return "-Osize"
            }
        }
        
        var description: String {
            switch self {
            case .none: return "No optimization (faster builds)"
            case .speed: return "Optimize for speed"
            case .size: return "Optimize for size"
            }
        }
    }
    
    enum BuildVerbosity: String, Codable, CaseIterable, Sendable {
        case quiet = "Quiet"
        case normal = "Normal"
        case verbose = "Verbose"
        
        var description: String {
            switch self {
            case .quiet: return "Show only errors"
            case .normal: return "Show warnings and errors"
            case .verbose: return "Show all build output"
            }
        }
    }
    
    init(
        customCompilerFlags: String = "",
        clearCacheOnBuild: Bool = false,
        optimizationLevel: OptimizationLevel = .none,
        enableDebugSymbols: Bool = true,
        parallelBuild: Bool = true,
        buildOutputVerbosity: BuildVerbosity = .normal,
        autoLaunchAfterBuild: Bool = false
    ) {
        self.customCompilerFlags = customCompilerFlags
        self.clearCacheOnBuild = clearCacheOnBuild
        self.optimizationLevel = optimizationLevel
        self.enableDebugSymbols = enableDebugSymbols
        self.parallelBuild = parallelBuild
        self.buildOutputVerbosity = buildOutputVerbosity
        self.autoLaunchAfterBuild = autoLaunchAfterBuild
    }
}
