//
//  MLXService.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

// Bridges app chat data to MLX inference and persists the catalog of custom models.

import Foundation
import Hub
import MLX
import MLXLLM
import MLXLMCommon
import MLXVLM
import SwiftUI

/// A service class that manages machine learning models for text and vision-language tasks.
/// This class handles model loading, caching, and text generation using various LLM and VLM models.
@Observable
class MLXService {
    // MARK: - Custom Model Management
    @MainActor
    @discardableResult
    func removeCustomModel(named name: String) -> Bool {
        guard let index = customModels.firstIndex(where: { $0.name == name }) else {
            return false
        }
        let model = customModels[index]
        // Ensure the model deletes its on-disk folder (also cancels active downloads)
        _ = model.deleteModel()
        // Remove from our custom list; didSet on customModels will persist
        customModels.remove(at: index)
        return true
    }

    @MainActor
    @discardableResult
    func removeCustomModel(_ model: ModelModel) -> Bool {
        return removeCustomModel(named: model.name)
    }
    
    private static let defaultService:MLXService = MLXService()
    
    static var shared: MLXService {
        get {
            return MLXService.defaultService
        }
    }
    
    /// List of available models that can be used for generation.
    /// Includes both language models (LLM) and vision-language models (VLM).
    static var defaultModel:ModelModel {
        get {
            return MLXService.shared.availableModels.first!
        }
    }
    
    init() {
        reconcileCustomModelsOnLaunch()
    }
    
    let availableModels: [ModelModel] = [
        ModelModel(name: "phi3.5:4b", configuration: LLMRegistry.phi3_5_4bit, type: .llm),
        ModelModel(name: "llama3.2:1b", configuration: LLMRegistry.llama3_2_1B_4bit, type: .llm),
        ModelModel(name: "qwen2.5:1.5b", configuration: LLMRegistry.qwen2_5_1_5b, type: .llm),
        ModelModel(name: "smolLM:135m", configuration: LLMRegistry.smolLM_135M_4bit, type: .llm),
        ModelModel(name: "qwen3:0.6b", configuration: LLMRegistry.qwen3_0_6b_4bit, type: .llm),
        ModelModel(name: "qwen3:1.7b", configuration: LLMRegistry.qwen3_1_7b_4bit, type: .llm),
        ModelModel(name: "qwen3:4b", configuration: LLMRegistry.qwen3_4b_4bit, type: .llm),
        ModelModel(name: "qwen3:8b", configuration: LLMRegistry.qwen3_8b_4bit, type: .llm),
        ModelModel(name: "qwen2.5VL:3b", configuration: VLMRegistry.qwen2_5VL3BInstruct4Bit, type: .vlm),
        ModelModel(name: "qwen2VL:2b", configuration: VLMRegistry.qwen2VL2BInstruct4Bit, type: .vlm),
        ModelModel(name: "smolVLM", configuration: VLMRegistry.smolvlminstruct4bit, type: .vlm),
    ]
    
    var customModels: [ModelModel] = [] {
        didSet{
            var storedModels: [ModelRecord] = []
            for model in customModels {
                storedModels.append(ModelRecord(model: model))
            }
            ModelStore().save(storedModels)
        }
    }
    
    var allModels: [ModelModel] {
        return MLXService.shared.customModels + MLXService.shared.availableModels
    }
    

    /// The currently loaded MLX runtime container.
    ///
    /// It is discarded when the selected model changes so the next request is
    /// prepared with the correct tokenizer, processor, and weights.
    var modelContainer: ModelContainer?

    /// Translates application chat state into an MLX generation stream.
    /// - Parameters:
    ///   - messages: Document messages in conversation order.
    ///   - model: Selected LLM or VLM configuration.
    ///   - parameters: Sampling and token limits edited by the UI.
    /// - Returns: MLX text chunks followed by completion information.
    /// - Throws: Model loading, input preparation, or generation errors.
    
    func generate(messages: [Message], model: ModelModel, parameters: GenerateParameters = GenerateParameters(temperature: 0.7)) async throws -> AsyncStream<Generation> {
        
        if await modelContainer?.configuration.name != model.configuration.name {
            modelContainer = nil
        }
        
        // ModelModel selects an LLM/VLM factory and loads local weights, or
        // downloads them from Hugging Face when they are not available.
        modelContainer = try await model.load(model: model)
        if modelContainer == nil {throw ModelLoadError.modelLoad(message: "Model Container not Loaded")}
        await MainActor.run {
            model.state = .generating
            messages.last?.modelState = .generating
        }
        
        // Translate the persistent app schema into MLXLMCommon's chat schema.
        let chat = messages.map { message in
            let role: Chat.Message.Role =
            switch message.role {
            case .prompt:
                    .system
            case .assistant:
                    .assistant
            case .user:
                    .user
            case .system:
                    .system
            }
            
            // Process any attached media for VLM models
            let images: [UserInput.Image] = message.images.map { imageURL in .url(imageURL) }
            let videos: [UserInput.Video] = message.videos.map { videoURL in .url(videoURL) }
            
            return Chat.Message(
                role: role, content: message.content, images: images, videos: videos)
        }
        
        // VLM processors resize attached media while text-only processors use
        // the same UserInput chat without media payloads.
        let userInput = UserInput(
            chat: chat, processing: .init(resize: .init(width: 1024, height: 1024)))
        
        // ModelContainer.perform serializes access to the loaded model context.
        // The returned AsyncStream is consumed by ChatModel and reflected in UI.
        return try await modelContainer!.perform { (context: ModelContext) in
            let lmInput = try await context.processor.prepare(input: userInput)
            
            return try MLXLMCommon.generate(
                input: lmInput, parameters: parameters, context: context)
        }
    }
}

extension MLXService {
    func reconcileCustomModelsOnLaunch() {
        var models: [ModelModel] = []
        
        let records = ModelStore().load()
        // 1) Restore from records
        for rec in records {
            if rec.idString != nil {
                let config = rec.configuration
                let mm = ModelModel(name: rec.name, configuration: config, type: rec.type, isCustomModel: true)
                let url = mm.folderURL
                if url.existsAsDirectory {
                    models.append(mm)
                } else {
                    
                    mm.state = .missing
                    models.append(mm)
                    
                }
            } else if let bookmark = rec.directoryBookmark {
                
                var isStale = false
                do {
#if os(macOS)
                    let url = try URL(
                        resolvingBookmarkData: bookmark,
                        options: [.withSecurityScope],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
                    let _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
#else
                    let url = try URL(
                        resolvingBookmarkData: bookmark,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
#endif
                    
                    if try url.isReachableAsDirectory() {
                        let config = ModelConfiguration(directory: url)
                        let mm = ModelModel(name: rec.name, configuration: config, type: rec.type, isCustomModel: true)
                        models.append(mm)
                    } else {
                        // Missing
                    }
                } catch {
                    // Missing or invalid bookmark
                }
            }
        }
        
        // 2) Discover orphaned but present repos in filesystem
        // e.g., scan ModelModel.modelDirectory and derive repo ids (<owner>/<repo>)
        // Add any that aren’t already represented by a record
        // Optionally persist them as new records, or present as “discovered”
        
        self.customModels = models
    }
}


struct ModelRecord: Codable, Hashable {
    let name: String
    let type: ModelModel.ModelType
    let configuration: ModelConfiguration
    //    let finishedSize: Int?
    let idString: String?
    let directoryBookmark: Data?
    let addedDate: Date
    
    init(name: String, type: ModelModel.ModelType, configuration: ModelConfiguration, idString: String?, directoryBookmark: Data?, addedDate: Date) {
        self.name = name
        self.type = type
        self.configuration = configuration
        self.idString = idString
        self.directoryBookmark = directoryBookmark
        self.addedDate = addedDate
    }
    
    init(model: ModelModel) {
#if os(macOS)
        let data: Data? = try? model.folderURL.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
#else
        let data: Data? = try? model.folderURL.bookmarkData()
#endif
        
        self.init(
            name: model.name,
            type: model.type,
            configuration: model.configuration,
            idString: model.name,
            directoryBookmark: data,
            addedDate: Date()
        )
    }
}

final class ModelStore {
    private let key = "CustomModelRecords"
    private let defaults = UserDefaults.standard
    
    func load() -> [ModelRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([ModelRecord].self, from: data)) ?? []
    }
    
    func save(_ records: [ModelRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: key)
        }
    }
}

extension LLMRegistry {
    
    static public let codeLlama13b4bitx = ModelConfiguration(
        id: "mlx-community/CodeLlama-13b-Instruct-hf-4bit-MLX",
        overrideTokenizer: "PreTrainedTokenizer",
        defaultPrompt: "func sortArray(_ array: [Int]) -> String { <FILL_ME> }"
    )
    
    static public let phi3_5_4bitx = ModelConfiguration(
        id: "mlx-community/Phi-3.5-mini-instruct-4bit",
        defaultPrompt: "What is the gravity on Mars and the moon?",
        extraEOSTokens: ["<|end|>"]
    )
    
    static public let phi3_5MoEx = ModelConfiguration(
        id: "mlx-community/Phi-3.5-MoE-instruct-4bit",
        defaultPrompt: "What is the gravity on Mars and the moon?",
        extraEOSTokens: ["<|end|>"]
    ) {
        prompt in
        "<|user|>\n\(prompt)<|end|>\n<|assistant|>\n"
    }
}

extension GenerateParameters: Codable {
    private enum CodingKeys: String, CodingKey {
        case prefillStepSize
        case maxTokens
        case temperature
        case topP
        case repetitionPenalty
        case repetitionContextSize
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let prefillStepSize = try container.decode(Int.self, forKey: .prefillStepSize)
        let maxTokens = try container.decodeIfPresent(Int.self, forKey: .maxTokens)
        let temperature = try container.decode(Float.self, forKey: .temperature)
        let topP = try container.decode(Float.self, forKey: .topP)
        let repetitionPenalty = try container.decodeIfPresent(Float.self, forKey: .repetitionPenalty)
        let repetitionContextSize = try container.decode(Int.self, forKey: .repetitionContextSize)
        
        // use our designated initializer for all but prefillStepSize
        self.init(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            repetitionPenalty: repetitionPenalty,
            repetitionContextSize: repetitionContextSize
        )
        self.prefillStepSize = prefillStepSize
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prefillStepSize,       forKey: .prefillStepSize)
        try container.encodeIfPresent(maxTokens,     forKey: .maxTokens)
        try container.encode(temperature,            forKey: .temperature)
        try container.encode(topP,                   forKey: .topP)
        try container.encodeIfPresent(repetitionPenalty, forKey: .repetitionPenalty)
        try container.encode(repetitionContextSize,  forKey: .repetitionContextSize)
    }
}
