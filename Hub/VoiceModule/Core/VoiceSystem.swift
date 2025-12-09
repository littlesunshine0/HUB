//
//  VoiceSystem.swift
//  Hub
//
//  Core voice user interface system with speech recognition and synthesis
//

import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Voice Command

public struct VoiceCommand {
    public let id: UUID
    public let text: String
    public let intent: VoiceIntent
    public let confidence: Float
    public let timestamp: Date
    public let parameters: [String: Any]
    
    public init(
        id: UUID = UUID(),
        text: String,
        intent: VoiceIntent,
        confidence: Float,
        timestamp: Date = Date(),
        parameters: [String: Any] = [:]
    ) {
        self.id = id
        self.text = text
        self.intent = intent
        self.confidence = confidence
        self.timestamp = timestamp
        self.parameters = parameters
    }
}

// MARK: - Voice Intent

public enum VoiceIntent: String, CaseIterable {
    // Navigation
    case openHub = "open_hub"
    case closeHub = "close_hub"
    case goBack = "go_back"
    case goHome = "go_home"
    case navigate = "navigate"
    
    // Hub Operations
    case createHub = "create_hub"
    case deleteHub = "delete_hub"
    case editHub = "edit_hub"
    case searchHub = "search_hub"
    case shareHub = "share_hub"
    
    // Information
    case getInfo = "get_info"
    case listHubs = "list_hubs"
    case showStats = "show_stats"
    case getHelp = "get_help"
    
    // Settings
    case changeSettings = "change_settings"
    case toggleFeature = "toggle_feature"
    
    // System
    case unknown = "unknown"
    
    public var description: String {
        switch self {
        case .openHub: return "Open a hub"
        case .closeHub: return "Close current hub"
        case .goBack: return "Go back"
        case .goHome: return "Go to home"
        case .navigate: return "Navigate to location"
        case .createHub: return "Create new hub"
        case .deleteHub: return "Delete a hub"
        case .editHub: return "Edit a hub"
        case .searchHub: return "Search for hubs"
        case .shareHub: return "Share a hub"
        case .getInfo: return "Get information"
        case .listHubs: return "List all hubs"
        case .showStats: return "Show statistics"
        case .getHelp: return "Get help"
        case .changeSettings: return "Change settings"
        case .toggleFeature: return "Toggle feature"
        case .unknown: return "Unknown command"
        }
    }
}

// MARK: - Voice Response

public struct VoiceResponse {
    public let text: String
    public let shouldSpeak: Bool
    public let action: (() -> Void)?
    
    public init(text: String, shouldSpeak: Bool = true, action: (() -> Void)? = nil) {
        self.text = text
        self.shouldSpeak = shouldSpeak
        self.action = action
    }
}

// MARK: - Voice Manager

@MainActor
public class VoiceManager: NSObject, ObservableObject {
    public static let shared = VoiceManager()
    
    // Speech Recognition
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Speech Synthesis
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // State
    @Published public var isListening = false
    @Published public var isProcessing = false
    @Published public var isSpeaking = false
    @Published public var lastCommand: VoiceCommand?
    @Published public var lastResponse: VoiceResponse?
    @Published public var transcription = ""
    @Published public var error: String?
    
    // Configuration
    public var voiceName: String = "Gary"
    public var language: String = "en-US"
    public var speechRate: Float = 0.5
    public var volume: Float = 1.0
    public var pitch: Float = 1.0
    
    // Command History
    @Published public var commandHistory: [VoiceCommand] = []
    private let maxHistoryCount = 50
    
    // Handlers
    private var commandHandlers: [VoiceIntent: (VoiceCommand) async -> VoiceResponse] = [:]
    
    private override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        super.init()
        self.speechSynthesizer.delegate = self
    }
    
    // MARK: - Permission
    
    public func requestPermissions() async -> Bool {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard speechStatus == .authorized else {
            error = "Speech recognition not authorized"
            return false
        }
        
        #if os(iOS)
        // Request microphone permission (iOS only)
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        guard audioStatus else {
            error = "Microphone access not authorized"
            return false
        }
        #endif
        
        return true
    }
    
    // MARK: - Speech Recognition
    
    public func startListening() async throws {
        guard !isListening else { return }
        
        // Cancel any ongoing recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        
        #if os(iOS)
        // Configure audio session (iOS only)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionUnavailable
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        await self.processTranscription(result.bestTranscription.formattedString)
                        self.stopListening()
                    }
                }
                
                if error != nil {
                    self.stopListening()
                }
            }
        }
        
        isListening = true
        error = nil
    }
    
    public func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
    
    // MARK: - Command Processing
    
    private func processTranscription(_ text: String) async {
        isProcessing = true
        
        // Parse command
        let command = parseCommand(from: text)
        lastCommand = command
        commandHistory.insert(command, at: 0)
        
        if commandHistory.count > maxHistoryCount {
            commandHistory.removeLast()
        }
        
        // Execute command
        if let handler = commandHandlers[command.intent] {
            let response = await handler(command)
            lastResponse = response
            
            if response.shouldSpeak {
                speak(response.text)
            }
            
            response.action?()
        } else {
            let response = VoiceResponse(text: "I'm not sure how to help with that. Can you try rephrasing?")
            lastResponse = response
            speak(response.text)
        }
        
        isProcessing = false
    }
    
    private func parseCommand(from text: String) -> VoiceCommand {
        let lowercased = text.lowercased()
        
        // Navigation commands
        if lowercased.contains("open") || lowercased.contains("show") {
            if let hubName = extractHubName(from: lowercased) {
                return VoiceCommand(
                    text: text,
                    intent: .openHub,
                    confidence: 0.9,
                    parameters: ["hubName": hubName]
                )
            }
        }
        
        if lowercased.contains("create") && lowercased.contains("hub") {
            return VoiceCommand(text: text, intent: .createHub, confidence: 0.9)
        }
        
        if lowercased.contains("delete") || lowercased.contains("remove") {
            return VoiceCommand(text: text, intent: .deleteHub, confidence: 0.8)
        }
        
        if lowercased.contains("search") || lowercased.contains("find") {
            return VoiceCommand(text: text, intent: .searchHub, confidence: 0.9)
        }
        
        if lowercased.contains("list") || lowercased.contains("show all") {
            return VoiceCommand(text: text, intent: .listHubs, confidence: 0.9)
        }
        
        if lowercased.contains("help") {
            return VoiceCommand(text: text, intent: .getHelp, confidence: 1.0)
        }
        
        if lowercased.contains("go back") || lowercased.contains("back") {
            return VoiceCommand(text: text, intent: .goBack, confidence: 0.9)
        }
        
        if lowercased.contains("home") {
            return VoiceCommand(text: text, intent: .goHome, confidence: 0.9)
        }
        
        // Unknown command
        return VoiceCommand(text: text, intent: .unknown, confidence: 0.0)
    }
    
    private func extractHubName(from text: String) -> String? {
        // Simple extraction - look for text after "open" or "show"
        if let range = text.range(of: "open ") {
            return String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        if let range = text.range(of: "show ") {
            return String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    // MARK: - Speech Synthesis
    
    public func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = speechRate
        utterance.volume = volume
        utterance.pitchMultiplier = pitch
        
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }
    
    public func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - Command Registration
    
    public func registerHandler(
        for intent: VoiceIntent,
        handler: @escaping (VoiceCommand) async -> VoiceResponse
    ) {
        commandHandlers[intent] = handler
    }
    
    public func unregisterHandler(for intent: VoiceIntent) {
        commandHandlers.removeValue(forKey: intent)
    }
    
    // MARK: - Convenience Methods
    
    public func greet() {
        speak("Hello! I'm \(voiceName), your voice assistant. How can I help you today?")
    }
    
    public func confirmAction(_ action: String) {
        speak("Okay, \(action)")
    }
    
    public func reportError(_ message: String) {
        speak("Sorry, \(message)")
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceManager: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

// MARK: - Voice Error

public enum VoiceError: Error {
    case recognitionUnavailable
    case audioEngineError
    case permissionDenied
    case unknown
    
    public var localizedDescription: String {
        switch self {
        case .recognitionUnavailable:
            return "Speech recognition is not available"
        case .audioEngineError:
            return "Audio engine error occurred"
        case .permissionDenied:
            return "Permission denied for speech recognition"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Voice Statistics

public struct VoiceStatistics {
    public let totalCommands: Int
    public let successfulCommands: Int
    public let failedCommands: Int
    public let averageConfidence: Float
    public let mostUsedIntent: VoiceIntent?
    
    public init(history: [VoiceCommand]) {
        self.totalCommands = history.count
        self.successfulCommands = history.filter { $0.intent != .unknown }.count
        self.failedCommands = history.filter { $0.intent == .unknown }.count
        
        if !history.isEmpty {
            self.averageConfidence = history.reduce(0) { $0 + $1.confidence } / Float(history.count)
        } else {
            self.averageConfidence = 0
        }
        
        // Find most used intent
        var intentCounts: [VoiceIntent: Int] = [:]
        for command in history {
            intentCounts[command.intent, default: 0] += 1
        }
        self.mostUsedIntent = intentCounts.max(by: { $0.value < $1.value })?.key
    }
}
