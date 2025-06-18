// DoChatStudioDocument.swift (Updated for SwiftLLM B)

import SwiftUI
import UniformTypeIdentifiers
//import LLM

class DoChatStudioDocument: FileDocument, ObservableObject {
    // MARK: - Published Properties
    @Published var url: URL? = nil {
        willSet { objectWillChange.send() }
    }
    @Published var urlExists: Bool = false
    var urlLoadError: Bool = false
    @Published var systemPrompt: String
    @Published var llm: LLMRunner? = nil {
        willSet { objectWillChange.send() }
    }
    @Published var history: [Chat] = [] {
        willSet { objectWillChange.send() }
        didSet {
            messageHistory = history.map { Message(chat: $0) }
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
    
    static var readableContentTypes: [UTType] { [.doChatStudio] }
    
    private struct DocumentData: Codable {
        var url: URL?
        var systemPrompt: String
        var history: [Chat]
        var locked: Bool
        var password: Bool
        var resetSeedAfterResponse: Bool
        var id: UUID
        
        private enum CodingKeys: String, CodingKey {
            case url, systemPrompt, history, locked, password, resetSeedAfterResponse, id
        }
        private enum ChatKeys: String, CodingKey {
            case role, content
        }
        
        init(url: URL?, systemPrompt: String, history: [Chat], locked: Bool, password: Bool, resetSeedAfterResponse: Bool, id: UUID) {
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
                let role: Role = roleString == "bot" ? .bot : .user
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
                let roleString = chat.role == .bot ? "bot" : "user"
                try chatContainer.encode(roleString, forKey: .role)
                try chatContainer.encode(chat.content, forKey: .content)
            }
        }
    }
    
    init(text: String) {
        self.systemPrompt = text
        self.id = UUID()
    }
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoded = try JSONDecoder().decode(DocumentData.self, from: data)
        self.url = decoded.url
        self.systemPrompt = decoded.systemPrompt
        self.history = decoded.history
        self.locked = decoded.locked
        self.password = decoded.password
        self.resetSeedAfterResponse = decoded.resetSeedAfterResponse
        self.id = decoded.id
        
        if let theURL = self.url, FileManager.default.fileExists(atPath: theURL.path) {
            DispatchQueue.global(qos: .default).async {
                self.initLLM(path: theURL)
            }
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let documentData = DocumentData(url: self.url, systemPrompt: self.systemPrompt, history: self.history, locked: self.locked, password: self.password, resetSeedAfterResponse: self.resetSeedAfterResponse, id: self.id)
        let data = try JSONEncoder().encode(documentData)
        return FileWrapper(regularFileWithContents: data)
    }
    
    func initLLM(path: URL) {
        url = path
        llm = nil
        guard let url = self.url else { return }
        
        Task { @MainActor in
            //            if let llmInstance = StatefulLLM(from: url, template: .llama(""), history: self.history, maxTokenCount: 8192) {
            self.urlExists = true
            self.llm = LLMRunner()
            self.isLoaded = true
            //            } else {
            //                print("Model Not Loaded from \(url)")
            //                self.isLoaded = false
            //            }
        }
    }
    
    func respond(input: String) {
        Task {
            guard let llm else { return }
            
            try await llm.respond(to: input)
            
            
            await MainActor.run {
                let output = llm.output
                
                self.history.append(Chat(role: .user, content: input))
                self.history.append(Chat(role: .bot, content: output))
                
            }
        }
    }
    
    func stop() {
//        llm?.stop()
        
    }
}
