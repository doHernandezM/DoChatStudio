//
//  LLMIII.swift
//  DoChatStudio
//
//  Created by Cosas on 6/17/25.
//

import Foundation
import MLX
import MLXLMCommon
import MLXLLM

@main
struct LLMx {
    static func main() async throws {
        // Load the model and tokenizer directly from HF
        let modelId = "mlx-community/Mistral-7B-Instruct-v0.3-4bit"
        let modelFactory = LLMModelFactory.shared
        let configuration = ModelConfiguration(id: modelId)
        let model = try await modelFactory.loadContainer(configuration: configuration)
        
        try await model.perform({context in
            // Prepare the prompt for the model
            let prompt = "Write a quicksort in Swift"
            let input = try await context.processor.prepare(input: UserInput(prompt: prompt))

            // Create the key-value cache
            let generateParameters = GenerateParameters()
            let cache = context.model.newCache(parameters: generateParameters)

            // Low level token iterator
            let tokenIter = try TokenIterator(input: input,
                                              model: context.model,
                                              cache: cache,
                                              parameters: generateParameters)
            let tokenStream = generate(input: input, context: context, iterator: tokenIter)
            for await part in tokenStream {
                print(part.chunk ?? "", terminator: "")
            }
        })
    }
}
