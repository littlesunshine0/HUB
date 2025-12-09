import Foundation
import SwiftUI
import Combine

public class HubBuilderService {
    public static let shared = HubBuilderService()
    
    private var achievementTracker: CodeGeneratorAchievementTracker?
    
    private init() {}
    
    // MARK: - Configuration
    
    public func setAchievementTracker(_ tracker: CodeGeneratorAchievementTracker) {
        self.achievementTracker = tracker
    }
    
    /// Loads a Swift file from the project directory
    static func loadSwiftFile(named filename: String, inDirectory directory: String = "Hub") -> String? {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let filePath = (currentPath as NSString).appendingPathComponent("\(directory)/\(filename)")
        
        return try? String(contentsOfFile: filePath, encoding: .utf8)
    }
    
    // MARK: - Hub Creation
    
    func createHub(templateID: UUID, templateName: String, name: String, icon: String, customization: HubCustomization, userID: String) -> AppHub {
        let hub = AppHub(
            name: name,
            description: customization.appName,
            icon: icon,
            category: .development,
            templateID: templateID,
            templateName: templateName,
            customization: customization,
            userID: userID
        )
        
        // Track customization achievements
        if !customization.primaryColor.isEmpty || !customization.accentColor.isEmpty {
            achievementTracker?.trackCustomization(type: "colors")
        }
        
        return hub
    }
    
    // MARK: - Code Generation
    
    func generateAppCode(for hub: AppHub, template: TemplateModel) -> [String: String] {
        guard let customization = hub.customization else {
            return ["main.swift": "// Error: No customization data found"]
        }
        
        var customizedFiles: [String: String] = [:]
        
        // Check if this is a visual template
        if template.isVisualTemplate {
            let appName = customization.appName
            let bundleID = customization.bundleIdentifier
            
            // Use multi-screen generator if screens exist
            if !template.visualScreens.isEmpty {
                let generatedFiles = EnhancedCodeGenerator.shared.generateApp(
                    from: template.visualScreens,
                    branding: template.branding,
                    appName: appName,
                    bundleIdentifier: bundleID
                )
                customizedFiles.merge(generatedFiles) { _, new in new }
            } else if !template.visualLayout.isEmpty {
                // Fallback to legacy single-screen generator
                let generatedCode = VisualCodeGenerator.shared.generateApp(
                    from: template.visualLayout,
                    appName: appName,
                    bundleIdentifier: bundleID
                )
                customizedFiles["main.swift"] = generatedCode
            }
        } else {
            // Use traditional code-based approach
            for (filename, code) in template.sourceFiles {
                let customizedCode = applyCustomizations(to: code, customization: customization, features: template.features, featureToggles: template.featureToggles)
                customizedFiles[filename] = customizedCode
            }
        }
        
        // Add shared modules
        let sharedModules = SharedModuleLibrary.shared.getModules(byIds: template.sharedModules)
        for module in sharedModules {
            let filename = "\(module.id).swift"
            customizedFiles[filename] = module.sourceCode
        }
        
        return customizedFiles
    }
    
    /// Applies customizations to generated code including colors and feature toggles
    private func applyCustomizations(to code: String, customization: HubCustomization, features: [String], featureToggles: [String: Bool]) -> String {
        var customizedCode = code
        
        // 1. Apply color customizations
        if customizedCode.contains("WindowGroup {") {
            if let accentColorHex = customization.accentColor as String?, !accentColorHex.isEmpty {
                // Find the first View() after WindowGroup and add tint modifier
                if let viewRange = customizedCode.range(of: "View\\(\\)", options: .regularExpression) {
                    let insertPoint = customizedCode.index(viewRange.upperBound, offsetBy: 0)
                    customizedCode.insert(contentsOf: "\n                        .tint(Color(hex: \"\(accentColorHex)\"))", at: insertPoint)
                }
            }
        }
        
        // 2. Apply feature toggles from user customization (highest priority)
        for (featureName, isEnabled) in customization.features {
            if !isEnabled {
                customizedCode = removeFeature(featureName, from: customizedCode)
            }
        }
        
        // 3. Apply template-level feature toggles (fallback)
        for (featureName, isEnabled) in featureToggles {
            if !isEnabled {
                customizedCode = removeFeature(featureName, from: customizedCode)
            }
        }
        
        return customizedCode
    }
    
    /// Removes a feature from the code based on feature markers
    private func removeFeature(_ featureName: String, from code: String) -> String {
        var modifiedCode = code
        
        // Look for feature markers like // FEATURE:Linter or /* FEATURE:Linter */
        let startMarker = "// FEATURE:\(featureName):START"
        let endMarker = "// FEATURE:\(featureName):END"
        
        if let startRange = modifiedCode.range(of: startMarker),
           let endRange = modifiedCode.range(of: endMarker) {
            // Remove the entire block between markers
            let removalRange = startRange.lowerBound..<endRange.upperBound
            modifiedCode.removeSubrange(removalRange)
        } else {
            // Fallback: Comment out specific function calls
            switch featureName {
            case "Linter":
                modifiedCode = modifiedCode.replacingOccurrences(
                    of: "let issues = UnifiedSystem.Analysis.UnifiedLinter.lintCode",
                    with: "// let issues = UnifiedSystem.Analysis.UnifiedLinter.lintCode"
                )
                modifiedCode = modifiedCode.replacingOccurrences(
                    of: "issues: issues,",
                    with: "issues: [],"
                )
            case "Parser":
                modifiedCode = modifiedCode.replacingOccurrences(
                    of: "let ast = UnifiedSystem.Analysis.UniversalCodeParser.parse",
                    with: "// let ast = UnifiedSystem.Analysis.UniversalCodeParser.parse"
                )
            case "Metrics":
                modifiedCode = modifiedCode.replacingOccurrences(
                    of: "let metric = UnifiedSystem.Analysis.ComplexityAnalyzer.analyzeComplexity",
                    with: "// let metric = UnifiedSystem.Analysis.ComplexityAnalyzer.analyzeComplexity"
                )
                modifiedCode = modifiedCode.replacingOccurrences(
                    of: "metrics: [metric]",
                    with: "metrics: []"
                )
            default:
                break
            }
        }
        
        return modifiedCode
    }
    
    /// Generates color modifier code for the app
    private func generateColorModifiers(for customization: HubCustomization) -> String {
        var modifiers = ""
        
        if !customization.accentColor.isEmpty {
            modifiers += "\n                        .tint(Color(hex: \"\(customization.accentColor)\"))"
        }
        
        return modifiers
    }
    

    // MARK: - Build & Launch
    
    /// Builds the hub into a private temporary location and returns the path
    func buildApp(hub: AppHub, template: TemplateModel) async throws -> String {
        guard let customization = hub.customization else {
            throw NSError(domain: "HubBuilderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No customization data found"])
        }
        
        let appName = customization.appName
        let startTime = Date()
        
        // Create a private build directory in Application Support
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let hubBuildsURL = appSupportURL.appendingPathComponent("Hub/Builds", isDirectory: true)
        try fileManager.createDirectory(at: hubBuildsURL, withIntermediateDirectories: true)
        
        // Build to this private location
        try await exportAsApp(hub: hub, template: template, to: hubBuildsURL)
        
        let builtAppURL = hubBuildsURL.appendingPathComponent("\(appName).app")
        
        // Track achievements
        let buildTime = Date().timeIntervalSince(startTime)
        achievementTracker?.trackAppBuilt(
            isVisual: template.isVisualTemplate,
            screenCount: template.visualScreens.count
        )
        achievementTracker?.trackSuccessfulBuild(buildTime: buildTime)
        achievementTracker?.trackBuildTime()
        
        return builtAppURL.path
    }
    
    /// Launches a built app from its path
    func launchApp(at path: String) throws {
        let appURL = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: path) else {
            throw NSError(domain: "HubBuilderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "App not found at path"])
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            if let error = error {
                print("Failed to launch app: \(error.localizedDescription)")
            }
        }
    }
    
    /// Exports (copies) a built app to a user-selected location
    func exportBuiltApp(from sourcePath: String, to destinationURL: URL) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let appName = sourceURL.lastPathComponent
        let destinationAppURL = destinationURL.appendingPathComponent(appName)
        
        let fileManager = FileManager.default
        
        // Remove existing app at destination if it exists
        if fileManager.fileExists(atPath: destinationAppURL.path) {
            try fileManager.removeItem(at: destinationAppURL)
        }
        
        // Copy the app
        try fileManager.copyItem(at: sourceURL, to: destinationAppURL)
        
        print("Successfully exported app to: \(destinationAppURL.path)")
    }
    
    // MARK: - Export to .app
    
    /// Exports the hub as a fully compiled, runnable macOS application.
    /// This creates the app bundle structure, generates Swift code, and compiles it into an executable.
    func exportAsApp(hub: AppHub, template: TemplateModel, to destinationURL: URL) async throws {
        guard let customization = hub.customization else {
            throw NSError(domain: "HubBuilderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No customization data found"])
        }
        
        let appName = customization.appName
        let sanitizedAppName = appName.replacingOccurrences(of: " ", with: "")
        let bundleIdentifier = customization.bundleIdentifier
        
        // Create app bundle structure
        let appBundleURL = destinationURL.appendingPathComponent("\(appName).app")
        let contentsURL = appBundleURL.appendingPathComponent("Contents")
        let macOSURL = contentsURL.appendingPathComponent("MacOS")
        let resourcesURL = contentsURL.appendingPathComponent("Resources")
        
        // Clean up existing bundle if it exists
        if FileManager.default.fileExists(atPath: appBundleURL.path) {
            try FileManager.default.removeItem(at: appBundleURL)
        }
        
        try FileManager.default.createDirectory(at: macOSURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
        
        // Write branding assets
        for (filename, data) in template.branding.assets {
            let assetURL = resourcesURL.appendingPathComponent(filename)
            try data.write(to: assetURL)
        }
        
        // Write app icon if provided
        if let iconData = template.branding.appIconData {
            try writeAppIcon(from: iconData, to: resourcesURL)
        }
        
        // Generate Info.plist
        let infoPlist = generateInfoPlist(appName: sanitizedAppName, bundleIdentifier: bundleIdentifier)
        try infoPlist.write(to: contentsURL.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        
        // Generate Swift source files (can be multiple files now)
        let sourceFiles = generateAppCode(for: hub, template: template)
        var sourceFileURLs: [URL] = []
        
        for (filename, code) in sourceFiles {
            let sourceFileURL = macOSURL.appendingPathComponent(filename)
            try code.write(to: sourceFileURL, atomically: true, encoding: .utf8)
            sourceFileURLs.append(sourceFileURL)
        }
        
        // Add Color+Hex extension if customizations use hex colors
        if !customization.accentColor.isEmpty || !customization.primaryColor.isEmpty {
            let colorExtension = generateColorExtension()
            let colorExtensionURL = macOSURL.appendingPathComponent("Color+Hex.swift")
            try colorExtension.write(to: colorExtensionURL, atomically: true, encoding: .utf8)
            sourceFileURLs.append(colorExtensionURL)
        }
        
        // Get dependencies from template
        let dependencies = template.dependencies
        
        // Compile the Swift code into an executable
        let executableURL = macOSURL.appendingPathComponent(sanitizedAppName)
        try await compileSwiftCode(sourceFiles: sourceFileURLs, outputExecutable: executableURL, dependencies: dependencies)
        
        // Remove the source files after compilation
        for sourceFileURL in sourceFileURLs {
            try? FileManager.default.removeItem(at: sourceFileURL)
        }
        
        print("Successfully exported runnable app to: \(appBundleURL.path)")
    }
    
    /// Generates a Color+Hex extension for hex color support
    private func generateColorExtension() -> String {
        return """
        import SwiftUI
        
        extension Color {
            init?(hex: String) {
                var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
                
                var rgb: UInt64 = 0
                
                guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
                    return nil
                }
                
                let r = Double((rgb & 0xFF0000) >> 16) / 255.0
                let g = Double((rgb & 0x00FF00) >> 8) / 255.0
                let b = Double(rgb & 0x0000FF) / 255.0
                
                self.init(red: r, green: g, blue: b)
            }
        }
        """
    }
    
    /// Compiles Swift source code into a macOS executable using swiftc
    private func compileSwiftCode(sourceFiles: [URL], outputExecutable: URL, dependencies: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
        
        // Get current architecture dynamically
        let architecture = try getCurrentArchitecture()
        let sdkPath = try getSDKPath()
        
        // Build compilation arguments
        var arguments: [String] = []
        
        // Add all source files
        for sourceFile in sourceFiles {
            arguments.append(sourceFile.path)
        }
        
        // Output executable
        arguments.append(contentsOf: ["-o", outputExecutable.path])
        
        // Target architecture (dynamic based on current system)
        arguments.append(contentsOf: ["-target", "\(architecture)-apple-macos14.0"])
        
        // SDK path
        arguments.append(contentsOf: ["-sdk", sdkPath])
        
        // Base frameworks
        let baseFrameworks = ["SwiftUI", "Foundation", "AppKit", "Combine"]
        for framework in baseFrameworks {
            arguments.append(contentsOf: ["-framework", framework])
        }
        
        // Add template-specific dependencies
        for dependency in dependencies {
            arguments.append(contentsOf: ["-framework", dependency])
        }
        
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown compilation error"
            throw NSError(
                domain: "HubBuilderService",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Compilation failed: \(errorMessage)"]
            )
        }
        
        // Make the executable... executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: outputExecutable.path
        )
    }
    
    /// Gets the current system architecture (arm64 or x86_64)
    private func getCurrentArchitecture() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/uname")
        process.arguments = ["-m"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let arch = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !arch.isEmpty else {
            throw NSError(
                domain: "HubBuilderService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not determine system architecture"]
            )
        }
        
        return arch
    }
    
    /// Gets the macOS SDK path for compilation
    private func getSDKPath() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--sdk", "macosx", "--show-sdk-path"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let sdkPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !sdkPath.isEmpty else {
            throw NSError(
                domain: "HubBuilderService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not find macOS SDK path"]
            )
        }
        
        return sdkPath
    }
    
    private func generateInfoPlist(appName: String, bundleIdentifier: String) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>en</string>
            <key>CFBundleExecutable</key>
            <string>\(appName)</string>
            <key>CFBundleIdentifier</key>
            <string>\(bundleIdentifier)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>\(appName)</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>LSMinimumSystemVersion</key>
            <string>14.0</string>
            <key>CFBundleIconFile</key>
            <string>AppIcon</string>
        </dict>
        </plist>
        """
    }
    
    /// Writes app icon to the Resources directory with proper iconset structure
    private func writeAppIcon(from data: Data, to resourcesURL: URL) throws {
        guard let nsImage = NSImage(data: data) else {
            throw NSError(domain: "HubBuilderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        // Create AppIcon.appiconset directory
        let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.appiconset")
        try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
        
        // Icon sizes for macOS
        let sizes: [(size: Int, scale: Int, idiom: String)] = [
            (16, 1, "mac"),
            (16, 2, "mac"),
            (32, 1, "mac"),
            (32, 2, "mac"),
            (128, 1, "mac"),
            (128, 2, "mac"),
            (256, 1, "mac"),
            (256, 2, "mac"),
            (512, 1, "mac"),
            (512, 2, "mac")
        ]
        
        var contentsJSON = """
        {
          "images" : [
        """
        
        for (index, sizeInfo) in sizes.enumerated() {
            let pixelSize = sizeInfo.size * sizeInfo.scale
            let filename = "icon_\(sizeInfo.size)x\(sizeInfo.size)@\(sizeInfo.scale)x.png"
            
            // Resize and save image
            if let resizedImage = resizeImage(nsImage, to: CGSize(width: pixelSize, height: pixelSize)),
               let pngData = resizedImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: pngData),
               let finalData = bitmap.representation(using: .png, properties: [:]) {
                let fileURL = iconsetURL.appendingPathComponent(filename)
                try finalData.write(to: fileURL)
            }
            
            // Add to Contents.json
            contentsJSON += """
            
                {
                  "filename" : "\(filename)",
                  "idiom" : "\(sizeInfo.idiom)",
                  "scale" : "\(sizeInfo.scale)x",
                  "size" : "\(sizeInfo.size)x\(sizeInfo.size)"
                }
            """
            
            if index < sizes.count - 1 {
                contentsJSON += ","
            }
        }
        
        contentsJSON += """
        
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        
        // Write Contents.json
        let contentsURL = iconsetURL.appendingPathComponent("Contents.json")
        try contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)
    }
    
    /// Resizes an NSImage to the specified size
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
    // MARK: - Cache Management
    
    /// Clears the builds directory to free up disk space
    func clearBuildsDirectory() throws {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let hubBuildsURL = appSupportURL.appendingPathComponent("Hub/Builds", isDirectory: true)
        
        guard fileManager.fileExists(atPath: hubBuildsURL.path) else {
            // Directory doesn't exist, nothing to clear
            return
        }
        
        // Get all items in the builds directory
        let items = try fileManager.contentsOfDirectory(at: hubBuildsURL, includingPropertiesForKeys: nil)
        
        // Remove each item
        for item in items {
            try fileManager.removeItem(at: item)
        }
        
        print("Cleared \(items.count) items from builds directory")
    }
    
    /// Gets the size of the builds directory in bytes
    func getBuildsDirectorySize() throws -> Int64 {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let hubBuildsURL = appSupportURL.appendingPathComponent("Hub/Builds", isDirectory: true)
        
        guard fileManager.fileExists(atPath: hubBuildsURL.path) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        let items = try fileManager.contentsOfDirectory(at: hubBuildsURL, includingPropertiesForKeys: [.fileSizeKey])
        
        for item in items {
            let attributes = try fileManager.attributesOfItem(atPath: item.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}
