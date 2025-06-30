//
//  ChatViewModel.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import Foundation
import MLX
import MLXLMCommon
import UniformTypeIdentifiers

/// ViewModel that manages the chat interface and coordinates with MLXService for text generation.
/// Handles user input, message history, media attachments, and generation state.
@Observable

class ChatViewModel: ObservableObject, Codable, Identifiable {
    /// Service responsible for ML model operations
    private let mlxService: MLXService
    
    var pm: PerformanceModel = PerformanceModel()
    
    let id: UUID

    var modelID:String?
    
    /// Current user input text
    var prompt: String = ""

    /// Chat history containing system, user, and assistant messages
    var messages: [Message] = [
        .system("You are a helpful assistant! Your name is Nichelle and are located in Toledo, Ohio")
    ]

    /// Currently selected language model for generation
    var selectedModel: DoModel = MLXService.availableModels.first!

    /// Manages image and video attachments for the current message
    var mediaSelection = MediaSelection()

    /// Indicates if text generation is in progress
    var isGenerating = false
    
    ///
    var generateParameters = GenerateParameters()

    /// Current generation task, used for cancellation
    private var generateTask: Task<Void, any Error>?

    /// Stores performance metrics from the current generation
    private var generateCompletionInfo: GenerateCompletionInfo?

    /// Current generation speed in tokens per second
    var tokensPerSecond: Double {
        generateCompletionInfo?.tokensPerSecond ?? 0
    }

    /// Progress of the current model download, if any
    @MainActor var modelDownloadProgress: Progress? {
            return mlxService.modelDownloadProgress
    }
//    @MainActor var modelFraction: Double? {
//            return mlxService.modelFraction
//    }

    /// Most recent error message, if any
    var errorMessage: String?

    
    init(mlxService: MLXService) {
        id = UUID()
        modelID = ""
        
        self.mlxService = mlxService
        
    }
    
    required init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        modelID = try c.decodeIfPresent(String.self, forKey: .modelID) ?? ""
        prompt = try c.decodeIfPresent(String.self, forKey: .prompt) ?? "Hello."
        messages = try c.decode([Message].self, forKey: .messages)
        
        self.mlxService = MLXService()
        
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(modelID, forKey: .modelID)
        try c.encodeIfPresent(prompt, forKey: .prompt)
        try c.encodeIfPresent(messages, forKey: .messages)
    }
    
    
    private enum CodingKeys: String, CodingKey {
        case id, modelID, prompt, messages
    }
    
    func takeMemorySnapshot() {
        pm.gpuSnapshot.append(Snapshot(activeMemory: MLX.GPU.activeMemory, cacheMemory:MLX.GPU.cacheMemory, peakMemory: MLX.GPU.peakMemory))
        pm.peakMemory = max(MLX.GPU.peakMemory, pm.peakMemory)
        pm.activeMemory = MLX.GPU.activeMemory
    }
    
    /// Generates response for the current prompt and media attachments
    func generate() async {
        takeMemorySnapshot()
        
        // Cancel any existing generation task
        if let existingTask = generateTask {
            existingTask.cancel()
            generateTask = nil
        }

        isGenerating = true

        // Add user message with any media attachments
        messages.append(.user(prompt, images: mediaSelection.images, videos: mediaSelection.videos))
        // Add empty assistant message that will be filled during generation
        messages.append(.assistant(""))

        // Clear the input after sending
        clear(.prompt)
        
        generateTask = Task {
            // Process generation chunks and update UI
            for await generation in try await mlxService.generate(
                messages: messages, model: selectedModel, parameters: generateParameters)
            {
                takeMemorySnapshot()
                pm.cacheLimit = MLX.GPU.cacheLimit
//                pm.memoryLimit = MLX.GPU.memoryLimit
                
                switch generation {
                case .chunk(let chunk):
                    // Append new text to the current assistant message
                    if let assistantMessage = messages.last {
                        
                        assistantMessage.content += chunk
                    }
                case .info(let info):
                    // Update performance metrics
                    generateCompletionInfo = info
                    messages.last?.generationInfo = info
                    print(info)
                }
                
                takeMemorySnapshot()
                
            }
        }

        do {
            // Handle task completion and cancellation
            try await withTaskCancellationHandler {
                try await generateTask?.value
            } onCancel: {
                Task { @MainActor in
                    generateTask?.cancel()

                    // Mark message as cancelled
                    if let assistantMessage = messages.last {
                        assistantMessage.content += "\n[Cancelled]"
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
        generateTask = nil
    }

    /// Processes and adds media attachments to the current message
    func addMedia(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()

            // Determine media type and add to appropriate collection
            if let mediaType = UTType(filenameExtension: url.pathExtension) {
                if mediaType.conforms(to: .image) {
                    mediaSelection.images = [url]
                } else if mediaType.conforms(to: .movie) {
                    mediaSelection.videos = [url]
                }
            }
        } catch {
            errorMessage = "Failed to load media item.\n\nError: \(error)"
        }
    }

    /// Clears various aspects of the chat state based on provided options
    func clear(_ options: ClearOption) {
        if options.contains(.prompt) {
            prompt = ""
            mediaSelection = .init()
        }

        if options.contains(.chat) {
            messages = []
            generateTask?.cancel()
        }

        if options.contains(.meta) {
            generateCompletionInfo = nil
        }

        pm.gpuSnapshot = []
        
        errorMessage = nil
    }
}

/// Manages the state of media attachments in the chat
@Observable
class MediaSelection {
    /// Controls visibility of media selection UI
    var isShowing = false

    /// Currently selected image URLs
    var images: [URL] = [] {
        didSet {
            didSetURLs(oldValue, images)
        }
    }

    /// Currently selected video URLs
    var videos: [URL] = [] {
        didSet {
            didSetURLs(oldValue, videos)
        }
    }

    /// Whether any media is currently selected
    var isEmpty: Bool {
        images.isEmpty && videos.isEmpty
    }

    private func didSetURLs(_ old: [URL], _ new: [URL]) {
        // the urls we get from fileImporter require SSB calls to access
        new.filter { !old.contains($0) }.forEach { _ = $0.startAccessingSecurityScopedResource() }
        old.filter { !new.contains($0) }.forEach { $0.stopAccessingSecurityScopedResource() }
    }
}

/// Options for clearing different aspects of the chat state
struct ClearOption: RawRepresentable, OptionSet {
    let rawValue: Int

    /// Clears current prompt and media selection
    static let prompt = ClearOption(rawValue: 1 << 0)
    /// Clears chat history and cancels generation
    static let chat = ClearOption(rawValue: 1 << 1)
    /// Clears generation metadata
    static let meta = ClearOption(rawValue: 1 << 2)
}
