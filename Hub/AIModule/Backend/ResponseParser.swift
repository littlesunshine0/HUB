//
//  ResponseParser.swift
//  Hub
//
//  Parse AI responses for tool calls, code blocks, and structured content
//

import Foundation

// MARK: - Response Parser

struct ResponseParser {
    
    func parse(_ response: AIResponse) -> AIResponse {
        var parsed = response
        
        // Extract code blocks
        let codeBlocks = extractCodeBlocks(from: response.content)
        
        // Detect implicit tool calls from content
        if parsed.toolCalls == nil || parsed.toolCalls!.isEmpty {
            let implicitCalls = detectImplicitToolCalls(from: response.content)
            if !implicitCalls.isEmpty {
                parsed = AIResponse(
                    content: parsed.content,
                    toolCalls: implicitCalls,
                    tokensUsed: parsed.tokensUsed,
                    model: parsed.model,
                    finishReason: parsed.finishReason
                )
            }
        }
        
        return parsed
    }
    
    // MARK: - Code Block Extraction
    
    func extractCodeBlocks(from text: String) -> [ParsedCodeBlock] {
        var blocks: [ParsedCodeBlock] = []
        let pattern = #"```(\w*)\n([\s\S]*?)```"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return blocks
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            guard let langRange = Range(match.range(at: 1), in: text),
                  let codeRange = Range(match.range(at: 2), in: text) else {
                continue
            }
            
            let language = String(text[langRange])
            let code = String(text[codeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            blocks.append(ParsedCodeBlock(
                language: language.isEmpty ? "text" : language,
                code: code,
                startIndex: match.range.location,
                endIndex: match.range.location + match.range.length
            ))
        }
        
        return blocks
    }
    
    // MARK: - Implicit Tool Call Detection
    
    func detectImplicitToolCalls(from text: String) -> [ToolCall] {
        var calls: [ToolCall] = []
        let lowercased = text.lowercased()
        
        // Detect file creation intent
        if let fileMatch = detectFileCreation(in: text) {
            calls.append(ToolCall(
                id: UUID().uuidString,
                name: "write_file",
                arguments: fileMatch
            ))
        }
        
        // Detect command execution intent
        if let cmdMatch = detectCommandExecution(in: text) {
            calls.append(ToolCall(
                id: UUID().uuidString,
                name: "run_command",
                arguments: cmdMatch
            ))
        }
        
        // Detect code generation with specific output
        if lowercased.contains("here's the code") || lowercased.contains("here is the code") {
            let codeBlocks = extractCodeBlocks(from: text)
            if let firstBlock = codeBlocks.first {
                calls.append(ToolCall(
                    id: UUID().uuidString,
                    name: "generate_code",
                    arguments: [
                        "code": firstBlock.code,
                        "language": firstBlock.language
                    ]
                ))
            }
        }
        
        return calls
    }
    
    private func detectFileCreation(in text: String) -> [String: Any]? {
        // Pattern: "Create a file named X" or "Save this to X"
        let patterns = [
            #"create\s+(?:a\s+)?file\s+(?:named\s+)?[\"']?([^\s\"']+)[\"']?"#,
            #"save\s+(?:this\s+)?to\s+[\"']?([^\s\"']+)[\"']?"#,
            #"write\s+to\s+[\"']?([^\s\"']+)[\"']?"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let pathRange = Range(match.range(at: 1), in: text) {
                
                let path = String(text[pathRange])
                let codeBlocks = extractCodeBlocks(from: text)
                let content = codeBlocks.first?.code ?? ""
                
                return ["path": path, "content": content]
            }
        }
        
        return nil
    }
    
    private func detectCommandExecution(in text: String) -> [String: Any]? {
        // Pattern: "Run: command" or "Execute: command"
        let patterns = [
            #"run[:\s]+`([^`]+)`"#,
            #"execute[:\s]+`([^`]+)`"#,
            #"```(?:bash|sh|shell)\n([^\n]+)\n```"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let cmdRange = Range(match.range(at: 1), in: text) {
                
                let command = String(text[cmdRange])
                return ["command": command]
            }
        }
        
        return nil
    }
    
    // MARK: - Structured Content Extraction
    
    func extractStructuredContent(from text: String) -> StructuredResponse {
        var response = StructuredResponse()
        
        // Extract headers
        response.headers = extractHeaders(from: text)
        
        // Extract lists
        response.lists = extractLists(from: text)
        
        // Extract code blocks
        response.codeBlocks = extractCodeBlocks(from: text)
        
        // Extract links
        response.links = extractLinks(from: text)
        
        // Extract key-value pairs
        response.keyValues = extractKeyValues(from: text)
        
        return response
    }
    
    private func extractHeaders(from text: String) -> [ParsedHeader] {
        var headers: [ParsedHeader] = []
        let pattern = #"^(#{1,6})\s+(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return headers
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            guard let hashRange = Range(match.range(at: 1), in: text),
                  let textRange = Range(match.range(at: 2), in: text) else {
                continue
            }
            
            let level = text[hashRange].count
            let headerText = String(text[textRange])
            
            headers.append(ParsedHeader(level: level, text: headerText))
        }
        
        return headers
    }
    
    private func extractLists(from text: String) -> [ParsedList] {
        var lists: [ParsedList] = []
        
        // Bullet lists
        let bulletPattern = #"^[\s]*[-*]\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: bulletPattern, options: .anchorsMatchLines) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            
            var items: [String] = []
            for match in matches {
                if let itemRange = Range(match.range(at: 1), in: text) {
                    items.append(String(text[itemRange]))
                }
            }
            
            if !items.isEmpty {
                lists.append(ParsedList(type: .bullet, items: items))
            }
        }
        
        // Numbered lists
        let numberedPattern = #"^[\s]*\d+[.)]\s+(.+)$"#
        if let regex = try? NSRegularExpression(pattern: numberedPattern, options: .anchorsMatchLines) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            
            var items: [String] = []
            for match in matches {
                if let itemRange = Range(match.range(at: 1), in: text) {
                    items.append(String(text[itemRange]))
                }
            }
            
            if !items.isEmpty {
                lists.append(ParsedList(type: .numbered, items: items))
            }
        }
        
        return lists
    }
    
    private func extractLinks(from text: String) -> [ParsedLink] {
        var links: [ParsedLink] = []
        let pattern = #"\[([^\]]+)\]\(([^)]+)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return links
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            guard let textRange = Range(match.range(at: 1), in: text),
                  let urlRange = Range(match.range(at: 2), in: text) else {
                continue
            }
            
            links.append(ParsedLink(
                text: String(text[textRange]),
                url: String(text[urlRange])
            ))
        }
        
        return links
    }
    
    private func extractKeyValues(from text: String) -> [String: String] {
        var keyValues: [String: String] = [:]
        let pattern = #"^\*\*([^*]+)\*\*:\s*(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return keyValues
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range)
        
        for match in matches {
            guard let keyRange = Range(match.range(at: 1), in: text),
                  let valueRange = Range(match.range(at: 2), in: text) else {
                continue
            }
            
            keyValues[String(text[keyRange])] = String(text[valueRange])
        }
        
        return keyValues
    }
}

// MARK: - Parsed Content Models

struct ParsedCodeBlock {
    let language: String
    let code: String
    let startIndex: Int
    let endIndex: Int
}

struct ParsedHeader {
    let level: Int
    let text: String
}

struct ParsedList {
    let type: ListType
    let items: [String]
    
    enum ListType {
        case bullet
        case numbered
    }
}

struct ParsedLink {
    let text: String
    let url: String
}

struct StructuredResponse {
    var headers: [ParsedHeader] = []
    var lists: [ParsedList] = []
    var codeBlocks: [ParsedCodeBlock] = []
    var links: [ParsedLink] = []
    var keyValues: [String: String] = [:]
}
