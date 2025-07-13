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

class ChatModel: ObservableObject, Codable, Identifiable {
    /// Service responsible for ML model operations
    private let mlxService: MLXService
    var finishedSize: Int64 = 0

    var viewData: ChatViewModelData
    
    var performance: PerformanceData = PerformanceData()
    
    let id: UUID
    
    var modelID:String?
    
    /// Current user input text
    var prompt: String = ""
    
    /// Chat history containing system, user, and assistant messages
    var messages: [Message] = [
        .prompt("You are a helpful assistant! Your name is Nichelle and are located in Toledo, Ohio")
    ]
    
    /// Currently selected language model for generation
    var model: DoModel?// = MLXService.defaultModel
    
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
        if model == nil {
            return nil
        }
        return model!.modelDownloadProgress
    }
    
    /// Most recent error message, if any
    var errorMessage: String?
    
    
    init(mlxService: MLXService) {
        viewData = ChatViewModelData()
        id = UUID()
        modelID = ""
        model = MLXService.defaultModel
        self.mlxService = mlxService
        
    }
    
    func takeMemorySnapshot() {
        performance.gpuSnapshots.append(Snapshot(activeMemory: MLX.GPU.activeMemory, cacheMemory:MLX.GPU.cacheMemory, peakMemory: MLX.GPU.peakMemory))
        performance.peakMemory = max(MLX.GPU.peakMemory, performance.peakMemory)
        performance.activeMemory = MLX.GPU.activeMemory
    }
    
    /// Generates response for the current prompt and media attachments
    func generate() async {
        model?.state = .preparing
        takeMemorySnapshot()
        if model == nil {return}
        // Cancel any existing generation task
        if let existingTask = generateTask {
            existingTask.cancel()
            generateTask = nil

        }
        Task { @MainActor in
            model?.state = .generating
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
                messages: messages, model: model!, parameters: generateParameters)
            {
                if model == nil {return}
                takeMemorySnapshot()
                performance.cacheLimit = MLX.GPU.cacheLimit
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
                model!.finishedSize = model!.calculateSize
            }
        }
        
        do {
            // Handle task completion and cancellation
            try await withTaskCancellationHandler {
                try await generateTask?.value
            } onCancel: {
                Task { @MainActor in
                    model?.state = .stopped

                    generateTask?.cancel()
                    
                    // Mark message as cancelled
                    if let assistantMessage = messages.last {
                        assistantMessage.content += "\nThe generation was cancelled."
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            model?.state = .error
        }
        
        model?.state = .idle
        
        isGenerating = false
        generateTask = nil
    }
    
    func cancelGeneration() {
        generateTask?.cancel()
        isGenerating = false
        generateTask = nil
        
        Task { @MainActor in
            // Mark message as cancelled
            if let assistantMessage = messages.last {
                if assistantMessage.role == .assistant {
                    assistantMessage.content += "The generation was cancelled."
                }
            }
        }
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
            if messages.count > 1 {messages = [messages[0]]}
            generateTask?.cancel()
        }
        
        if options.contains(.meta) {
            generateCompletionInfo = nil
            self.performance.gpuSnapshots = []
            self.performance.peakMemory = 0
            self.performance.activeMemory = 0
        }
                        
        if options.contains(.gpuCache) {
            MLX.GPU.clearCache()
        }
        
        errorMessage = nil
                
    }
    
    private enum CodingKeys: String, CodingKey {
        case chatViewModelData, id, modelID, prompt, messages, generateParameters, selectedModel, finishedSize
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                = try c.decode(UUID.self, forKey: .id)
        modelID           = try c.decodeIfPresent(String.self, forKey: .modelID)
        prompt            = try c.decode(String.self, forKey: .prompt)
        messages          = try c.decode([Message].self, forKey: .messages)
        finishedSize = try c.decode(Int64.self, forKey: .finishedSize)
        generateParameters = try c.decode(GenerateParameters.self, forKey: .generateParameters)
        viewData = try c.decode(ChatViewModelData.self, forKey: .chatViewModelData)
        
        self.mlxService = MLXService()
        
        let decodedModel = MLXService.availableModels.first { $0.configuration.name == modelID }
        self.model = decodedModel
        
        model?.finishedSize = finishedSize
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                 forKey: .id)
        try c.encodeIfPresent(model?.configuration.name, forKey: .modelID)
        try c.encode(prompt,             forKey: .prompt)
        try c.encode(messages,           forKey: .messages)
        try c.encode(finishedSize, forKey: .finishedSize)
        try c.encode(generateParameters, forKey: .generateParameters)
        try c.encode(viewData, forKey: .chatViewModelData)
        //    try c.encode(selectedModel.name, forKey: .selectedModel)
        
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
    /// Clears generation metadata
    static let gpuCache = ClearOption(rawValue: 1 << 3)
}

@Observable
class ChatViewModelData: Codable {
  var currentSelectedTab: Int = 0
}
