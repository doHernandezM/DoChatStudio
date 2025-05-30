// Extensions.swift

import Foundation
import SwiftUI
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

// MARK: - LLMOutputDelegate

public protocol LLMOutputDelegate: AnyObject {
    /// Called for every partial token-delta as it arrives.
    func newOutput(outputChat: Chat)
}

// MARK: - StatefulLLM Subclass

/// A subclass of upstream A’s `LLM` that adds SwiftUI-friendly state,
/// delegate callbacks, and recovery hook.
open class StatefulLLM: LLM {
    @Published public private(set) var llmState: LLMState = .initializing
    public weak var delegate: LLMOutputDelegate?

    @Published var isThinking: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    
    public var shouldContinuePredicting = false
    public var shouldPausePredicting = false
    public func stopGeneration() {
        isThinking = false
        shouldPausePredicting = false
        shouldContinuePredicting = false
        self.llmState = .stopped
    }
    
    
    public override init?(
        from path: String,
        stopSequence: String? = nil,
        history: [Chat] = [],
        seed: UInt32 = .random(in: .min ... .max),
        topK: Int32 = 40,
        topP: Float = 0.95,
        temp: Float = 0.8,
        historyLimit: Int = 8,
        maxTokenCount: Int32 = 2048
    ) {
        super.init(
            from: path,
            stopSequence: stopSequence,
            history: history,
            seed: seed,
            topK: topK,
            topP: topP,
            temp: temp,
            historyLimit: historyLimit,
            maxTokenCount: maxTokenCount
        )
        llmState = .idle
    }

    /// Override the recovery hook to emit a "TL;DR" on overflow.
    override open func recoverFromLengthy(
        _ input: String,
        to output: AsyncStream<String>.Continuation
    ) {
        output.yield("TL;DR")
        llmState = .error
    }
    
    override open func respond(to input: String) async {
        await respond(to: input) { [weak self] response in
            guard let self = self else { return "" }
            llmState = .preparing
            await self.setOutput(to: "")
            llmState = .generating
            
            for await responseDelta in response {
                self.update(responseDelta)
                await self.setOutput(to: self.output + responseDelta)
                self.delegate?.newOutput(outputChat: (.bot, responseDelta))
                }
            self.update(nil)
            
            let trimmedOutput = self.output.trimmingCharacters(in: .whitespacesAndNewlines)
            llmState = .finishing
            await self.setOutput(to: trimmedOutput.isEmpty ? "..." : trimmedOutput)
            llmState = .idle
            return self.output
            
            
        }
    }
}
//
//// MARK: - Performance Extensions on LLMCore
//
//public struct LlamaPerfContextData {
//    public let tStartMs: Double
//    public let tLoadMs: Double
//    public let tPEvalMs: Double
//    public let tEvalMs: Double
//    public let nPEval: Int
//    public let nEval: Int
//}
//
//extension LLMCore {
//    /// Returns a string with system information from llama.
//    public func systemInfo() -> String {
//        guard let cStr = llama_print_system_info() else { return "" }
//        return String(cString: cStr)
//    }
//
//    /// Returns performance metrics for the current context.
//    public func perfContextData() -> LlamaPerfContextData? {
//        let data = llama_perf_context(self.context)
//        return LlamaPerfContextData(
//            tStartMs: data.t_start_ms,
//            tLoadMs: data.t_load_ms,
//            tPEvalMs: data.t_p_eval_ms,
//            tEvalMs: data.t_eval_ms,
//            nPEval: Int(data.n_p_eval),
//            nEval: Int(data.n_eval)
//        )
//    }
//
//    /// Resets performance counters in the current context.
//    public func resetPerfContext() {
//        llama_perf_context_reset(self.context)
//    }
//}
//
//// MARK: - Helpers for llama_batch
//
//extension llama_batch {
//    /// Clears all tokens from the batch.
//    mutating func clear() {
//        self.n_tokens = 0
//    }
//
//    /// Adds a token to the batch.
//    mutating func add(
//        _ token: llama_token,
//        _ position: Int32,
//        _ ids: [Int32],
//        _ logit: Bool
//    ) {
//        let i = Int(self.n_tokens)
//        self.token[i]    = token
//        self.pos[i]      = position
//        self.n_seq_id[i] = Int32(ids.count)
//        if let seq = self.seq_id[i] {
//            for (j, id) in ids.enumerated() {
//                seq[j] = id
//            }
//        }
//        self.logits[i]   = logit ? 1 : 0
//        self.n_tokens   += 1
//    }
//}
