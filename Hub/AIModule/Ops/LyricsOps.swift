//
//  LyricsOps.swift
//  Hub
//
//  Lyrics creation operations with musical workflow
//

import Foundation

// MARK: - Lyrics Ops

public struct LyricsOps {
    
    // MARK: - DAG Definition
    
    public static let dag = OperationDAG(
        name: "LyricsOps",
        description: "Song lyrics creation workflow",
        nodes: [
            DAGNode(id: "concept", operation: Operation.concept, dependencies: []),
            DAGNode(id: "hook", operation: Operation.hook, dependencies: ["concept"]),
            DAGNode(id: "verses", operation: Operation.verses, dependencies: ["hook"]),
            DAGNode(id: "chorus", operation: Operation.chorus, dependencies: ["hook"]),
            DAGNode(id: "bridge", operation: Operation.bridge, dependencies: ["verses", "chorus"]),
            DAGNode(id: "arrange", operation: Operation.arrange, dependencies: ["bridge"]),
            DAGNode(id: "finalize", operation: Operation.finalize, dependencies: ["arrange"])
        ]
    )
    
    // MARK: - Operations
    
    public enum Operation: String {
        case concept = "Develop song concept"
        case hook = "Create catchy hook"
        case verses = "Write verses"
        case chorus = "Compose chorus"
        case bridge = "Add bridge section"
        case arrange = "Arrange song structure"
        case finalize = "Finalize lyrics"
    }
    
    // MARK: - Commands
    
    public static func concept(theme: String, genre: MusicGenre) -> SongConcept {
        return SongConcept(theme: theme, genre: genre, mood: genre.typicalMood)
    }
    
    public static func hook(concept: SongConcept) -> Hook {
        return Hook(line: "Catchy hook about \(concept.theme)", memorable: true)
    }
}

// MARK: - Supporting Types

public enum MusicGenre: String {
    case pop, rock, hiphop, country, rnb
    
    var typicalMood: String {
        switch self {
        case .pop: return "upbeat"
        case .rock: return "energetic"
        case .hiphop: return "confident"
        case .country: return "storytelling"
        case .rnb: return "soulful"
        }
    }
}

public struct SongConcept {
    public let theme: String
    public let genre: MusicGenre
    public let mood: String
}

public struct Hook {
    public let line: String
    public let memorable: Bool
}
