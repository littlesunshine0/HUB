//
//  ModuleIndexGenerator.swift
//  Hub
//
//  Automatic module index generation with detailed grouping and ownership
//

import Foundation
import Combine

// MARK: - Module Index Generator

@MainActor
public class ModuleIndexGenerator: ObservableObject {
    
    @Published public var generatedIndexes: [String: ModuleIndex] = [:]
    
    // MARK: - Generate Index
    
    public func generateIndex(for filePath: String, content: String) -> ModuleIndex {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        
        var index = ModuleIndex(fileName: fileName, filePath: filePath)
        
        // Parse content
        let lines = content.components(separatedBy: .newlines)
        var currentSection: IndexSection?
        var currentOwner: String?
        let _ = 0 // indentLevel - reserved for future use
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Detect section markers
            if trimmed.hasPrefix("// MARK: -") {
                let sectionName = trimmed
                    .replacingOccurrences(of: "// MARK: -", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if let section = currentSection {
                    index.sections.append(section)
                }
                
                currentSection = IndexSection(name: sectionName)
                currentOwner = nil
            }
            
            // Detect ownership comments
            if trimmed.hasPrefix("// Owner:") || trimmed.hasPrefix("// Owned by:") {
                currentOwner = trimmed
                    .replacingOccurrences(of: "// Owner:", with: "")
                    .replacingOccurrences(of: "// Owned by:", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            
            // Parse declarations
            if let declaration = parseDeclaration(line: trimmed) {
                var entry = declaration
                entry.owner = currentOwner
                currentSection?.entries.append(entry)
            }
        }
        
        // Add final section
        if let section = currentSection {
            index.sections.append(section)
        }
        
        generatedIndexes[fileName] = index
        return index
    }
    
    // MARK: - Parse Declaration
    
    private func parseDeclaration(line: String) -> IndexEntry? {
        // Enum
        if line.hasPrefix("public enum ") || line.hasPrefix("enum ") {
            let name = extractName(from: line, after: "enum ")
            return IndexEntry(type: .enum, name: name, signature: line)
        }
        
        // Struct
        if line.hasPrefix("public struct ") || line.hasPrefix("struct ") {
            let name = extractName(from: line, after: "struct ")
            return IndexEntry(type: .struct, name: name, signature: line)
        }
        
        // Class
        if line.hasPrefix("public class ") || line.hasPrefix("class ") {
            let name = extractName(from: line, after: "class ")
            return IndexEntry(type: .class, name: name, signature: line)
        }
        
        // Actor
        if line.hasPrefix("public actor ") || line.hasPrefix("actor ") {
            let name = extractName(from: line, after: "actor ")
            return IndexEntry(type: .actor, name: name, signature: line)
        }
        
        // Protocol
        if line.hasPrefix("public protocol ") || line.hasPrefix("protocol ") {
            let name = extractName(from: line, after: "protocol ")
            return IndexEntry(type: .protocol, name: name, signature: line)
        }
        
        // Function
        if line.contains("func ") {
            let name = extractFunctionName(from: line)
            return IndexEntry(type: .function, name: name, signature: line)
        }
        
        // Variable/Property
        if line.contains("var ") || line.contains("let ") {
            let name = extractVariableName(from: line)
            return IndexEntry(type: .property, name: name, signature: line)
        }
        
        return nil
    }
    
    // MARK: - Name Extraction
    
    private func extractName(from line: String, after keyword: String) -> String {
        guard let range = line.range(of: keyword) else { return "" }
        let afterKeyword = String(line[range.upperBound...])
        let components = afterKeyword.components(separatedBy: CharacterSet(charactersIn: " :<{"))
        return components.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    private func extractFunctionName(from line: String) -> String {
        guard let range = line.range(of: "func ") else { return "" }
        let afterFunc = String(line[range.upperBound...])
        let components = afterFunc.components(separatedBy: CharacterSet(charactersIn: "(<"))
        return components.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    private func extractVariableName(from line: String) -> String {
        let keyword = line.contains("var ") ? "var " : "let "
        guard let range = line.range(of: keyword) else { return "" }
        let afterKeyword = String(line[range.upperBound...])
        let components = afterKeyword.components(separatedBy: CharacterSet(charactersIn: " :="))
        return components.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    // MARK: - Format Output
    
    public func formatAsMarkdown(_ index: ModuleIndex) -> String {
        var output = "# \(index.fileName) Module Index\n\n"
        output += "**File:** `\(index.filePath)`\n\n"
        output += "---\n\n"
        
        // Group by type
        let groupedByType = Dictionary(grouping: index.allEntries) { $0.type }
        
        // Models section
        if !groupedByType[.enum, default: []].isEmpty ||
           !groupedByType[.struct, default: []].isEmpty {
            output += "## Models\n\n"
            
            // Enums
            if !groupedByType[.enum, default: []].isEmpty {
                output += "### Enums\n\n"
                for entry in groupedByType[.enum, default: []] {
                    output += "- **\(entry.name)**"
                    if let owner = entry.owner {
                        output += " _(Owner: \(owner))_"
                    }
                    output += "\n"
                }
                output += "\n"
            }
            
            // Structs
            if !groupedByType[.struct, default: []].isEmpty {
                output += "### Structs\n\n"
                for entry in groupedByType[.struct, default: []] {
                    output += "- **\(entry.name)**"
                    if let owner = entry.owner {
                        output += " _(Owner: \(owner))_"
                    }
                    output += "\n"
                }
                output += "\n"
            }
        }
        
        // Classes section
        if !groupedByType[.class, default: []].isEmpty {
            output += "## Classes\n\n"
            for entry in groupedByType[.class, default: []] {
                output += "### \(entry.name)\n\n"
                if let owner = entry.owner {
                    output += "**Owner:** \(owner)\n\n"
                }
            }
        }
        
        // Actors section
        if !groupedByType[.actor, default: []].isEmpty {
            output += "## Actors\n\n"
            for entry in groupedByType[.actor, default: []] {
                output += "### \(entry.name)\n\n"
                if let owner = entry.owner {
                    output += "**Owner:** \(owner)\n\n"
                }
            }
        }
        
        // Functions section
        if !groupedByType[.function, default: []].isEmpty {
            output += "## Functions\n\n"
            for entry in groupedByType[.function, default: []] {
                output += "- `\(entry.name)()`"
                if let owner = entry.owner {
                    output += " _(Owner: \(owner))_"
                }
                output += "\n"
            }
            output += "\n"
        }
        
        return output
    }
    
    // MARK: - Batch Generation
    
    public func generateIndexesForDirectory(_ directoryPath: String) async -> [ModuleIndex] {
        var indexes: [ModuleIndex] = []

        // Helper to collect Swift files synchronously, recursively
        func collectSwiftFiles(at url: URL) -> [String] {
            var results: [String] = []
            let fileManager = FileManager.default
            do {
                let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
                for item in items {
                    do {
                        let values = try item.resourceValues(forKeys: [.isDirectoryKey])
                        if values.isDirectory == true {
                            results.append(contentsOf: collectSwiftFiles(at: item))
                        } else if item.pathExtension == "swift" {
                            results.append(item.path)
                        }
                    } catch {
                        // Ignore individual item errors and continue
                        continue
                    }
                }
            } catch {
                // Ignore directory read errors and return what we have
            }
            return results
        }

        let rootURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
        let swiftFilePaths = collectSwiftFiles(at: rootURL)

        for fullPath in swiftFilePaths {
            if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                let index = generateIndex(for: fullPath, content: content)
                indexes.append(index)
            }
        }

        return indexes
    }
}

// MARK: - Models

public struct ModuleIndex {
    public let fileName: String
    public let filePath: String
    public var sections: [IndexSection] = []
    
    public var allEntries: [IndexEntry] {
        sections.flatMap { $0.entries }
    }
}

public struct IndexSection {
    public let name: String
    public var entries: [IndexEntry] = []
}

public struct IndexEntry {
    public let type: EntryType
    public let name: String
    public let signature: String
    public var owner: String?
    public var children: [IndexEntry] = []
}

public enum EntryType: String {
    case `enum` = "Enum"
    case `struct` = "Struct"
    case `class` = "Class"
    case actor = "Actor"
    case `protocol` = "Protocol"
    case function = "Function"
    case property = "Property"
    case variable = "Variable"
}
