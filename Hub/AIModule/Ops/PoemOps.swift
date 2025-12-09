//
//  PoemOps.swift
//  Hub
//
//  Poem creation operations with creative workflow
//

import Foundation

// MARK: - Poem Ops

public struct PoemOps {
    
    // MARK: - DAG Definition
    
    public static let dag = OperationDAG(
        name: "PoemOps",
        description: "Creative poem composition workflow",
        nodes: [
            DAGNode(id: "inspire", operation: Operation.inspire, dependencies: []),
            DAGNode(id: "brainstorm", operation: Operation.brainstorm, dependencies: ["inspire"]),
            DAGNode(id: "compose", operation: Operation.compose, dependencies: ["brainstorm"]),
            DAGNode(id: "refine", operation: Operation.refine, dependencies: ["compose"]),
            DAGNode(id: "polish", operation: Operation.polish, dependencies: ["refine"]),
            DAGNode(id: "share", operation: Operation.share, dependencies: ["polish"])
        ]
    )
    
    // MARK: - Operations
    
    public enum Operation: String {
        case inspire = "Gather inspiration and themes"
        case brainstorm = "Brainstorm imagery and metaphors"
        case compose = "Compose initial verses"
        case refine = "Refine rhythm and rhyme"
        case polish = "Polish language and flow"
        case share = "Share poem"
    }
    
    // MARK: - Commands
    
    public static func inspire(theme: String, mood: PoemMood) -> Inspiration {
        return Inspiration(
            theme: theme,
            mood: mood,
            imagery: [
                "Natural elements",
                "Emotional landscapes",
                "Sensory details",
                "Symbolic objects"
            ],
            emotions: mood.emotions
        )
    }
    
    public static func brainstorm(inspiration: Inspiration) -> BrainstormResult {
        return BrainstormResult(
            metaphors: [
                "Time as a river",
                "Love as a flame",
                "Hope as a sunrise"
            ],
            imagery: inspiration.imagery,
            wordBank: [
                "whisper", "cascade", "shimmer", "embrace",
                "wander", "bloom", "echo", "dance"
            ]
        )
    }
    
    public static func compose(
        brainstorm: BrainstormResult,
        style: PoemStyle,
        structure: PoemStructure
    ) -> PoemDraft {
        return PoemDraft(
            title: "Untitled",
            verses: structure.generateVerses(wordBank: brainstorm.wordBank),
            style: style,
            structure: structure
        )
    }
    
    public static func refine(draft: PoemDraft, focus: RefinementFocus) -> PoemDraft {
        var refined = draft
        refined.title = "Refined: \(draft.title)"
        return refined
    }
    
    public static func polish(draft: PoemDraft) -> FinalPoem {
        return FinalPoem(
            title: draft.title,
            content: draft.verses.joined(separator: "\n\n"),
            style: draft.style,
            wordCount: draft.verses.joined(separator: " ").split(separator: " ").count
        )
    }
    
    public static func share(poem: FinalPoem, platform: SharingPlatform) -> ShareResult {
        return ShareResult(
            url: "https://\(platform.rawValue)/poems/\(UUID().uuidString)",
            sharedAt: Date(),
            platform: platform
        )
    }
}

// MARK: - Supporting Types

public enum PoemMood: String {
    case joyful = "Joyful"
    case melancholic = "Melancholic"
    case contemplative = "Contemplative"
    case passionate = "Passionate"
    case serene = "Serene"
    
    var emotions: [String] {
        switch self {
        case .joyful: return ["happiness", "excitement", "wonder"]
        case .melancholic: return ["sadness", "longing", "nostalgia"]
        case .contemplative: return ["reflection", "wisdom", "peace"]
        case .passionate: return ["love", "desire", "intensity"]
        case .serene: return ["calm", "tranquility", "acceptance"]
        }
    }
}

public enum PoemStyle: String {
    case freeVerse = "Free Verse"
    case haiku = "Haiku"
    case sonnet = "Sonnet"
    case limerick = "Limerick"
    case acrostic = "Acrostic"
}

public struct PoemStructure {
    public let verses: Int
    public let linesPerVerse: Int
    public let rhymeScheme: String?
    
    public static let freeVerse = PoemStructure(verses: 3, linesPerVerse: 4, rhymeScheme: nil)
    public static let haiku = PoemStructure(verses: 1, linesPerVerse: 3, rhymeScheme: nil)
    public static let sonnet = PoemStructure(verses: 4, linesPerVerse: 4, rhymeScheme: "ABAB CDCD EFEF GG")
    
    func generateVerses(wordBank: [String]) -> [String] {
        return (0..<verses).map { verseNum in
            (0..<linesPerVerse).map { lineNum in
                "Line \(lineNum + 1) of verse \(verseNum + 1)"
            }.joined(separator: "\n")
        }
    }
}

public enum RefinementFocus {
    case rhythm, rhyme, imagery, emotion
}

public enum SharingPlatform: String {
    case poetryFoundation = "poetryfoundation.org"
    case allPoetry = "allpoetry.com"
    case helloPoetry = "hellopoetry.com"
    case personal = "personal-blog.com"
}

public struct Inspiration {
    public let theme: String
    public let mood: PoemMood
    public let imagery: [String]
    public let emotions: [String]
}

public struct BrainstormResult {
    public let metaphors: [String]
    public let imagery: [String]
    public let wordBank: [String]
}

public struct PoemDraft {
    public var title: String
    public let verses: [String]
    public let style: PoemStyle
    public let structure: PoemStructure
}

public struct FinalPoem {
    public let title: String
    public let content: String
    public let style: PoemStyle
    public let wordCount: Int
}

public struct ShareResult {
    public let url: String
    public let sharedAt: Date
    public let platform: SharingPlatform
}
