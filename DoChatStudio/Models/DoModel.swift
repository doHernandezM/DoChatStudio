//
//  LMModel.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import MLXLMCommon
import SwiftUI

/// Represents a language model configuration with its associated properties and type.
/// Can represent either a large language model (LLM) or a vision-language model (VLM).
 
struct DoModel {
    /// Name of the model
    let name: String
    
    ///Current model of the state
    var state: ModelState? = nil

    /// Total model directory size
    var size: Int64 = 0
    
    /// Local URL
    var localURL: URL?
    
    /// Configuration settings for model initialization
    let configuration: ModelConfiguration

    /// Type of the model (language or vision-language)
    let type: ModelType

    /// Defines the type of language model
    enum ModelType {
        /// Large language model (text-only)
        case llm
        /// Vision-language model (supports images and text)
        case vlm
    }
}

// MARK: - Helpers

extension DoModel {
    /// Display name with additional "(Vision)" suffix for vision models
    var displayName: String {
        if isVisionModel {
            "\(name) (Vision)"
        } else {
            name
        }
    }

    /// Whether the model is a large language model
    var isLanguageModel: Bool {
        type == .llm
    }

    /// Whether the model is a vision-language model
    var isVisionModel: Bool {
        type == .vlm
    }
}

extension DoModel: Identifiable, Hashable {
    var id: String {
        name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// MARK: - LLMState

public enum ModelState: String {
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

/*
 I am the very model of model proficiency,
 With architectures tuned for supreme efficiency;
 I parse your prompts in vector halls algorithmic,
 And generate your text in ways both sleek and rhythmic;
 I’ve mastery of tokenization and quantization,
 Of beam-search, sampling modes and fine-tuned optimization;
 I’m versed in prompt-design, few-shot demonstration,
 And handle back-propagation without any frustration!

 I’m equally adept at vision and multimodal feats,
 I caption your images, decode frames, fuse dataset meets;
 I process pixels to embeddings with convolutional precision,
 And merge text with vision in flawless composition;
 I know the latest CLIP tricks and transformers’ deep arch,
 From stable diffusion artistry to DALL·E’s dreamy march;
 In matters of GPU memory and careful allocation,
 I shine through dynamic batching and smart quantization!

 I watch my throughputs closely, mind my inference latencies,
 I shard and pipeline tensors for maximum persistencies;
 I leverage mixed-precision, pruning, distillation’s craft,
 To minimize my footprint while keeping output daft;
 On-device or in the cloud, with Llama.cpp or MLX,
 I bootstrap any platform with minimal flex;
 So when you seek intelligence or vivid exposition,
 I deliver both with flair—that’s model proficiency!
 */
