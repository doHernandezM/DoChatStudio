// StatefulLLM.swift

import Foundation
import SwiftUI
import llama
import LLM

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

// MARK: - StatefulLLM Subclass

/// A subclass of upstream A’s `LLM` that adds SwiftUI-friendly state,
/// delegate callbacks, and recovery hook.
@MainActor
open class StatefulLLM: LLM {
    @Published public private(set) var llmState: LLMState = .initializing
    
    @Published var isThinking: Bool = false
    
    @Published public private(set) var publishedOutput: String = ""
    
    public var shouldContinuePredicting = false
//    public var shouldPausePredicting = false
    public func stopGeneration() {
        self.isThinking = false
            self.llmState   = .stopped

//            self.shouldPausePredicting    = false
            self.shouldContinuePredicting = false


        super.stop()
        
    }
    
    override open func respond(to input: String) async {
        
        if llmState == .stopped {
            llmState = .idle
        }
        self.shouldContinuePredicting = true
        self.llmState = .preparing
        self.isThinking = true
        self.updateOutputManually(to: "")
    
        
        await respond(to: input) { [weak self] responseStream in
            guard let self else { return "" }

            
            await MainActor.run { self.llmState = .generating }
            
            var collected = ""
            
            for await responseDelta in responseStream {
//                // Check for pause
//                if self.shouldPausePredicting {
//                    await MainActor.run { self.llmState = .paused }
//                    repeat {
//                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
//                    } while self.shouldPausePredicting && self.shouldContinuePredicting
//                    
//                    await MainActor.run {
//                        if self.shouldContinuePredicting {
//                            self.llmState = .generating
//                        }
//                    }
//                }
                
                // Check for stop
                guard self.shouldContinuePredicting else {
                    print("⚠️ Generation stopped early")
                    break
                }
                
               self.update(responseDelta)
                collected += responseDelta
                self.updateOutputManually(to: collected)
                
            }
            
            self.update(nil)
            
            // Final cleanup
            let trimmed = collected.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalOutput = trimmed.isEmpty ? "..." : trimmed
            self.updateOutputManually(to: finalOutput)
            
            await MainActor.run {
                self.llmState = .finishing
                self.isThinking = false
            }
            self.postprocess(finalOutput)
            await MainActor.run { self.llmState = .idle }
            
            return finalOutput
        }
        
    }
    
    @MainActor
    public func updateOutputManually(to newOutput: String) {
        self.publishedOutput = newOutput
        self.setOutput(to: newOutput) // Call the inherited method
    }
    
    
}
