////LLM.swift
//
//import Foundation
//import SwiftUI
//import llama
//
//public typealias Token = llama_token
//
//// Add DeltaInfo struct
//struct DeltaInfo {
//    let tokensAdded: Int
//}
//
//@globalActor public actor InferenceActor {
//    static public let shared = InferenceActor()
//}
//
//
//    
//public enum LLMState: String {
//    // The model is loading, initializing, or being set up.
//    case initializing = "Initializing"
//    
//    // The model is ready and waiting for input.
//    case idle = "Idle"
//    
//    // The model is processing the input (e.g., tokenizing or setting context).
//    case preparing = "Preparing"
//    
//    // The model is in the process of generating tokens.
//    case thinking = "Thinking"
//    
//    // Actively generating a response from the model.
//    case generating = "Generating"
//    
//    // The model is finalizing or wrapping up the output.
//    case finishing = "Finishing"
//    
//    // The generation has been interrupted (e.g., by a stop request).
//    case stopped = "Stopped"
//    
//    // The generation has been paused.
//    case paused = "Paused"
//    
//    // The model encountered an error or needs to recover.
//    case error = "Error"
//    
//    // Additional states that may be useful:
//    
//    // When the model is downloading resources (e.g., from Hugging Face).
//    case downloading = "Downloading"
//    
//    // When updating progress or performing minor adjustments.
//    case updating = "Updating"
//    
//    var color: Color {
//        get {
//            var llmColor: Color? = nil
//            switch self {
//            case .initializing:
//                llmColor = .pink
//            case .idle:
//                llmColor = .blue
//            case .preparing:
//                llmColor = .mint
//            case .thinking:
//                llmColor = .teal
//            case .generating:
//                llmColor = .cyan
//            case .finishing:
//                llmColor = .green
//            case .stopped:
//                llmColor = .gray
//            case .paused:
//                llmColor = .yellow.mix(with: .blue, by: 0.1)
//            case .error:
//                llmColor = .red
//            case .downloading:
//                llmColor = .orange
//            case .updating:
//                llmColor = .yellow
//            }
//            return llmColor == nil ? .gray : llmColor!
//        }
//    }
//}
//    /// A protocol to receive updates when the LLM's output changes.
//    public protocol LLMOutputDelegate: AnyObject {
//        //    var rawOutputString: String { get set }
//        /// Called whenever the LLM's output is updated.
//        /// - Parameter output: The new output string.
//        func newOutput(outputChat: Chat)
//    }
//    
////LLM.swift
//
//open class LLM: ObservableObject {
//    @Published public var llmState: LLMState = LLMState.initializing
//
//    @Published public var model: Model
//    public var path: [CChar]
//    
//    //Model Info
//    @Published public var modelName: String = ""
//    @Published public var modelArchitecture: String = ""
//    @Published public var modelAuthor: String = ""
//    @Published public var modelQuantizationType: String = ""
//    
//    //Thinking
//    public var preprocess: (_ input: String, _ history: [Chat]) -> String = { input, _ in return input }
//    public var postprocess: (_ output: String) -> Void = { print($0) }
//    public var update: (_ outputDelta: String?) -> Void = { _ in }
//    public var template: Template? = nil {
//        didSet {
//            guard let template else {
//                preprocess = { input, _ in return input }
//                stopSequence = nil
//                stopSequenceLength = 0
//                return
//            }
//            preprocess = template.preprocess
//            if let stopSequence = template.stopSequence?.utf8CString {
//                self.stopSequence = stopSequence
//                stopSequenceLength = stopSequence.count - 1
//            } else {
//                stopSequence = nil
//                stopSequenceLength = 0
//            }
//        }
//    }
//    
//    @Published public var seed: UInt32
//    @Published public var topK: Int32
//    @Published public var topP: Float
//    @Published public var temp: Float
//    public var history: [Chat]
//    @Published public var historyLimit: Int32
//    
//    //    public weak var delegate: LLMOutputDelegate?
//    
//    @Published public private(set) var output = ""
//    
//    @MainActor public func setOutput(to newOutput: consuming String) {
//        self.output = newOutput
//    }
//    
//    @Published var isThinking: Bool = false {
//        willSet {
//            objectWillChange.send()
//        }
//    }
//    
//    private var context: Context!
//    private var batch: llama_batch!
//    private let maxTokenCount: Int
//    private let totalTokenCount: Int
//    private let newlineToken: Token
//    public private(set) var stopSequence: ContiguousArray<CChar>?
//    private var stopSequenceLength: Int
//    public private(set) var params: llama_context_params
//    private var isFull = false
//    
//    private var updateProgress: (Double) -> Void = { _ in }
//    
//    public init?(
//        from path: String,
//        stopSequence: String? = nil,
//        history: [Chat] = [],
//        seed: UInt32 = .random(in: .min ... .max),
//        topK: Int32 = 40,
//        topP: Float = 0.95,
//        temp: Float = 0.6,
//        historyLimit: Int32 = 8,
//        maxTokenCount: Int32 = 2048
//    ) {
//        self.path = path.cString(using: .utf8)!
//        var modelParams = llama_model_default_params()
//#if targetEnvironment(simulator)
//        modelParams.n_gpu_layers = 0
//#endif
//        let model = llama_load_model_from_file(self.path, modelParams)
//        if UnsafeRawPointer(model) == nil {
//            // Model failed to load; handle the error.
//            print("Error: Model could not be loaded from path \(self.path)")
//            self.llmState = .error
//            return nil
//        }
//        
//        llmState = .initializing
//        params = llama_context_default_params()
//        let processorCount = Int32(ProcessInfo().processorCount)
//        self.maxTokenCount = Int(min(maxTokenCount, llama_n_ctx_train(model)))
//        params.n_ctx = UInt32(self.maxTokenCount)
//        params.n_batch = params.n_ctx
//        params.n_threads = processorCount
//        params.n_threads_batch = processorCount
//        self.seed = seed
//        self.topK = topK
//        self.topP = topP
//        self.temp = temp
//        self.historyLimit = historyLimit
//        self.model = model!
//        self.history = history
//        self.totalTokenCount = Int(llama_n_vocab(model!))
//        self.newlineToken = model!.newLineToken
//        self.stopSequence = stopSequence?.utf8CString
//        self.stopSequenceLength = (self.stopSequence?.count ?? 1) - 1
//        batch = llama_batch_init(Int32(self.maxTokenCount), 0, 1)
//        self.llmState = .idle
//        objectWillChange.send()
//    }
//    
//    deinit {
//        llama_free_model(model)
//    }
//    
//    public convenience init?(
//        from url: URL,
//        stopSequence: String? = nil,
//        history: [Chat] = [],
//        seed: UInt32 = .random(in: .min ... .max),
//        topK: Int32 = 40,
//        topP: Float = 0.95,
//        temp: Float = 0.8,
//        historyLimit: Int32 = 8,
//        maxTokenCount: Int32 = 2048
//    ) {
//        self.init(
//            from: url.path,
//            stopSequence: stopSequence,
//            history: history,
//            seed: seed,
//            topK: topK,
//            topP: topP,
//            temp: temp,
//            historyLimit: historyLimit,
//            maxTokenCount: maxTokenCount
//        )
//    }
//    
//    public convenience init?(
//        from huggingFaceModel: HuggingFaceModel,
//        to url: URL = .documentsDirectory,
//        as name: String? = nil,
//        history: [Chat] = [],
//        seed: UInt32 = .random(in: .min ... .max),
//        topK: Int32 = 40,
//        topP: Float = 0.95,
//        temp: Float = 0.6,
//        historyLimit: Int32 = 8,
//        maxTokenCount: Int32 = 2048,
//        updateProgress: @escaping (Double) -> Void = { print(String(format: "downloaded(%.2f%%)", $0 * 100)) }
//    ) async throws {
//        let url = try await huggingFaceModel.download(to: url, as: name) { progress in
//            Task { await MainActor.run { updateProgress(progress) } }
//        }
//        self.init(
//            from: url,
//            template: huggingFaceModel.template,
//            history: history,
//            seed: seed,
//            topK: topK,
//            topP: topP,
//            temp: temp,
//            historyLimit: historyLimit,
//            maxTokenCount: maxTokenCount
//        )
//        self.updateProgress = updateProgress
//    }
//    
//    public convenience init?(
//        from url: URL,
//        template: Template,
//        history: [Chat] = [],
//        seed: UInt32 = .random(in: .min ... .max),
//        topK: Int32 = 40,
//        topP: Float = 0.95,
//        temp: Float = 0.6,
//        historyLimit: Int32 = 8,
//        maxTokenCount: Int32 = 2048
//    ) {
//        self.init(
//            from: url.path,
//            stopSequence: template.stopSequence,
//            history: history,
//            seed: seed,
//            topK: topK,
//            topP: topP,
//            temp: temp,
//            historyLimit: historyLimit,
//            maxTokenCount: maxTokenCount
//        )
//        self.preprocess = template.preprocess
//        self.template = template
//    }
//    
//    public var shouldContinuePredicting = false
//    public var shouldPausePredicting = false
//    public func stop() {
//        isThinking = false
//        shouldPausePredicting = false
//        shouldContinuePredicting = false
//        self.llmState = .stopped
//    }
//    
//    @InferenceActor
//    private func predictNextToken() async -> Token {
//        guard shouldContinuePredicting else { return model.endToken }
//        
//        let samplerParams = llama_sampler_chain_default_params()
//        let sampler = llama_sampler_chain_init(samplerParams)
//        
//        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(topK))
//        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(topP, 1))
//        llama_sampler_chain_add(sampler, llama_sampler_init_temp(temp))
//        llama_sampler_chain_add(sampler, llama_sampler_init_dist(seed))
//
//        let i = batch.n_tokens - 1
//        let token = llama_sampler_sample(sampler, context.pointer, i)
//
//        if token == model.endToken {
//            shouldContinuePredicting = false  // Ensure stopping condition is set
//        }
//        
//        batch.clear()
//        batch.add(token, currentCount, [0], true)
//        context.decode(batch)
//
//        return token
//    }
//    
//    private var currentCount: Int32!
//    private var decoded = ""
//    
//    open func recoverFromLengthy(_ input: borrowing String, to output: borrowing AsyncStream<String>.Continuation) {
//        output.yield("tl;dr")
//    }
//    
//    private func prepare(from input: borrowing String, to output: borrowing AsyncStream<String>.Continuation) -> Bool {
//        guard !input.isEmpty else { return false }
//        context = .init(model, params)
//        var tokens = encode(input)
//        var initialCount = tokens.count
//        currentCount = Int32(initialCount)
//        if maxTokenCount <= currentCount {
//            while !history.isEmpty && maxTokenCount <= currentCount {
//                history.removeFirst(min(2, history.count))
//                tokens = encode(preprocess(self.input, history))
//                initialCount = tokens.count
//                currentCount = Int32(initialCount)
//            }
//            if maxTokenCount <= currentCount {
//                isFull = true
//                recoverFromLengthy(input, to: output)
//                self.llmState = .error
//                return false
//            }
//        }
//        for (i, token) in tokens.enumerated() {
//            batch.n_tokens = Int32(i)
//            batch.add(token, batch.n_tokens, [0], i == initialCount - 1)
//        }
//        context.decode(batch)
//        self.shouldContinuePredicting = true
//        
//        return true
//    }
//    
//    @InferenceActor
//    private func finishResponse(from response: inout [String], to output: borrowing AsyncStream<String>.Continuation) async {
//        multibyteCharacter.removeAll()
//        await MainActor.run { self.llmState = .finishing }
//        
//        var input = ""
//        if !history.isEmpty {
//            history.removeFirst(min(2, history.count))
//            input = preprocess(self.input, history)
//        } else {
//            response.scoup(response.count / 3)
//            input = preprocess(self.input, history)
//            input += response.joined()
//        }
//        let rest = getResponse(from: input)
//        for await restDelta in rest {
//            output.yield(restDelta)
//        }
//        
//        await MainActor.run { self.llmState = .idle }
//    }
//    
//    private func process(_ token: Token, to output: borrowing AsyncStream<String>.Continuation) -> Bool {
//        struct saved {
//            static var stopSequenceEndIndex = 0
//            static var letters: [CChar] = []
//        }
//        guard token != model.endToken else { return false }
//        var word = decode(token)
//        guard let stopSequence else { output.yield(word); return true }
//        var found = 0 < saved.stopSequenceEndIndex
//        var letters: [CChar] = []
//        for letter in word.utf8CString {
//            guard letter != 0 else { break }
//            if letter == stopSequence[saved.stopSequenceEndIndex] {
//                saved.stopSequenceEndIndex += 1
//                found = true
//                saved.letters.append(letter)
//                guard saved.stopSequenceEndIndex == stopSequenceLength else { continue }
//                saved.stopSequenceEndIndex = 0
//                saved.letters.removeAll()
//                return false
//            } else if found {
//                saved.stopSequenceEndIndex = 0
//                if !saved.letters.isEmpty {
//                    word = String(cString: saved.letters + [0]) + word
//                    saved.letters.removeAll()
//                }
//                output.yield(word)
//                return true
//            }
//            letters.append(letter)
//        }
//        if !letters.isEmpty { output.yield(found ? String(cString: letters + [0]) : word) }
//        return true
//    }
//    
//    private func getResponse(from input: String) -> AsyncStream<String> {
//        .init { output in Task {
//            await MainActor.run { self.llmState = .preparing }
//            
//            defer { context = nil }
//            guard prepare(from: input, to: output) else { return output.finish() }
//            var response: [String] = []
//            
//            await MainActor.run { self.llmState = .generating }
//            
//            // Main token-generation loop
//            while currentCount < maxTokenCount {
//                // Check for termination condition
//                if !shouldContinuePredicting {
//                    break
//                }
//                
//                // Handle pause/resume efficiently
//                if shouldPausePredicting {
//                    await MainActor.run {
//                        if self.llmState != .paused {
//                            self.llmState = .paused
//                        }
//                    }
//                    
//                    repeat {
//                        try await Task.sleep(nanoseconds: 50_000_000)
//                    } while shouldPausePredicting && shouldContinuePredicting
//                    
//                    // Resume generation only if it's still running
//                    await MainActor.run {
//                        if shouldContinuePredicting {
//                            self.llmState = .generating
//                        }
//                    }
//                }
//                
//                let token = await predictNextToken()
//                if !process(token, to: output) { break }
//                currentCount += 1
//            }
//            
//            // Only finish response if not forcibly stopped.
//            if shouldContinuePredicting {
//                await finishResponse(from: &response, to: output)
//            }
//            
//            return output.finish()
//        }}
//    }
//    
//    private var input: String = ""
//    private var isAvailable = true
//    
//    @InferenceActor
//    public func getCompletion(from input: borrowing String) async -> String {
//        await MainActor.run { self.llmState = .thinking }
//        
//        guard isAvailable else { fatalError("LLM is being used") }
//        isAvailable = false
//        let response = getResponse(from: input)
//        var output = ""
//        for await responseDelta in response {
//            output += responseDelta
//        }
//        isAvailable = true
//        await MainActor.run { self.llmState = .idle }
//        return output
//    }
//    
//    @InferenceActor
//    public func respond(to input: String, with makeOutputFrom: @escaping (AsyncStream<String>) async -> String) async {
//        guard isAvailable else { return }
//        isAvailable = false
//        self.input = input
//        history += [Chat(role: .user, content: input)]
//        
//        let processedInput = preprocess(input, history)
//        let response = getResponse(from: processedInput)
//        
//        let output = await makeOutputFrom(response)
//        
//        // delegate
//        let outputChat = Chat(role: .bot, content: output)
//        history += [outputChat]
//        
//        let historyCount = history.count
//        if historyLimit < historyCount {
//            history.removeFirst(min(2, historyCount))
//        }
//        await MainActor.run { self.llmState = .finishing }
//        
//        postprocess(output)
//        
//        await MainActor.run { self.llmState = .idle }
//        
//        isAvailable = true
//    }
//    
//    open func respond(to input: String) async {
//        let baseline = baselineMemoryInfo()
//        print("Baseline: \(baseline)\n\n")
//        
//        await respond(to: input) { [self] response in
//            await setOutput(to: "")
//            for await responseDelta in response {
////                print(String(format: "Current Memory Usage : %.02f GB\n\n", (Double(currentMemoryUsage()) / 1024.0 / 1024.0 / 1024.0)))
//                update(responseDelta)
//                await setOutput(to: output + responseDelta)
//            }
//            update(nil)
//            let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
//            await setOutput(to: trimmedOutput.isEmpty ? "..." : trimmedOutput)
//            return output
//        }
//    }
//    
//    private var multibyteCharacter: [CUnsignedChar] = []
//    private func decode(_ token: Token) -> String {
//        return model.decode(token, with: &multibyteCharacter)
//    }
//    
//    public func decode(_ tokens: [Token]) -> String {
//        return tokens.map({model.decodeOnly($0)}).joined()
//    }
//    
//    @inlinable
//    public func encode(_ text: borrowing String) -> [Token] {
//        model.encode(text)
//    }
//    
//    /// Returns baseline memory info: the model’s weight size (in bytes) and a system info string.
//    public func baselineMemoryInfo() -> (modelSize: UInt64, systemInfo: String?) {
//        // Convert the opaque pointer to an UnsafeMutableRawPointer.
//        let info = llama_wrapper_get_baseline_memory_info(UnsafeMutableRawPointer(model))
//        let size = info.model_size_bytes
//        let sysInfo: String? = info.system_info != nil ? String(cString: info.system_info) : nil
//        // Free the allocated system_info string.
//        var mutableInfo = info
//        llama_free_baseline_memory_info(&mutableInfo)
//        return (modelSize: size, systemInfo: sysInfo)
//    }
//    
//    /// Returns an estimate of current memory usage (in bytes) based on the state size.
////    public func currentMemoryUsage() -> UInt64 {
////        return llama_wrapper_get_current_memory_usage(UnsafeMutableRawPointer(context.pointer))
////    }
//}
//
//
//
//
//private class Context {
//    let pointer: OpaquePointer
//    init(_ model: Model, _ params: llama_context_params) {
//        self.pointer = llama_new_context_with_model(model, params)
//    }
//    deinit {
//        llama_free(pointer)
//    }
//    func decode(_ batch: llama_batch) {
//        guard llama_decode(pointer, batch) == 0 else { fatalError("llama_decode failed") }
//    }
//}
//
//extension llama_batch {
//    mutating func clear() {
//        self.n_tokens = 0
//    }
//    
//    mutating func add(_ token: Token, _ position: Int32, _ ids: [Int], _ logit: Bool) {
//        let i = Int(self.n_tokens)
//        self.token[i] = token
//        self.pos[i] = position
//        self.n_seq_id[i] = Int32(ids.count)
//        if let seq_id = self.seq_id[i] {
//            for (j, id) in ids.enumerated() {
//                seq_id[j] = Int32(id)
//            }
//        }
//        self.logits[i] = logit ? 1 : 0
//        self.n_tokens += 1
//    }
//}
//
//extension [String] {
//    mutating func scoup(_ count: Int) {
//        guard 0 < count else { return }
//        let firstIndex = count
//        let lastIndex = count * 2
//        self.removeSubrange(firstIndex..<lastIndex)
//    }
//}
//
//public enum Role: String, Codable {
//    case user
//    case bot
//}
//
//public struct Template {
//    public typealias Attachment = (prefix: String, suffix: String)
//    public let system: Attachment
//    public let user: Attachment
//    public let bot: Attachment
//    public let systemPrompt: String?
//    public let stopSequence: String?
//    public let prefix: String
//    public let shouldDropLast: Bool
//    
//    public init(
//        prefix: String = "",
//        system: Attachment? = nil,
//        user: Attachment? = nil,
//        bot: Attachment? = nil,
//        stopSequence: String? = nil,
//        systemPrompt: String?,
//        shouldDropLast: Bool = false
//    ) {
//        self.system = system ?? ("", "")
//        self.user = user  ?? ("", "")
//        self.bot = bot ?? ("", "")
//        self.stopSequence = stopSequence
//        self.systemPrompt = systemPrompt
//        self.prefix = prefix
//        self.shouldDropLast = shouldDropLast
//    }
//    
//    public var preprocess: (_ input: String, _ history: [Chat]) -> String {
//        return { [self] input, history in
//            var processed = prefix
//            if let systemPrompt {
//                processed += "\(system.prefix)\(systemPrompt)\(system.suffix)"
//            }
//            for chat in history {
//                if chat.role == .user {
//                    processed += "\(user.prefix)\(chat.content)\(user.suffix)"
//                } else {
//                    processed += "\(bot.prefix)\(chat.content)\(bot.suffix)"
//                }
//            }
//            processed += "\(user.prefix)\(input)\(user.suffix)"
//            if shouldDropLast {
//                processed += bot.prefix.dropLast()
//            } else {
//                processed += bot.prefix
//            }
//            return processed
//        }
//    }
//    
//    public var preprocessJinja: (_ input: String, _ history: [Chat]) -> String {
//        return { [self] input, history in
//            var prompt = ""
//            
//            // Optionally add a BOS token if your template's prefix is used for that.
//            prompt += self.prefix
//            
//            // Add the system prompt (if any), ensuring a trailing newline.
//            if let systemPrompt = self.systemPrompt {
//                prompt += "\(self.system.prefix)\(systemPrompt)\(self.system.suffix)"
//            }
//            
//            // Iterate over the chat history.
//            for chat in history {
//                // Use Jinja-style markers:
//                if chat.role == .user {
//                    // Each user message starts with the marker and ends with a newline.
//                    prompt += "<｜User｜>" + chat.content + "\n"
//                } else {
//                    // Assistant messages are wrapped with the assistant marker and
//                    // terminated with the stop sequence followed by a newline.
//                    prompt += "<｜Assistant｜>" + chat.content + "<｜end▁of▁sentence｜>\n"
//                }
//            }
//            
//            // Append the current user input as a new message.
//            prompt += "<｜User｜>" + input + "\n"
//            
//            // Append an assistant marker to signal that generation should begin.
//            prompt += "<｜Assistant｜>"
//            
//            return prompt
//        }
//    }
//    
//    public static func chatML(_ systemPrompt: String? = nil) -> Template {
//        return Template(
//            system: ("<|im_start|>system\n", "<|im_end|>\n"),
//            user: ("<|im_start|>user\n", "<|im_end|>\n"),
//            bot: ("<|im_start|>assistant\n", "<|im_end|>\n"),
//            stopSequence: "<|im_end|>",
//            systemPrompt: systemPrompt
//        )
//    }
//    
//    public static func alpaca(_ systemPrompt: String? = nil) -> Template {
//        return Template(
//            system: ("", "\n\n"),
//            user: ("### Instruction:\n", "\n\n"),
//            bot: ("### Response:\n", "\n\n"),
//            stopSequence: "###",
//            systemPrompt: systemPrompt
//        )
//    }
//    
//    public static func llama(_ systemPrompt: String? = nil) -> Template {
//        return Template(
//            prefix: "[INST] ",
//            system: ("<<SYS>>\n", "\n<</SYS>>\n\n"),
//            user: ("", " [/INST]"),
//            bot: (" ", "</s><s>[INST] "),
//            stopSequence: "</s>",
//            systemPrompt: systemPrompt,
//            shouldDropLast: true
//        )
//    }
//    
//    public static let mistral = Template(
//        user: ("[INST] ", " [/INST]"),
//        bot: ("", "</s> "),
//        stopSequence: "</s>",
//        systemPrompt: nil
//    )
//    
//    public static func customJinja(_ systemPrompt: String? = nil) -> Template {
//        return Template(
//            prefix: "", // no extra prefix; caller is expected to provide BOS separately if needed
//            system: ("", "\n"), // system prompt (if any) is printed with a trailing newline
//            user: ("<｜User｜>", "\n"), // user messages are wrapped with these markers and end with a newline
//            bot: ("<｜Assistant｜>", "<｜end▁of▁sentence｜>\n"), // assistant messages are wrapped with these markers
//            stopSequence: "<｜end▁of▁sentence｜>", // used to signal generation end
//            systemPrompt: systemPrompt,
//            shouldDropLast: false
//        )
//    }
//}
//
//public enum Quantization: String, CaseIterable {
//    case IQ1_S
//    case IQ1_M
//    case IQ2_XXS
//    case IQ2_XS
//    case IQ2_S
//    case IQ2_M
//    case Q2_K_S
//    case Q2_K
//    case IQ3_XXS
//    case IQ3_XS
//    case IQ3_S
//    case IQ3_M
//    case Q3_K_S
//    case Q3_K_M
//    case Q3_K_L
//    case IQ4_XS
//    case IQ4_NL
//    case Q4_0
//    case Q4_1
//    case Q4_K_S
//    case Q4_K_M
//    case Q5_0
//    case Q5_1
//    case Q5_K_S
//    case Q5_K_M
//    case Q6_K
//    case Q8_0
//}
//
//public enum HuggingFaceError: Error {
//    case network(statusCode: Int)
//    case noFilteredURL
//    case urlIsNilForSomeReason
//}
//
//public struct HuggingFaceModel {
//    public let name: String
//    public let template: Template
//    public let filterRegexPattern: String
//    
//    public init(_ name: String, template: Template, filterRegexPattern: String) {
//        self.name = name
//        self.template = template
//        self.filterRegexPattern = filterRegexPattern
//    }
//    
//    public init(_ name: String, _ quantization: Quantization = .Q4_K_M, template: Template) {
//        self.name = name
//        self.template = template
//        self.filterRegexPattern = "(?i)\(quantization.rawValue)"
//    }
//    
//    func getDownloadURLStrings() async throws -> [String] {
//        let url = URL(string: "https://huggingface.co/\(name)/tree/main")!
//        let data = try await url.getData()
//        let content = String(data: data, encoding: .utf8)!
//        let downloadURLPattern = #"(?<=href=").*\.gguf\?download=true"#
//        let matches = try! downloadURLPattern.matches(in: content)
//        let root = "https://huggingface.co"
//        return matches.map { match in root + match }
//    }
//    
//    func getDownloadURL() async throws -> URL? {
//        let urlStrings = try await getDownloadURLStrings()
//        for urlString in urlStrings {
//            let found = try filterRegexPattern.hasMatch(in: urlString)
//            if found { return URL(string: urlString)! }
//        }
//        return nil
//    }
//    
//    public func download(to directory: URL = .documentsDirectory, as name: String? = nil, _ updateProgress: @escaping (Double) -> Void) async throws -> URL {
//        var destination: URL
//        if let name {
//            destination = directory.appending(path: name)
//            guard !destination.exists else { updateProgress(1); return destination }
//        }
//        guard let downloadURL = try await getDownloadURL() else { throw HuggingFaceError.noFilteredURL }
//        destination = directory.appending(path: downloadURL.lastPathComponent)
//        guard !destination.exists else { return destination }
//        try await downloadURL.downloadData(to: destination, updateProgress)
//        return destination
//    }
//    
//    public static func tinyLLaMA(_ quantization: Quantization = .Q4_K_M, _ systemPrompt: String) -> HuggingFaceModel {
//        HuggingFaceModel("TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF", quantization, template: .chatML(systemPrompt))
//    }
//}
//
//extension URL {
//    @backDeployed(before: iOS 16)
//    public func appending(path: String) -> URL {
//        appendingPathComponent(path)
//    }
//    @backDeployed(before: iOS 16)
//    public static var documentsDirectory: URL {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//    fileprivate var exists: Bool { FileManager.default.fileExists(atPath: path) }
//    fileprivate func getData() async throws -> Data {
//        let (data, response) = try await URLSession.shared.data(from: self)
//        let statusCode = (response as! HTTPURLResponse).statusCode
//        guard statusCode / 100 == 2 else { throw HuggingFaceError.network(statusCode: statusCode) }
//        return data
//    }
//    fileprivate func downloadData(to destination: URL, _ updateProgress: @escaping (Double) -> Void) async throws {
//        var observation: NSKeyValueObservation!
//        let url: URL = try await withCheckedThrowingContinuation { continuation in
//            let task = URLSession.shared.downloadTask(with: self) { url, response, error in
//                if let error { return continuation.resume(throwing: error) }
//                guard let url else { return continuation.resume(throwing: HuggingFaceError.urlIsNilForSomeReason) }
//                let statusCode = (response as! HTTPURLResponse).statusCode
//                guard statusCode / 100 == 2 else { return continuation.resume(throwing: HuggingFaceError.network(statusCode: statusCode)) }
//                continuation.resume(returning: url)
//            }
//            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
//                updateProgress(progress.fractionCompleted)
//            }
//            task.resume()
//        }
//        _ = observation
//        try FileManager.default.moveItem(at: url, to: destination)
//    }
//}
//
//extension String {
//    func matches(in content: String) throws -> [String] {
//        let pattern = try NSRegularExpression(pattern: self)
//        let range = NSRange(location: 0, length: content.utf16.count)
//        let matches = pattern.matches(in: content, range: range)
//        return matches.map { match in String(content[Range(match.range, in: content)!]) }
//    }
//    func hasMatch(in content: String) throws -> Bool {
//        let pattern = try NSRegularExpression(pattern: self)
//        let range = NSRange(location: 0, length: content.utf16.count)
//        return pattern.firstMatch(in: content, range: range) != nil
//    }
//    func firstMatch(in content: String) throws -> String? {
//        let pattern = try NSRegularExpression(pattern: self)
//        let range = NSRange(location: 0, length: content.utf16.count)
//        guard let match = pattern.firstMatch(in: content, range: range) else { return nil }
//        return String(content[Range(match.range, in: content)!])
//    }
//}
//
//
//// Define a Swift structure to hold performance data.
//public struct LlamaPerfContextData {
//    public let tStartMs: Double    // model start time in ms
//    public let tLoadMs: Double     // load time in ms
//    public let tPEvalMs: Double    // prompt evaluation time in ms
//    public let tEvalMs: Double     // generation (eval) time in ms
//    public let nPEval: Int         // number of tokens processed in prompt
//    public let nEval: Int          // number of tokens generated
//}
//
//extension LLM {
//    
//    /// Returns a string containing CPU/system capabilities as reported by llama.
//    public func systemInfo() -> String {
//        // llama_print_system_info returns a const char*; wrap it in a Swift String.
//        guard let cStr = llama_print_system_info() else { return "Performan information not available." }
//        return String(cString: cStr)
//    }
//    
//    /// Returns the performance metrics from the current llama context.
//    public func perfContextData() -> LlamaPerfContextData? {
//        // Make sure the context exists.
//        guard let ctx = self.context else { return nil }
//        
//        // Call the C function. (Assumes that `ctx.pointer` is of type `llama_context*`.)
//        let data = llama_perf_context(ctx.pointer)
//        
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
//    /// Prints performance context information to standard output using llama's internal logging.
//    public func printPerfContext() {
//        guard let ctx = self.context else { return }
//        llama_perf_context_print(ctx.pointer)
//    }
//    
//    /// Resets the performance metrics in the current llama context.
//    public func resetPerfContext() {
//        guard let ctx = self.context else { return }
//        llama_perf_context_reset(ctx.pointer)
//    }
//    
//    /// Dumps performance timing metrics in YAML format to the given FILE stream.
//    ///
//    /// - Parameter stream: A pointer to a FILE (for example, `stdout` or a file you opened).
//    public func dumpPerfYaml(to stream: UnsafeMutablePointer<FILE>) {
//        guard let ctx = self.context else { return }
//        llama_perf_dump_yaml(stream, ctx.pointer)
//    }
//}
