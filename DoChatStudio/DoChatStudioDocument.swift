//  DoChatStudioDocument.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var doChatStudio: UTType {
        UTType(importedAs: "net.example.doChatStudio.document")
    }
    static var GGMLUniversalFile: UTType {
        UTType(importedAs: "net.example.doChatStudio.gguf")
    }
}

class DoChatStudioDocument: FileDocument, Codable, ObservableObject/*, LLMOutputDelegate*/ {
    //    @Published var rawOutputString: String = ""
    
    
    @Published var url: URL? = nil  {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var urlExists: Bool = false
    var urlLoadError: Bool = false
    
    @Published var systemPrompt: String
    
    @Published var llm: LLM? = nil {
        willSet {
            objectWillChange.send()
        }
    }
    
    @Published var history: [Chat] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    
    var isLoaded: Bool = false
    var isLoadedingModel: Bool = false
    
    var id: UUID
    
    enum CodingKeys: String, CodingKey {
        case url
        case systemPrompt
        case id
        case history
    }
    
    init(text: String) {
        self.systemPrompt = text
        id = UUID()
        
        print("url0:\(url)")
        
        DispatchQueue.global(qos: .default).async {
            self.initLLM()
        }
        
    }
    
    static var readableContentTypes: [UTType] { [.doChatStudio] }
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decodedDocument = try JSONDecoder().decode(DoChatStudioDocument.self, from: data)
        self.url = decodedDocument.url
        self.systemPrompt = decodedDocument.systemPrompt
        self.id = UUID()
        self.history = decodedDocument.history
        
        print("doc1:\(decodedDocument)")
        print("url1:\(url)")
        
        DispatchQueue.global(qos: .default).async {
            self.initLLM()
        }
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        self.systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        self.id = UUID()
        self.history = try container.decode([Chat].self, forKey: .history)
        
        print("doc2:\(container)")
        print("url2:\(self.url)")
                
        DispatchQueue.global(qos: .default).async {
            self.initLLM()
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(id, forKey: .id)
        try container.encode(history, forKey: .history)
    }
    
    func decode(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        id = try container.decode(UUID.self, forKey: .id)
        history = try container.decode([Chat].self, forKey: .history)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }
    
    func initLLM(path: URL? = nil) {
        //        objectWillChange.send()
        if isLoadedingModel {return}
        print("isLoaded: \(isLoaded)")
        print("URL: \(url)")
        print("path: \(path)")
        if isLoaded { return }
        
        llm = nil
        
        if path != nil {
            url = path
        }
        
        if url == nil {
            urlExists = false
            self.isLoaded = false
            print("Load Exit")
            return
        }
        print(".......................................................................................")
        print("DoChat LLLM Init Start \nURL:\(url?.path() ?? "Path N/A")")
        print(".......................................................................................")
        
        if isLoadedingModel {return}

        if ((url?.startAccessingSecurityScopedResource()) != nil) {
            
            do {
                let result = try Data(contentsOf: url!)
                print("URL Load Results:\(result)")
                
                urlExists = true
            } catch {
                print("URL Load Error:\(error)")
                urlExists = false
                if !urlLoadError {
                    urlLoadError = true
                    initLLM(path: nil)

                    print("initllm16")
                }
            }
            
            if !urlExists {
                print("URL does not exist")
                self.isLoaded = false
                self.llm = nil
                url?.stopAccessingSecurityScopedResource()
                self.isLoadedingModel = false
                return
            }
            print("..........................................3............................................")
            
            
            DispatchQueue.main.async {
                if self.isLoadedingModel {return}
                self.isLoadedingModel = true
                if let llm = LLM.init(from: self.url!, template: .customJinja(self.systemPrompt)) {
                    self.urlExists = true
                    llm.history.append(contentsOf: self.history)
                    
                    llm.modelName = llm.model.name ?? ""
                    llm.modelArchitecture = llm.model.architecture ?? ""
                    llm.modelAuthor = llm.model.author ?? ""
                    llm.modelQuantizationType = llm.model.quantizationType ?? ""
                    
                    print("Model \(llm.modelName)")
                    print("Info: \(llm.systemInfo())")
                    print("DoChat initialized successfully: @ \n URL:\(self.url!.absoluteString) \n Author:\(llm.modelAuthor) \r Architecture:\(llm.modelArchitecture) \t Quantization Type:\(llm.modelQuantizationType)")
                    
                    self.objectWillChange.send()
                    self.llm = llm
                    self.isLoaded = true
                    
                    self.url?.stopAccessingSecurityScopedResource()
                    self.isLoadedingModel = false

                    return
                }
                
                if self.llm == nil {
                    print("Model Not Loaded")
                    self.isLoaded = false
                    self.isLoadedingModel = false
                }
                
                
                
            }
            url?.stopAccessingSecurityScopedResource()
            self.isLoadedingModel = false

        }
    }
    
    func respond(input: String) -> Void {
        // Ensure we have a valid model instance.
        //        guard let llm = llm else { return }
        
        if !(llm?.isThinking ?? false) {
            // Model is not running: start generation.
            llm?.isThinking = true
            llm?.shouldPausePredicting = false
            
            // Append the user's chat to history on the main queue.
            DispatchQueue.main.async { [weak self] in
                self?.history.append(Chat(role: .user, content: input))
            }
            
            // Start the async generation task.
            Task {
                await llm?.respond(to: input)
                DispatchQueue.main.async { [weak self] in
                    // After generation completes, append the bot's response.
                    if let self = self {
                        let chat = Chat(role: .bot, content: llm?.output ?? "")
                        self.history.append(chat)
                        llm?.isThinking = false
                    }
                }
            }
        } else {
            // Model is already generating; toggle pause/resume.
            llm?.shouldPausePredicting.toggle()
        }
    }
    
    func stop() {
        llm?.stop()
    }
    
}
