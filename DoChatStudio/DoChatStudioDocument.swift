//  DoChatStudioDocument.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.

import SwiftUI
import UniformTypeIdentifiers
import LLM

class DoChatStudioDocument: FileDocument, ObservableObject {
    // MARK: - Published Properties
    @Published var url: URL? = nil {
        willSet { objectWillChange.send() }
    }
    @Published var urlExists: Bool = false
    var urlLoadError: Bool = false
    @Published var systemPrompt: String
    @Published var llm: StatefulLLM? = nil {
        willSet { objectWillChange.send() }
    }
    @Published var history: [Chat] = [] {
        willSet { objectWillChange.send() }
        didSet {
            var chats: [Message] = []
            
            for chat in self.history {
                chats.append(Message(chat: chat))
            }
            
            messageHistory = chats
        }
    }
    @Published var messageHistory: [Message] = [] {
        willSet { objectWillChange.send() }
    }
    
    @Published var locked: Bool = false
    @Published var password: Bool = false
    
    @Published var resetSeedAfterResponse: Bool = false
    
    // MARK: - Other Properties
    var isLoaded: Bool = false
    var id: UUID
    
    // Specify the document type.
    static var readableContentTypes: [UTType] { [.doChatStudio] }
    
    // MARK: - Helper Struct for JSON Coding

    private struct DocumentData: Codable {
        var url: URL?
        var systemPrompt: String
        var history: [Chat]
        
        var locked: Bool
        var password: Bool
        
        var resetSeedAfterResponse: Bool
        
        var id: UUID

        private enum CodingKeys: String, CodingKey {
            case url, systemPrompt, history
            case locked, password, resetSeedAfterResponse, id
        }
        private enum ChatKeys: String, CodingKey {
            case role, content
        }

        init(
              url: URL?,
              systemPrompt: String,
              history: [Chat],
              locked: Bool,
              password: Bool,
              resetSeedAfterResponse: Bool,
              id: UUID
            ) {
              self.url = url
              self.systemPrompt = systemPrompt
              self.history = history
              self.locked = locked
              self.password = password
              self.resetSeedAfterResponse = resetSeedAfterResponse
              self.id = id
            }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            url = try c.decodeIfPresent(URL.self, forKey: .url)
            systemPrompt = try c.decode(String.self, forKey: .systemPrompt)
            locked = try c.decode(Bool.self, forKey: .locked)
            password = try c.decode(Bool.self, forKey: .password)
            resetSeedAfterResponse = try c.decode(Bool.self, forKey: .resetSeedAfterResponse)
            id = try c.decode(UUID.self, forKey: .id)

            var historyArray = try c.nestedUnkeyedContainer(forKey: .history)
            var chats: [Chat] = []
            while !historyArray.isAtEnd {
                let chatContainer = try historyArray.nestedContainer(keyedBy: ChatKeys.self)
                let roleString = try chatContainer.decode(String.self, forKey: .role)
                let role: Role = {
                    switch roleString {
                    case "user": return .user
                    case "bot":  return .bot
                    default:
                        // fallback or throw
                        return .user
                    }
                }()
                let content = try chatContainer.decode(String.self, forKey: .content)
                chats.append((role: role, content: content))
            }
            history = chats
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encodeIfPresent(url, forKey: .url)
            try c.encode(systemPrompt, forKey: .systemPrompt)
            try c.encode(locked, forKey: .locked)
            try c.encode(password, forKey: .password)
            try c.encode(resetSeedAfterResponse, forKey: .resetSeedAfterResponse)
            try c.encode(id, forKey: .id)

            var historyArray = c.nestedUnkeyedContainer(forKey: .history)
            for chat in history {
                var chatContainer = historyArray.nestedContainer(keyedBy: ChatKeys.self)
                let roleString: String = {
                    switch chat.role {
                    case .user: return "user"
                    case .bot:  return "bot"
                    }
                }()
                try chatContainer.encode(roleString, forKey: .role)
                try chatContainer.encode(chat.content, forKey: .content)
            }
        }
    }
    // MARK: - Initializers
    
    /// Creates a new document with the given system prompt.
    init(text: String) {
        self.systemPrompt = text
        self.id = UUID()
        
        // For new documents you may want to set url later.
        DispatchQueue.global(qos: .default).async {
            //            self.initLLM()
        }
    }
    
    /// Initializes the document from the file’s JSON data.
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Decode the JSON into our helper struct.
        let decoded = try JSONDecoder().decode(DocumentData.self, from: data)
        self.url = decoded.url
        self.systemPrompt = decoded.systemPrompt
        self.history = decoded.history
        
        self.locked = decoded.locked
        self.password = decoded.password
        
        self.resetSeedAfterResponse = decoded.resetSeedAfterResponse
        
        self.id = UUID()  // Create a new UUID or decode one if needed.
        if self.url == nil {return}
        
        
        print("Document URL updated to sandbox copy: \(self.url!)")
        
        
        // Now initialize the LLM asynchronously.
        if let theURL = self.url {
            if FileManager.default.fileExists(atPath: theURL.path) {
                DispatchQueue.global(qos: .default).async {
                    print("theUrl: \(theURL.absoluteString)")
                    self.initLLM(path: theURL)
                }
                
                print("Initialized document with URL: \(theURL.absoluteString)")
            }
        }
        
    }
    
    /// Writes the document’s data as JSON.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Create an instance of the helper struct.
        let documentData = DocumentData(url: self.url,
                                        systemPrompt: self.systemPrompt,
                                        history: self.history, locked: self.locked, password: self.password, resetSeedAfterResponse: self.resetSeedAfterResponse, id: self.id)
        let data = try JSONEncoder().encode(documentData)
        return FileWrapper(regularFileWithContents: data)
    }
    
    // MARK: - Main LLM Initialization
    
    func initLLM(path: URL) {
        url = path
        
        llm = nil
        
        if url == nil {return}
        
        // Load the LLM from the local copy on the main thread.
        Task { @MainActor in
            if let llmInstance = StatefulLLM.init(from: self.url!,
                                                  template: .llama()){
                self.urlExists = true
                llmInstance.history.append(contentsOf: self.history)
                //append(contentsOf: self.history)
                
//                llmInstance.modelName = llmInstance.model.name ?? ""
//                llmInstance.modelArchitecture = llmInstance.model.architecture ?? ""
//                llmInstance.modelAuthor = llmInstance.model.author ?? ""
//                llmInstance.modelQuantizationType = llmInstance.model.quantizationType ?? ""
                
//                print("Model \(llmInstance.modelName) initialized successfully from \(self.url!)")
                self.llm = llmInstance
                self.isLoaded = true
            } else {
                print("Model Not Loaded from \(self.url!)")
                self.isLoaded = false
            }
        }
    }
    
    // MARK: - Respond / Chat Logic
    func respond(input: String) {
        guard let llm = llm else { return }
        if !llm.isThinking {
            llm.isThinking = true
            llm.shouldPausePredicting = false
            
            // Add the user's message to the history
            DispatchQueue.main.async {
                self.history.append(Chat(role: .user, content: input))
            }
            
            // Run the actual LLM inference
            Task {
                await llm.respond(to: input)
                DispatchQueue.main.async {
                    let botMessage = Chat(role: .bot, content: self.llm?.output ?? "")
                    self.history.append(botMessage)
                    self.llm?.isThinking = false
                }
            }
        } else {
            llm.shouldPausePredicting.toggle()
        }
    }
    
    func stop() {
        llm?.stop()
    }
}
