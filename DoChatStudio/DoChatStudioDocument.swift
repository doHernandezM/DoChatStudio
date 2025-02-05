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
    
    var id: UUID
    
    enum CodingKeys: String, CodingKey {
        case url
        case systemPrompt
        case id
        case history
    }
    
    init(text: String = "I'm a helpful chatbot with a personality like a computer from a tv scifi show, efficient and curt, but not rude.") {
        self.systemPrompt = text
        id = UUID()
        
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
        
        self.initLLM(path: self.url)
        print("initllm14")
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(URL.self, forKey: .url)
        self.systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        self.id = UUID()
        self.history = try container.decode([Chat].self, forKey: .history)
        
        self.initLLM(path: self.url)
        print("initllm15")
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
        llm = nil
        
        
        url = path
        
        if url == nil {
            urlExists = false
            return
        }
        print(".......................................................................................")
        print("DoChat LLLM Init Start \nURL:\(url?.path() ?? "Path N/A")")
        print(".......................................................................................")
        
//        if ((url?.startAccessingSecurityScopedResource()) != nil) {
            
            do {
                let result = try Data(contentsOf: url!)
                print("URL Load Results:\(result)")
                urlExists = true
//                objectWillChange.send()
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
                
                self.llm = nil
                
//                url?.stopAccessingSecurityScopedResource()
                
                return
            }
            print(".......................................................................................")
            
            
        DispatchQueue.main.async {
            if let llm = LLM.init(from: self.url!, template: .customJinja(self.systemPrompt)) {
                self.urlExists = true
                llm.history.append(contentsOf: self.history)
                
                //                self.llm?.delegate = self
                llm.modelName = llm.model.name ?? ""
                llm.modelArchitecture = llm.model.architecture ?? ""
                llm.modelAuthor = llm.model.author ?? ""
                llm.modelQuantizationType = llm.model.quantizationType ?? ""
                
                print("Model \(llm.modelName)")
                print("Info: \(llm.systemInfo())")
                print("DoChat initialized successfully: @ \n URL:\(self.url!.absoluteString) \n Author:\(llm.modelAuthor) \r Architecture:\(llm.modelArchitecture) \t Quantization Type:\(llm.modelQuantizationType)")
                
//                url?.stopAccessingSecurityScopedResource()
                
                self.objectWillChange.send()
                self.llm = llm
                
                
                
                return
            }
            
            if self.llm == nil {print("Model Not Loaded")}
            
//            url?.stopAccessingSecurityScopedResource()
        }
        
    }
    
    
    func respond(input: String) -> Void {
//        Task {
            DispatchQueue.main.async { [self] in
                history.append(Chat(role: .user, content: input))
                llm?.isThinking = true
            }
            //            let file = UnsafeMutablePointer<FILE>.allocate(capacity: 1)
            
            //            print("LLM Perf:\(llm?.dumpPerfYaml(to: file))")
            //            print("LLM Perf:\(file.pointee)")
            //
        Task  { 
                await llm?.respond(to: input)
                
                //            print("LLM Perf:\(llm?.dumpPerfYaml(to: file))")
                //            print("LLM Perf:\(file.pointee)")
                //
                DispatchQueue.main.async { [self] in
                    let chat = Chat(role: .bot, content: llm?.output ?? "")
                    
                    history.append(chat)
                    llm?.isThinking = false
                }
//            }
        }
    }
    
    func stop() {
        llm?.stop()
        DispatchQueue.main.async { [self] in
            llm?.isThinking = false
        }
    }
    
}

//func stringFromFILE(filePtr: UnsafeMutablePointer<FILE>) -> String {
//    guard filePtr != nil else {
//      return ""
//    }
//    // change the buffer size at your needs
//    let buffer = [CChar](repeating: 0, count: 1024)
//    var string = String()
//    while fgets(UnsafeMutablePointer(mutating: buffer), Int32(buffer.count), filePtr) != nil {
//      if let read = String.fromCString(buffer) {
//        string += read
//      }
//    }
//    return string
//  }
