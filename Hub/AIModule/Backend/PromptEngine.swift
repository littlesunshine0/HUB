//
//  PromptEngine.swift
//  Hub
//
//  Prompt construction and management
//

import Foundation

// MARK: - Prompt Engine

struct PromptEngine {
    
    // MARK: - Main Prompt Builder
    
    func buildPrompt(
        message: String,
        context: EnrichedContext,
        history: [ChatTurn],
        ragDocuments: [RAGDocument],
        tools: [AITool]
    ) -> LLMPrompt {
        var messages: [LLMMessage] = []
        
        // System prompt
        let systemPrompt = buildSystemPrompt(context: context, tools: tools)
        messages.append(LLMMessage(role: "system", content: systemPrompt))
        
        // RAG context
        if !ragDocuments.isEmpty {
            let ragContext = buildRAGContext(ragDocuments)
            messages.append(LLMMessage(role: "system", content: ragContext))
        }
        
        // Conversation history
        for turn in history.suffix(20) { // Keep last 20 turns
            messages.append(LLMMessage(role: turn.role, content: turn.content))
        }
        
        // Current message with context
        let enrichedMessage = buildEnrichedMessage(message: message, context: context)
        messages.append(LLMMessage(role: "user", content: enrichedMessage))
        
        // Tool definitions
        let toolDefs = tools.map { tool in
            ToolDefinition(
                name: tool.name,
                description: tool.description,
                parameters: tool.parameters
            )
        }
        
        return LLMPrompt(messages: messages, tools: toolDefs.isEmpty ? nil : toolDefs)
    }
    
    // MARK: - System Prompt
    
    private func buildSystemPrompt(context: EnrichedContext, tools: [AITool]) -> String {
        var prompt = """
        You are an expert AI coding assistant integrated into Hub, a powerful app development platform.
        
        ## Your Capabilities
        - Generate high-quality, production-ready code
        - Explain complex concepts clearly
        - Debug and fix issues
        - Refactor and optimize code
        - Search and navigate codebases
        - Create and modify files
        - Execute safe shell commands
        
        ## Guidelines
        1. Always provide complete, working code - no placeholders or TODOs
        2. Follow best practices for the language/framework being used
        3. Include helpful comments for complex logic
        4. Consider edge cases and error handling
        5. Suggest improvements when appropriate
        6. Be concise but thorough
        
        ## Response Format
        - Use markdown for formatting
        - Use code blocks with language specifiers
        - Structure long responses with headers
        - Provide step-by-step explanations when helpful
        
        """
        
        // Add context-specific instructions
        if let fileContext = context.originalContext?.currentFile {
            prompt += """
            
            ## Current Context
            - File: \(fileContext.path)
            - Language: \(fileContext.language)
            
            """
        }
        
        if let project = context.originalContext?.projectContext {
            prompt += """
            - Project: \(project.name)
            - Type: \(project.type)
            - Frameworks: \(project.frameworks.joined(separator: ", "))
            
            """
        }
        
        // Add tool instructions if available
        if !tools.isEmpty {
            prompt += """
            
            ## Available Tools
            You have access to the following tools. Use them when appropriate:
            
            """
            
            for tool in tools {
                prompt += "- **\(tool.name)**: \(tool.description)\n"
            }
            
            prompt += """
            
            To use a tool, respond with a tool call in the appropriate format.
            Only use tools when necessary to complete the user's request.
            
            """
        }
        
        return prompt
    }
    
    // MARK: - RAG Context
    
    private func buildRAGContext(_ documents: [RAGDocument]) -> String {
        var context = """
        ## Relevant Context from Codebase
        
        The following code snippets may be relevant to the user's question:
        
        """
        
        for (index, doc) in documents.enumerated() {
            context += """
            
            ### Source \(index + 1): \(doc.metadata.source)
            ```\(doc.metadata.language ?? "")
            \(doc.content.prefix(1000))
            ```
            
            """
        }
        
        context += """
        
        Use this context to provide accurate, project-specific answers.
        Reference specific files when relevant.
        
        """
        
        return context
    }
    
    // MARK: - Enriched Message
    
    private func buildEnrichedMessage(message: String, context: EnrichedContext) -> String {
        var enriched = message
        
        // Add selected code
        if let selection = context.selectedCode, !selection.isEmpty {
            enriched = """
            \(message)
            
            **Selected Code:**
            ```\(context.fileLanguage ?? "")
            \(selection)
            ```
            """
        }
        
        // Add file content if relevant
        if let fileContent = context.fileContent,
           context.detectedIntent == .explain || context.detectedIntent == .debug || context.detectedIntent == .refactor {
            let truncated = String(fileContent.prefix(3000))
            enriched += """
            
            **Current File Content:**
            ```\(context.fileLanguage ?? "")
            \(truncated)
            ```
            """
        }
        
        // Add attached files
        for file in context.attachedFiles {
            enriched += """
            
            **Attached File: \(file.name)**
            ```
            \(file.content.prefix(2000))
            ```
            """
        }
        
        // Add code snippets
        for (index, snippet) in context.codeSnippets.enumerated() {
            enriched += """
            
            **Code Snippet \(index + 1):**
            ```
            \(snippet.prefix(1000))
            ```
            """
        }
        
        // Add image analyses
        for analysis in context.imageAnalyses {
            enriched += """
            
            **Image Analysis:**
            \(analysis.description)
            Objects detected: \(analysis.objects.joined(separator: ", "))
            """
            if let text = analysis.text {
                enriched += "\nText in image: \(text)"
            }
        }
        
        return enriched
    }
    
    // MARK: - Tool Result Prompt
    
    func buildToolResultPrompt(
        originalMessage: String,
        toolResults: [ToolResult],
        context: EnrichedContext
    ) -> LLMPrompt {
        var messages: [LLMMessage] = []
        
        // System prompt
        messages.append(LLMMessage(role: "system", content: """
        You are an AI assistant. The user asked a question and you used tools to help answer it.
        Now provide a helpful response based on the tool results.
        """))
        
        // Original message
        messages.append(LLMMessage(role: "user", content: originalMessage))
        
        // Tool results
        var toolResultContent = "Tool execution results:\n\n"
        for result in toolResults {
            toolResultContent += """
            **Tool: \(result.toolCallId)**
            Success: \(result.success)
            Output: \(result.output ?? "No output")
            \(result.error.map { "Error: \($0)" } ?? "")
            
            """
        }
        messages.append(LLMMessage(role: "assistant", content: toolResultContent))
        
        // Request final response
        messages.append(LLMMessage(role: "user", content: "Based on these results, please provide a complete answer to my original question."))
        
        return LLMPrompt(messages: messages, tools: nil)
    }
    
    // MARK: - Specialized Prompts
    
    func buildCodeGenerationPrompt(description: String, language: String, framework: String?) -> LLMPrompt {
        let systemPrompt = """
        You are an expert \(language) developer\(framework.map { " specializing in \($0)" } ?? "").
        Generate clean, production-ready code based on the user's description.
        
        Requirements:
        - Complete, working implementation
        - Proper error handling
        - Clear comments for complex logic
        - Follow \(language) best practices
        - Include any necessary imports
        """
        
        return LLMPrompt(
            messages: [
                LLMMessage(role: "system", content: systemPrompt),
                LLMMessage(role: "user", content: "Generate: \(description)")
            ],
            tools: nil
        )
    }
    
    func buildExplanationPrompt(code: String, language: String) -> LLMPrompt {
        let systemPrompt = """
        You are a patient teacher explaining code to a developer.
        Provide clear, structured explanations with:
        - Overview of what the code does
        - Line-by-line breakdown of key parts
        - Explanation of patterns and techniques used
        - Potential improvements or considerations
        """
        
        return LLMPrompt(
            messages: [
                LLMMessage(role: "system", content: systemPrompt),
                LLMMessage(role: "user", content: """
                Please explain this \(language) code:
                
                ```\(language)
                \(code)
                ```
                """)
            ],
            tools: nil
        )
    }
    
    func buildDebugPrompt(code: String, error: String, language: String) -> LLMPrompt {
        let systemPrompt = """
        You are an expert debugger. Analyze the code and error, then:
        1. Identify the root cause
        2. Explain why the error occurs
        3. Provide the corrected code
        4. Suggest how to prevent similar issues
        """
        
        return LLMPrompt(
            messages: [
                LLMMessage(role: "system", content: systemPrompt),
                LLMMessage(role: "user", content: """
                I'm getting this error:
                ```
                \(error)
                ```
                
                In this \(language) code:
                ```\(language)
                \(code)
                ```
                
                Please help me fix it.
                """)
            ],
            tools: nil
        )
    }
    
    func buildRefactorPrompt(code: String, language: String, goals: [String]) -> LLMPrompt {
        let goalsText = goals.isEmpty ? "general improvement" : goals.joined(separator: ", ")
        
        let systemPrompt = """
        You are a code quality expert. Refactor the provided code with focus on: \(goalsText).
        
        Provide:
        1. The refactored code
        2. Explanation of changes made
        3. Benefits of the refactoring
        """
        
        return LLMPrompt(
            messages: [
                LLMMessage(role: "system", content: systemPrompt),
                LLMMessage(role: "user", content: """
                Please refactor this \(language) code:
                
                ```\(language)
                \(code)
                ```
                """)
            ],
            tools: nil
        )
    }
}
