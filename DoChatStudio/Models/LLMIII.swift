//  LLMRunner.swift
//  DoChatStudio
//
//  Created by Cosas on 6/17/25.
//

import Foundation
import SwiftUI
import MLX
import MLXLMCommon
import MLXLLM

// MARK: - LLMState

public enum LLMState: String {
    case initializing
    case idle
    case preparing
    case thinking
    case generating
    case finishing
    case stopped
    case paused
    case error
    case downloading
    case updating
    
    public var color: Color {
        switch self {
        case .initializing: return .pink
        case .idle:         return .blue
        case .preparing:    return .mint
        case .thinking:     return .teal
        case .generating:   return .cyan
        case .finishing:    return .green
        case .stopped:      return .gray
        case .paused:       return .yellow
        case .error:        return .red
        case .downloading:  return .orange
        case .updating:     return .yellow
        }
    }
}



/// Responsible for loading an LLM container and streaming back generations.
@MainActor
final class LLMRunner: ObservableObject {
    private let modelFactory = LLMModelFactory.shared

    @Published public private(set) var llmState: LLMState = .initializing
    
    @Published var isThinking: Bool = false
    
    @Published public private(set) var publishedOutput: String = ""
    
    @Published public private(set) var output = ""
    
    public var shouldContinuePredicting = false
    public func stopGeneration() {
        self.isThinking = false
            self.llmState   = .stopped
            self.shouldContinuePredicting = false
    }
    

    /// Loads the model from HF and streams the response to stdout.
    public func respond(to prompt: String) async throws {
        
        let startMemory = GPU.snapshot()
        
        
        self.llmState = .preparing
        
        let modelId = "mlx-community/Mistral-7B-Instruct-v0.3-4bit"
        let configuration = ModelConfiguration(id: modelId)
        
//        print(LLMRegistry.shared.models)
        
        let container = try await modelFactory.loadContainer(configuration: configuration)

        if llmState == .stopped {
            llmState = .idle
        }
        
        try await container.perform { context in
            var generatedTokens = ""
            
            await MainActor.run {
                self.llmState = .generating
                self.isThinking = true
                }
            
            let input = try await context.processor.prepare(
                input: UserInput(prompt: prompt)
            )

            let params = GenerateParameters()
            let cache = context.model.newCache(parameters: params)

            let iterator = try TokenIterator(
                input: input,
                model: context.model,
                cache: cache,
                parameters: params
            )
            
            let stream = generate(input: input, context: context, iterator: iterator)


            
            // stream out each chunk as it arrives
            for await partial in stream {
                if let text = partial.chunk {
//                    print(text, terminator: "")
                    generatedTokens += text
                    await self.updateOutputManually(to: generatedTokens)
                    
                }
            }
            await self.updateOutputManually(to: generatedTokens)
            await MainActor.run {
                self.llmState = .finishing
                self.isThinking = false
            }
            
        }
        
        let endMemory = GPU.snapshot()


        // what stats are interesting to you?


        print("=======")
        print("Memory size: \(GPU.memoryLimit / 1024)K")
        print("Cache size:  \(GPU.cacheLimit / 1024)K")


        print("")
        print("=======")
        print("Starting memory")
        print(startMemory.description)


        print("")
        print("=======")
        print("Ending memory")
        print(endMemory.description)


        print("")
        print("=======")
        print("Growth")
        print(startMemory.delta(endMemory).description)
        
    }
    
    @MainActor public func setOutput(to newOutput: consuming String) {
        output = newOutput
    }
    
    @MainActor
    public func updateOutputManually(to newOutput: String) {
        self.publishedOutput = newOutput
        self.setOutput(to: newOutput) // Call the inherited method
    }
}
