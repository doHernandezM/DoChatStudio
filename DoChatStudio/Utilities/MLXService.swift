
//
//  MLXService.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import Foundation
import Hub
import MLX
import MLXLLM
import MLXLMCommon
import MLXVLM

/// A service class that manages machine learning models for text and vision-language tasks.
/// This class handles model loading, caching, and text generation using various LLM and VLM models.
@Observable
class MLXService {
    
    private static let defaultService:MLXService = MLXService()
    
    static var shared: MLXService {
        get {
            return MLXService.defaultService
        }
    }
    
    /// List of available models that can be used for generation.
    /// Includes both language models (LLM) and vision-language models (VLM).
    static var defaultModel:DoModel {
        get {
            return MLXService.availableModels.first!
        }
    }
    
    static var availableModels: [DoModel] = [
        DoModel(name: "llama3.2:1b", configuration: LLMRegistry.llama3_2_1B_4bit, type: .llm),
        DoModel(name: "qwen2.5:1.5b", configuration: LLMRegistry.qwen2_5_1_5b, type: .llm),
        DoModel(name: "smolLM:135m", configuration: LLMRegistry.smolLM_135M_4bit, type: .llm),
        DoModel(name: "qwen3:0.6b", configuration: LLMRegistry.qwen3_0_6b_4bit, type: .llm),
        DoModel(name: "qwen3:1.7b", configuration: LLMRegistry.qwen3_1_7b_4bit, type: .llm),
        DoModel(name: "qwen3:4b", configuration: LLMRegistry.qwen3_4b_4bit, type: .llm),
        DoModel(name: "qwen3:8b", configuration: LLMRegistry.qwen3_8b_4bit, type: .llm),
        DoModel(
            name: "qwen2.5VL:3b", configuration: VLMRegistry.qwen2_5VL3BInstruct4Bit, type: .vlm),
        DoModel(name: "qwen2VL:2b", configuration: VLMRegistry.qwen2VL2BInstruct4Bit, type: .vlm),
        DoModel(name: "smolVLM", configuration: VLMRegistry.smolvlminstruct4bit, type: .vlm),
    ]
    
    static var modelKeys: [String] =
    [
        LLMRegistry.llama3_2_1B_4bit.name,
        LLMRegistry.qwen2_5_1_5b.name,
        LLMRegistry.smolLM_135M_4bit.name,
        LLMRegistry.qwen3_0_6b_4bit.name,
        LLMRegistry.qwen3_1_7b_4bit.name,
        LLMRegistry.qwen3_4b_4bit.name,
        LLMRegistry.qwen3_8b_4bit.name,
        VLMRegistry.qwen2_5VL3BInstruct4Bit.name,
        VLMRegistry.qwen2VL2BInstruct4Bit.name,
        VLMRegistry.smolvlminstruct4bit.name
    ]

    /// Generates text based on the provided messages using the specified model.
    /// - Parameters:
    ///   - messages: Array of chat messages including user, assistant, and system messages
    ///   - model: The language model to use for generation
    /// - Returns: An AsyncStream of generated text tokens
    /// - Throws: Errors that might occur during generation
    var modelContainer: ModelContainer?
    
    func generate(messages: [Message], model: DoModel, parameters: GenerateParameters = GenerateParameters(temperature: 0.7)) async throws -> AsyncStream<Generation> {
        
        if await modelContainer?.configuration.name != model.configuration.name {
            modelContainer = nil
        }
        
        modelContainer = try await model.load(model: model)
        // Load or retrieve model from cache
        if modelContainer == nil {throw ModelLoadError.modelLoad(message: "Model Container not Loaded")}
        model.state = .generating
        
        // Map app-specific Message type to Chat.Message for model input
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

        // Prepare input for model processing
        let userInput = UserInput(
            chat: chat, processing: .init(resize: .init(width: 1024, height: 1024)))

        // Generate response using the model
        return try await modelContainer!.perform { (context: ModelContext) in
            let lmInput = try await context.processor.prepare(input: userInput)
            
            print("TOKES::: ", lmInput.text.tokens.count)
            return try MLXLMCommon.generate(
                input: lmInput, parameters: parameters, context: context)
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
