//
//  KnowledgeModels.swift
//  Hub
//
//  Re-exports knowledge models from HubModuleUpdate_2 for unified access
//  This ensures compatibility and avoids duplication
//

import Foundation

// MARK: - Re-export existing models from HubModuleUpdate_2

// These types are already defined in Hub/HubComponents/HubModuleUpdate_2/Data/Models/
// We re-export them here for convenient access within the OfflineAssistantModule

/// Re-export OfflineKnowledgeEntry
/// Defined in: Hub/HubComponents/HubModuleUpdate_2/Data/Models/OfflineKnowledgeEntry.swift


/// Re-export base Conversation model
/// Defined in: Hub/HubComponents/HubModuleUpdate_2/Domain/Conversation/ConversationModels.swift
typealias BaseConversation = Hub.Conversation

/// Re-export base Message model
/// Defined in: Hub/HubComponents/HubModuleUpdate_2/Domain/Conversation/ConversationModels.swift
typealias BaseMessage = Hub.Message

// Note: MessageRole is already available from HubModuleUpdate_2
// No need to re-export as it's in the same module

// MARK: - Extension for compatibility

extension OfflineKnowledgeEntry {
    /// Calculate content hash for deduplication
    var contentHash: String {
        let content = originalSubmission + (mappedData.content ?? "")
        return content.sha256Hash()
    }
}

// MARK: - String Extension for Hashing

extension String {
    /// Calculate SHA-256 hash of the string
    func sha256Hash() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        
        // Use CommonCrypto for SHA-256
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Import CommonCrypto for SHA-256
import CommonCrypto
