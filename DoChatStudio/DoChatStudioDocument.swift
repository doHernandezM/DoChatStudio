//  DoChatStudioDocument.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var doChatStudio: UTType {
        UTType(importedAs: "net.example.dochatstudio.document")
    }
    static var GGMLUniversalFile: UTType {
        UTType(importedAs: "net.example.dochatstudio.gguf")
    }
}

class DoChatStudioDocument: FileDocument, ObservableObject {
    // MARK: - Published Properties
    @Published var url: URL? = nil {
        willSet { objectWillChange.send() }
    }
    @Published var urlExists: Bool = false
    var urlLoadError: Bool = false
    @Published var systemPrompt: String
    @Published var llm: LLM? = nil {
        willSet { objectWillChange.send() }
    }
    @Published var history: [Chat] = [] {
        willSet { objectWillChange.send() }
    }
    
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
    }
    
    // MARK: - Initializers
    
    /// Creates a new document with the given system prompt.
    init(text: String) {
        self.systemPrompt = text
        self.id = UUID()
        
        // For new documents you may want to set url later.
        DispatchQueue.global(qos: .default).async {
            self.initLLM()
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
        self.id = UUID()  // Create a new UUID or decode one if needed.
        
        // **** Synchronously update self.url if it’s external ****
        // This ensures that the file URL stored in the document is a sandboxed copy.
        if let originalURL = self.url {
            let fileManager = FileManager.default
            guard let documentsURL = try? fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ) else {
                print("Could not find Documents directory.")
                return
            }
            let filePath = originalURL.path
            let docsPath = documentsURL.path
            let isInsideAppSandbox = filePath.hasPrefix(docsPath)
            
            // Create a "Models" subfolder in the Documents directory.
            let localDirectory = documentsURL.appendingPathComponent("Models")
            do {
                try fileManager.createDirectory(at: localDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating local Models directory: \(error)")
            }
            
            // Destination URL is the local copy.
            let destinationURL = localDirectory.appendingPathComponent(originalURL.lastPathComponent)
            
            // If the local copy does not already exist, copy the file.
            if !fileManager.fileExists(atPath: destinationURL.path) {
                if !isInsideAppSandbox {
                    #if os(iOS)
                    if originalURL.startAccessingSecurityScopedResource() {
                        defer { originalURL.stopAccessingSecurityScopedResource() }
                        do {
                            try fileManager.copyItem(at: originalURL, to: destinationURL)
                        } catch {
                            print("Error copying file to local Models directory: \(error)")
                        }
                    } else {
                        print("Unable to start accessing security scoped resource at \(originalURL)")
                    }
                    #else
                    do {
                        try fileManager.copyItem(at: originalURL, to: destinationURL)
                    } catch {
                        print("Error copying file to local Models directory: \(error)")
                    }
                    #endif
                } else {
                    do {
                        try fileManager.copyItem(at: originalURL, to: destinationURL)
                    } catch {
                        print("Error copying file to local Models directory: \(error)")
                    }
                }
            }
            // Update self.url to point to the local copy.
            self.url = destinationURL
            print("Document URL updated to sandbox copy: \(self.url!)")
        }
        
        // Now initialize the LLM asynchronously.
        DispatchQueue.global(qos: .default).async {
            self.initLLM()
        }
        
        print("Initialized document with URL: \(self.url?.absoluteString ?? "nil")")
    }
    
    /// Writes the document’s data as JSON.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Create an instance of the helper struct.
        let documentData = DocumentData(url: self.url,
                                        systemPrompt: self.systemPrompt,
                                        history: self.history)
        let data = try JSONEncoder().encode(documentData)
        return FileWrapper(regularFileWithContents: data)
    }
    
    // MARK: - Main LLM Initialization
    func initLLM(path: URL? = nil) {
        // If we've already loaded a model, no need to repeat.
        if isLoaded { return }
        print("Init")
        // Reset any previously loaded LLM.
        llm = nil

        // Update `url` if a new path is provided.
        if let path = path {
            url = path
        }
        
        guard let fileURL = url else {
            urlExists = false
            isLoaded = false
            print("Load Exit: URL is nil")
            return
        }
        
        let fileManager = FileManager.default
        // Get the app’s Documents directory for sandboxed file storage.
        guard let documentsURL = try? fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else {
            print("Could not find Documents directory.")
            return
        }
        
        // Check if the file is already inside the app’s sandbox.
        let filePath = fileURL.path
        let docsPath = documentsURL.path
        let isInsideAppSandbox = filePath.hasPrefix(docsPath)
        
        // Create a "Models" subfolder in the Documents directory.
        let localDirectory = documentsURL.appendingPathComponent("Models")
        do {
            try fileManager.createDirectory(at: localDirectory,
                                            withIntermediateDirectories: true)
        } catch {
            print("Error creating local Models directory: \(error)")
            return
        }
        
        // Destination URL is the local copy.
        let destinationURL = localDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        // If the local copy does not already exist, copy the file.
        if !fileManager.fileExists(atPath: destinationURL.path) {
            if !isInsideAppSandbox {
                #if os(iOS)
                guard fileURL.startAccessingSecurityScopedResource() else {
                    print("Unable to start accessing security-scoped resource at \(fileURL)")
                    return
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }
                #endif
                do {
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                } catch {
                    print("Error copying file to Documents/Models: \(error)")
                    return
                }
            } else {
                do {
                    try fileManager.copyItem(at: fileURL, to: destinationURL)
                } catch {
                    print("Error copying file to Documents/Models: \(error)")
                    return
                }
            }
        }
        
        // Update the document’s URL to point to the local copy.
        self.url = destinationURL
        
        // Load the LLM from the local copy on the main thread.
        DispatchQueue.main.async {
            if let llmInstance = LLM.init(from: self.url!,
                                          template: .customJinja(self.systemPrompt)) {
                self.urlExists = true
                llmInstance.history.append(contentsOf: self.history)
                
                llmInstance.modelName = llmInstance.model.name ?? ""
                llmInstance.modelArchitecture = llmInstance.model.architecture ?? ""
                llmInstance.modelAuthor = llmInstance.model.author ?? ""
                llmInstance.modelQuantizationType = llmInstance.model.quantizationType ?? ""
                
                print("Model \(llmInstance.modelName) initialized successfully from \(self.url!)")
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
