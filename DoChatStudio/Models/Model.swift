//  Model.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import Foundation
import llama

public typealias Model = OpaquePointer

public typealias DoToken = llama_token

extension Model {
    public var endToken: DoToken { llama_vocab_eos(self) }
    public var newLineToken: DoToken { llama_vocab_nl(self) }
    
    public func shouldAddBOS() -> Bool {
        let addBOS = llama_vocab_get_add_bos(self);
        guard !addBOS else {
            return llama_vocab_type(self) == LLAMA_VOCAB_TYPE_SPM
        }
        return addBOS
    }
    
    public func decodeOnly(_ token: DoToken) -> String {
        var nothing: [CUnsignedChar] = []
        return decode(token, with: &nothing)
    }
    
    public func decode(_ token: DoToken, with multibyteCharacter: inout [CUnsignedChar]) -> String {
        var bufferLength = 16
        var buffer: [CChar] = .init(repeating: 0, count: bufferLength)
        let actualLength = Int(llama_token_to_piece(self, token, &buffer, Int32(bufferLength), 0, false))
        guard 0 != actualLength else { return "" }
        if actualLength < 0 {
            bufferLength = -actualLength
            buffer = .init(repeating: 0, count: bufferLength)
            llama_token_to_piece(self, token, &buffer, Int32(bufferLength), 0, false)
        } else {
            buffer.removeLast(bufferLength - actualLength)
        }
        if multibyteCharacter.isEmpty, let decoded = String(cString: buffer + [0], encoding: .utf8) {
            return decoded
        }
        multibyteCharacter.append(contentsOf: buffer.map { CUnsignedChar(bitPattern: $0) })
        guard let decoded = String(data: .init(multibyteCharacter), encoding: .utf8) else { return "" }
        multibyteCharacter.removeAll(keepingCapacity: true)
        return decoded
    }
    
    public func encode(_ text: borrowing String) -> [DoToken] {
        let addBOS = true
        let count = Int32(text.cString(using: .utf8)!.count)
        var tokenCount = count + 1
        let cTokens = UnsafeMutablePointer<llama_token>.allocate(capacity: Int(tokenCount)); defer { cTokens.deallocate() }
        tokenCount = llama_tokenize(self, text, count, cTokens, tokenCount, addBOS, false)
        let tokens = (0..<Int(tokenCount)).map { cTokens[$0] }
        return tokens
    }

    // Get model metadata by key
    private func getModelMetadata(for key: String) -> String? {
        // Allocate a buffer for the metadata value
        var buffer = [CChar](repeating: 0, count: 256) // Adjust size as needed
        let bufferSize = buffer.count

        // Use withCString to safely pass the key as a C string
        return key.withCString { keyPtr in
            // Use withUnsafeMutableBytes to get a mutable pointer to the buffer's first element
            buffer.withUnsafeMutableBytes { bufferPtr in
                guard let bufferBase = bufferPtr.baseAddress?.assumingMemoryBound(to: CChar.self) else {
                    print("Failed to get buffer base address")
                    return nil
                }

                // Call the C function
                let result = llama_model_meta_val_str(self, keyPtr, bufferBase, bufferSize)

                // If result indicates success, convert the buffer to a String
                if result >= 0 {
                    return String(cString: bufferBase)
                } else {
                    print("Failed to retrieve metadata for key: \(key)")
                    return nil
                }
            }
        }
    }

    // Get model name (e.g., "LLaMA 2 7B Chat")
    public var name: String? {
        return getModelMetadata(for: "general.name")
    }
    
    // Get model architecture (e.g., "LLaMA", "Mistral")
    public var architecture: String? {
        return getModelMetadata(for: "general.architecture")
    }

    // Get model author
    public var author: String? {
        return getModelMetadata(for: "general.author")
    }

    // Get quantization type (e.g., "Q4_K_M", "F16")
    public var quantizationType: String? {
        return getModelMetadata(for: "general.quantization_type")
    }
    
    // Get model size
    public var size: String? {
        return getModelMetadata(for: "general.quantization_type")
    }
    
    
}
