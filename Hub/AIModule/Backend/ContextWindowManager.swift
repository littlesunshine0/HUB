//
//  ContextWindowManager.swift
//  Hub
//
//  Manages context window size and token counting
//

import Foundation

// MARK: - Context Window Manager

actor ContextWindowManager {
    private let maxTokens: Int
    private var currentTokenCount: Int = 0
    
    init(maxTokens: Int = 128000) {
        self.maxTokens = maxTokens
    }
    
    // MARK: - Token Counting
    
    func countTokens(_ text: String) -> Int {
        // Approximate token count (GPT-style: ~4 chars per token)
        // For production, use tiktoken or similar
        return max(1, text.count / 4)
    }
    
    func countTokens(messages: [LLMMessage]) -> Int {
        var total = 0
        for message in messages {
            total += countTokens(message.content)
            total += 4 // Role and formatting overhead
        }
        return total
    }
    
    // MARK: - Context Fitting
    
    func fitToContext(
        messages: [LLMMessage],
        maxTokens: Int? = nil
    ) -> [LLMMessage] {
        let limit = maxTokens ?? self.maxTokens
        var fitted: [LLMMessage] = []
        var tokenCount = 0
        
        // Always include system message
        if let systemMessage = messages.first(where: { $0.role == "system" }) {
            fitted.append(systemMessage)
            tokenCount += countTokens(systemMessage.content)
        }
        
        // Add messages from most recent, respecting token limit
        let nonSystemMessages = messages.filter { $0.role != "system" }
        
        for message in nonSystemMessages.reversed() {
            let messageTokens = countTokens(message.content)
            if tokenCount + messageTokens <= limit {
                fitted.insert(message, at: fitted.count > 0 ? 1 : 0)
                tokenCount += messageTokens
            } else {
                break
            }
        }
        
        return fitted
    }
    
    func truncateContent(_ content: String, maxTokens: Int) -> String {
        let currentTokens = countTokens(content)
        if currentTokens <= maxTokens {
            return content
        }
        
        // Truncate to approximate character count
        let targetChars = maxTokens * 4
        if content.count <= targetChars {
            return content
        }
        
        let truncated = String(content.prefix(targetChars))
        return truncated + "\n\n[Content truncated due to length...]"
    }
    
    // MARK: - Smart Summarization
    
    func summarizeForContext(_ content: String, targetTokens: Int) -> String {
        let currentTokens = countTokens(content)
        if currentTokens <= targetTokens {
            return content
        }
        
        // Extract key sections
        var summary = ""
        let lines = content.components(separatedBy: "\n")
        
        // Prioritize: headers, function signatures, important comments
        let priorityPatterns = [
            #"^#{1,6}\s+"#,           // Headers
            #"^(func|class|struct|enum|protocol)\s+"#,  // Declarations
            #"^(import|require|include)\s+"#,  // Imports
            #"^//\s*(MARK|TODO|FIXME|NOTE):"#,  // Important comments
            #"^(public|private|internal)\s+"#   // Access modifiers
        ]
        
        var priorityLines: [String] = []
        var otherLines: [String] = []
        
        for line in lines {
            var isPriority = false
            for pattern in priorityPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                    isPriority = true
                    break
                }
            }
            
            if isPriority {
                priorityLines.append(line)
            } else {
                otherLines.append(line)
            }
        }
        
        // Build summary starting with priority lines
        var tokenCount = 0
        
        for line in priorityLines {
            let lineTokens = countTokens(line)
            if tokenCount + lineTokens <= targetTokens {
                summary += line + "\n"
                tokenCount += lineTokens
            }
        }
        
        // Add other lines if space remains
        for line in otherLines {
            let lineTokens = countTokens(line)
            if tokenCount + lineTokens <= targetTokens {
                summary += line + "\n"
                tokenCount += lineTokens
            }
        }
        
        if summary.isEmpty {
            return truncateContent(content, maxTokens: targetTokens)
        }
        
        return summary
    }
    
    // MARK: - Context Allocation
    
    struct ContextAllocation {
        let systemPrompt: Int
        let ragContext: Int
        let conversationHistory: Int
        let currentMessage: Int
        let responseBuffer: Int
    }
    
    func allocateContext(
        systemPromptTokens: Int,
        ragDocumentCount: Int,
        historyTurnCount: Int
    ) -> ContextAllocation {
        let responseBuffer = min(4096, maxTokens / 4)
        let available = maxTokens - responseBuffer
        
        // Allocate proportionally
        let systemAllocation = min(systemPromptTokens, available / 4)
        let remaining = available - systemAllocation
        
        let ragAllocation = ragDocumentCount > 0 ? min(remaining / 3, ragDocumentCount * 500) : 0
        let historyAllocation = historyTurnCount > 0 ? min(remaining / 3, historyTurnCount * 200) : 0
        let messageAllocation = remaining - ragAllocation - historyAllocation
        
        return ContextAllocation(
            systemPrompt: systemAllocation,
            ragContext: ragAllocation,
            conversationHistory: historyAllocation,
            currentMessage: messageAllocation,
            responseBuffer: responseBuffer
        )
    }
    
    // MARK: - Sliding Window
    
    func slidingWindow(
        messages: [LLMMessage],
        windowSize: Int
    ) -> [LLMMessage] {
        guard messages.count > windowSize else {
            return messages
        }
        
        var windowed: [LLMMessage] = []
        
        // Keep system message
        if let system = messages.first(where: { $0.role == "system" }) {
            windowed.append(system)
        }
        
        // Keep last N messages
        let nonSystem = messages.filter { $0.role != "system" }
        windowed.append(contentsOf: nonSystem.suffix(windowSize))
        
        return windowed
    }
}

// MARK: - Token Counter (More Accurate)

struct TokenCounter {
    // Character-based approximation by language
    static func count(_ text: String, language: String? = nil) -> Int {
        let baseCount = text.count / 4
        
        // Adjust for language-specific patterns
        switch language?.lowercased() {
        case "swift", "java", "kotlin":
            // More verbose languages
            return Int(Double(baseCount) * 0.9)
        case "python", "ruby":
            // More concise languages
            return Int(Double(baseCount) * 1.1)
        case "json", "yaml":
            // Structured data
            return Int(Double(baseCount) * 0.8)
        default:
            return baseCount
        }
    }
    
    // Count with special token handling
    static func countWithSpecialTokens(_ messages: [LLMMessage]) -> Int {
        var total = 0
        
        for message in messages {
            // Message overhead
            total += 4  // <|im_start|>, role, <|im_sep|>, <|im_end|>
            
            // Content tokens
            total += count(message.content)
        }
        
        // Conversation overhead
        total += 3  // Priming tokens
        
        return total
    }
}
