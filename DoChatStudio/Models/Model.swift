//  Model.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import Foundation
//import llama

public typealias Model = OpaquePointer

//public typealias DoToken = llama_token
//
//extension Model {
//
//    // Get model name (e.g., "LLaMA 2 7B Chat")
//    public var name: String? {
//        return getModelMetadata(for: "general.name")
//    }
//    
//    // Get model architecture (e.g., "LLaMA", "Mistral")
//    public var architecture: String? {
//        return getModelMetadata(for: "general.architecture")
//    }
//
//    // Get model author
//    public var author: String? {
//        return getModelMetadata(for: "general.author")
//    }
//
//    // Get quantization type (e.g., "Q4_K_M", "F16")
//    public var quantizationType: String? {
//        return getModelMetadata(for: "general.quantization_type")
//    }
//    
//    // Get model size
//    public var size: String? {
//        return getModelMetadata(for: "general.quantization_type")
//    }
//    
//    
//}
