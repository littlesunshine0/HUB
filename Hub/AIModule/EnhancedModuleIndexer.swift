//
//  EnhancedModuleIndexer.swift
//  Hub
//
//  Enhanced module indexer with detailed grouping following strict rules
//

import Foundation
import Combine

// MARK: - Enhanced Module Indexer

@MainActor
public class EnhancedModuleIndexer: ObservableObject {
    
    // MARK: - Generate Enhanced Index
    
    public func generateEnhancedIndex(fileName: String, content: String) -> String {
        var output = "# \(fileName) Module Index (Table of Contents)\n\n"
        
        let parser = SwiftParser(content: content)
        let structure = parser.parse()
        
        // Group by top-level declarations
        var sectionNumber = 1
        
        for topLevel in structure.topLevelDeclarations {
            output += "## \(sectionNumber). \(topLevel.name)\n\n"
            
            // Models section
            if !topLevel.enums.isEmpty || !topLevel.structs.isEmpty {
                output += "- **Models**\n"
                
                // Enums
                if !topLevel.enums.isEmpty {
                    output += "  - **Enums**\n"
                    for enumDecl in topLevel.enums {
                        output += "    - \(enumDecl.name)"
                        if !enumDecl.cases.isEmpty {
                            output += " (\(enumDecl.cases.joined(separator: ", ")))"
                        }
                        output += "\n"
                    }
                }
                
                // Structs
                if !topLevel.structs.isEmpty {
                    output += "  - **Structs**\n"
                    for structDecl in topLevel.structs {
                        output += "    - \(structDecl.name)\n"
                        
                        // Properties
                        if !structDecl.properties.isEmpty {
                            output += "      - **Variables/Properties:** \(structDecl.properties.joined(separator: ", "))\n"
                        }
                        
                        // Initializers
                        if !structDecl.initializers.isEmpty {
                            output += "      - **init**\(structDecl.initializers.first ?? "")\n"
                        }
                        
                        // Functions
                        if !structDecl.functions.isEmpty {
                            output += "      - **Functions:** \(structDecl.functions.joined(separator: ", "))\n"
                        }
                    }
                }
            }
            
            // Classes
            if !topLevel.classes.isEmpty {
                output += "- **Classes**\n"
                for classDecl in topLevel.classes {
                    output += "  - \(classDecl.name)"
                    if !classDecl.conformances.isEmpty {
                        output += ": \(classDecl.conformances.joined(separator: ", "))"
                    }
                    output += "\n"
                    
                    // Properties
                    if !classDecl.properties.isEmpty {
                        output += "    - **Variables/Properties:** \(classDecl.properties.joined(separator: ", "))\n"
                    }
                    
                    // Initializers
                    if !classDecl.initializers.isEmpty {
                        output += "    - **init**\(classDecl.initializers.first ?? "")\n"
                    }
                    
                    // Functions
                    if !classDecl.functions.isEmpty {
                        output += "    - **Functions:** \(classDecl.functions.joined(separator: ", "))\n"
                    }
                }
            }
            
            // Actors
            if !topLevel.actors.isEmpty {
                output += "- **Actors**\n"
                for actorDecl in topLevel.actors {
                    output += "  - \(actorDecl.name)\n"
                    if !actorDecl.functions.isEmpty {
                        output += "    - **Functions:** \(actorDecl.functions.joined(separator: ", "))\n"
                    }
                }
            }
            
            output += "\n"
            sectionNumber += 1
        }
        
        return output
    }
}

// MARK: - Swift Parser

public class SwiftParser {
    private let content: String
    private let lines: [String]
    
    public init(content: String) {
        self.content = content
        self.lines = content.components(separatedBy: .newlines)
    }
    
    public func parse() -> ParsedStructure {
        var structure = ParsedStructure()
        var currentTopLevel: TopLevelDeclaration?
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Top-level file name detection
            if trimmed.hasPrefix("//") && trimmed.contains(".swift") {
                if let current = currentTopLevel {
                    structure.topLevelDeclarations.append(current)
                }
                let fileName = extractFileName(from: trimmed)
                currentTopLevel = TopLevelDeclaration(name: fileName)
            }
            
            // Parse declarations
            if let enumDecl = parseEnum(line: trimmed, startIndex: index) {
                currentTopLevel?.enums.append(enumDecl)
            }
            
            if let structDecl = parseStruct(line: trimmed, startIndex: index) {
                currentTopLevel?.structs.append(structDecl)
            }
            
            if let classDecl = parseClass(line: trimmed, startIndex: index) {
                currentTopLevel?.classes.append(classDecl)
            }
            
            if let actorDecl = parseActor(line: trimmed, startIndex: index) {
                currentTopLevel?.actors.append(actorDecl)
            }
        }
        
        if let current = currentTopLevel {
            structure.topLevelDeclarations.append(current)
        }
        
        return structure
    }
    
    private func extractFileName(from line: String) -> String {
        let components = line.components(separatedBy: .whitespaces)
        for component in components {
            if component.hasSuffix(".swift") {
                return component
            }
        }
        return "Unknown"
    }
    
    private func parseEnum(line: String, startIndex: Int) -> EnumDeclaration? {
        guard line.contains("enum ") else { return nil }
        
        let name = extractTypeName(from: line, keyword: "enum")
        let cases = extractEnumCases(startingAt: startIndex)
        
        return EnumDeclaration(name: name, cases: cases)
    }
    
    private func parseStruct(line: String, startIndex: Int) -> StructDeclaration? {
        guard line.contains("struct ") else { return nil }
        
        let name = extractTypeName(from: line, keyword: "struct")
        let properties = extractProperties(startingAt: startIndex)
        let functions = extractFunctions(startingAt: startIndex)
        let initializers = extractInitializers(startingAt: startIndex)
        
        return StructDeclaration(
            name: name,
            properties: properties,
            functions: functions,
            initializers: initializers
        )
    }
    
    private func parseClass(line: String, startIndex: Int) -> ClassDeclaration? {
        guard line.contains("class ") else { return nil }
        
        let name = extractTypeName(from: line, keyword: "class")
        let conformances = extractConformances(from: line)
        let properties = extractProperties(startingAt: startIndex)
        let functions = extractFunctions(startingAt: startIndex)
        let initializers = extractInitializers(startingAt: startIndex)
        
        return ClassDeclaration(
            name: name,
            conformances: conformances,
            properties: properties,
            functions: functions,
            initializers: initializers
        )
    }
    
    private func parseActor(line: String, startIndex: Int) -> ActorDeclaration? {
        guard line.contains("actor ") else { return nil }
        
        let name = extractTypeName(from: line, keyword: "actor")
        let functions = extractFunctions(startingAt: startIndex)
        
        return ActorDeclaration(name: name, functions: functions)
    }
    
    private func extractTypeName(from line: String, keyword: String) -> String {
        guard let range = line.range(of: keyword + " ") else { return "" }
        let afterKeyword = String(line[range.upperBound...])
        let components = afterKeyword.components(separatedBy: CharacterSet(charactersIn: " :<{"))
        return components.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    private func extractConformances(from line: String) -> [String] {
        guard let colonIndex = line.firstIndex(of: ":") else { return [] }
        let afterColon = String(line[line.index(after: colonIndex)...])
        let beforeBrace = afterColon.components(separatedBy: "{").first ?? ""
        return beforeBrace.components(separatedBy: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty }
    }
    
    private func extractEnumCases(startingAt index: Int) -> [String] {
        var cases: [String] = []
        var braceCount = 0
        var started = false
        
        for i in index..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line.contains("{") {
                braceCount += 1
                started = true
            }
            
            if started && line.hasPrefix("case ") {
                let caseName = line
                    .replacingOccurrences(of: "case ", with: "")
                    .components(separatedBy: CharacterSet(charactersIn: " =({"))
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                if !caseName.isEmpty {
                    cases.append(caseName)
                }
            }
            
            if line.contains("}") {
                braceCount -= 1
                if braceCount == 0 { break }
            }
        }
        
        return cases
    }
    
    private func extractProperties(startingAt index: Int) -> [String] {
        var properties: [String] = []
        var braceCount = 0
        var started = false
        
        for i in index..<min(index + 50, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line.contains("{") { braceCount += 1; started = true }
            if line.contains("}") { braceCount -= 1 }
            if braceCount == 0 && started { break }
            
            if started && (line.contains("var ") || line.contains("let ")) {
                if let propName = extractPropertyName(from: line) {
                    properties.append(propName)
                }
            }
        }
        
        return properties
    }
    
    private func extractFunctions(startingAt index: Int) -> [String] {
        var functions: [String] = []
        var braceCount = 0
        var started = false
        
        for i in index..<min(index + 100, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line.contains("{") { braceCount += 1; started = true }
            if line.contains("}") { braceCount -= 1 }
            if braceCount == 0 && started { break }
            
            if started && line.contains("func ") {
                if let funcName = extractFunctionName(from: line) {
                    functions.append(funcName)
                }
            }
        }
        
        return functions
    }
    
    private func extractInitializers(startingAt index: Int) -> [String] {
        var initializers: [String] = []
        var braceCount = 0
        var started = false
        
        for i in index..<min(index + 50, lines.count) {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line.contains("{") { braceCount += 1; started = true }
            if line.contains("}") { braceCount -= 1 }
            if braceCount == 0 && started { break }
            
            if started && line.contains("init") {
                let params = extractInitParams(from: line)
                initializers.append(params)
            }
        }
        
        return initializers
    }
    
    private func extractPropertyName(from line: String) -> String? {
        let keyword = line.contains("var ") ? "var " : "let "
        guard let range = line.range(of: keyword) else { return nil }
        let afterKeyword = String(line[range.upperBound...])
        let components = afterKeyword.components(separatedBy: CharacterSet(charactersIn: " :="))
        return components.first?.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractFunctionName(from line: String) -> String? {
        guard let range = line.range(of: "func ") else { return nil }
        let afterFunc = String(line[range.upperBound...])
        let components = afterFunc.components(separatedBy: CharacterSet(charactersIn: "(<"))
        return components.first?.trimmingCharacters(in: .whitespaces)
    }
    
    private func extractInitParams(from line: String) -> String {
        guard let startParen = line.firstIndex(of: "("),
              let endParen = line.lastIndex(of: ")") else {
            return "()"
        }
        return String(line[startParen...endParen])
    }
}

// MARK: - Parsed Structure Models

public struct ParsedStructure {
    public var topLevelDeclarations: [TopLevelDeclaration] = []
}

public struct TopLevelDeclaration {
    public let name: String
    public var enums: [EnumDeclaration] = []
    public var structs: [StructDeclaration] = []
    public var classes: [ClassDeclaration] = []
    public var actors: [ActorDeclaration] = []
}

public struct EnumDeclaration {
    public let name: String
    public let cases: [String]
}

public struct StructDeclaration {
    public let name: String
    public let properties: [String]
    public let functions: [String]
    public let initializers: [String]
}

public struct ClassDeclaration {
    public let name: String
    public let conformances: [String]
    public let properties: [String]
    public let functions: [String]
    public let initializers: [String]
}

public struct ActorDeclaration {
    public let name: String
    public let functions: [String]
}

