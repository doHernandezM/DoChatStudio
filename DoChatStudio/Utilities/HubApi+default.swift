//
//  HubApi+default.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

// Extends the Hugging Face Hub client with model metadata, README, and configuration requests.

import CryptoKit
import Foundation
import Network
import os
@preconcurrency import Hub
import MLX
import MLXLMCommon
import Hub

/// Extension providing a default HubApi instance for downloading model files
//extension HubApi {
//    /// Default HubApi instance configured to download models to the user's Downloads directory
//    /// under a 'huggingface' subdirectory.
//#if os(macOS)
//    static let `default` = HubApi(
//        downloadBase: URL.documentsDirectory.appending(path: "doChat"), useOfflineMode: false
//    )
//#else
//    static let `default` = HubApi(
//        downloadBase: URL.documentsDirectory.appending(path: "doChat"), useOfflineMode: false
//    )
//#endif
//
//}
struct HFModelInfo: Decodable {
    let id: String
    let modelId: String?
    let pipeline_tag: String?
    let tags: [String]?
    let likes: Int?
    let downloads: Int?
    let cardData: [String: String]?
    // Add more fields as needed (see HF docs)
}

extension HubApi {
    func fetchModelInfo(repoId: String, baseURL: URL = URL(string: "https://huggingface.co")!, token: String? = nil) async throws -> HFModelInfo {
        let url = baseURL.appending(path: "api").appending(path: "models").appending(path: repoId)
        var request = URLRequest(url: url)
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(HFModelInfo.self, from: data)
    }
    
    func fetchModelCardMarkdown(repoId: String, revision: String = "main", baseURL: URL = URL(string: "https://huggingface.co")!, token: String? = nil) async throws -> String? {
        let url = baseURL.appending(path: repoId).appending(path: "resolve").appending(path: revision).appending(path: "README.md")

        var request = URLRequest(url: url)
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return String(data: data, encoding: .utf8)
    }
}

struct HFModelConfig: Decodable {
    let architectures: [String]?
    let vocab_size: Int?
    let max_position_embeddings: Int?
    // Add other fields as needed
}

extension HubApi {
    func fetchModelConfig(repoId: String, revision: String = "main", baseURL: URL = URL(string: "https://huggingface.co")!, token: String? = nil) async throws -> HFModelConfig {
        let url = baseURL.appending(path: repoId).appending(path: "resolve").appending(path: revision).appending(path: "config.json")
        var request = URLRequest(url: url)
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(HFModelConfig.self, from: data)
    }
    
    func makeModelConfiguration(repoId: String, hf: HFModelConfig) -> ModelConfiguration {
        let arch = hf.architectures?.first?.lowercased() ?? ""
        
        var defaultPrompt = "hello"
        var extraEOSTokens: Set<String> = []
        var overrideTokenizer: String? = nil
        var tokenizerId: String? = nil
        
        // Heuristics per family; extend as you learn more models
        switch arch {
        case let s where s.contains("llama"):
            // Llama-family defaults
            defaultPrompt = "You are a helpful assistant."
            // Llama 3 often uses chat templates; you can leave EOS tokens empty here.
            
        case let s where s.contains("phi"):
            // Phi-family often uses <|end|> as an EOS
            defaultPrompt = "What is the gravity on Mars and the moon?"
            extraEOSTokens.insert("<|end|>")
            
        case let s where s.contains("qwen"):
            // Qwen-family prompt style
            defaultPrompt = "You are a helpful assistant."
            
        case let s where s.contains("mistral"):
            defaultPrompt = "You are a helpful assistant."
            
        default:
            defaultPrompt = "hello"
        }
        
        let newModel = ModelConfiguration(
            id: repoId,
            tokenizerId: tokenizerId,
            overrideTokenizer: overrideTokenizer,
            defaultPrompt: defaultPrompt,
            extraEOSTokens: extraEOSTokens)
        
            print("newCustomConfig: \(newModel)")
            return newModel
    }
    
    func configurationFromHF(repoId: String, revision: String = "main", token: String? = nil) async throws -> ModelConfiguration {
        let hf = try await fetchModelConfig(repoId: repoId, revision: revision, token: token)
        return makeModelConfiguration(repoId: repoId, hf: hf)
    }
}
