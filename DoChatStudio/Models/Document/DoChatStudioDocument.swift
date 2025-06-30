// DoChatStudioDocument.swift (Updated for SwiftLLM B)

import SwiftUI
import UniformTypeIdentifiers
//import LLM

class DoChatStudioDocument: FileDocument, ObservableObject {
    
    // MARK: - Published Properties
    @Published var url: URL? = nil {
        didSet {
            DispatchQueue.main.async { [self] in
                urlExists = url != nil
                objectWillChange.send()
            }
        }
    }
    @Published var urlExists: Bool = false
    var urlLoadError: Bool = false
    
    @Published var chatModel: ChatViewModel? = nil /*{
                                                    willSet { objectWillChange.send() }
                                                    }*/
    
    @Published var locked: Bool = false
    @Published var password: Bool = false
    
    // MARK: - Other Properties
    var isLoaded: Bool = false
    var id: UUID
    
    static var readableContentTypes: [UTType] { [.doChatStudio] }
    
    
    init(text: String) {
        self.id = UUID()
        Task {
            let model = ChatViewModel(mlxService: MLXService())
            await MainActor.run {
                self.chatModel = model
            }
        }
    }
    
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoded = try JSONDecoder().decode(DocumentData.self, from: data)
        self.id = UUID()
        
        DispatchQueue.main.async {
            self.locked = decoded.locked
            self.password = decoded.password
            self.id = decoded.id
            
            if self.url == nil {
                self.url = decoded.url
            }
            self.chatModel = decoded.chatModel
        }
    }
    
    func setFileURL(url:URL) {
        DispatchQueue.main.async {
            self.url = url
        }
    }
    
    @MainActor
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data:Data
        
        var documentData: DocumentData? = nil
        
        if self.chatModel == nil {
                self.chatModel = ChatViewModel(mlxService: MLXService())
        }
        
        if self.chatModel == nil {
            throw DocumentError.noData("chatModel == nil")
        }
        
        documentData = DocumentData(url: self.url, chatModel: self.chatModel!, locked: self.locked, password: self.password, id: self.id)
        
        if documentData == nil {
            throw DocumentError.noData("documentData == nil")
        }
        
        data = try JSONEncoder().encode(documentData)
        
        return FileWrapper(regularFileWithContents: data)
        
    }
    
    func save(saveDestination: URL? = nil) {
        do {
            
            // 1️⃣ Figure out the URL
            if let dest = saveDestination, dest != url {
                url = dest
            }
            
            // 2️⃣ If we still don’t have a URL, bail out
            guard url != nil else { return }
            
            //                 2️⃣ Manually encode your DocumentData
            let documentData = DocumentData(
                url: self.url,
                chatModel: self.chatModel ?? ChatViewModel(mlxService: MLXService()),
                locked: self.locked,
                password: self.password,
                id: self.id
            )
            let data = try JSONEncoder().encode(documentData)
            
            try data.write(to: url!, options: .atomic)
            
            self.urlExists = true
            self.urlLoadError = false
        } catch {
            self.urlLoadError = true
        }
        
    }
    
    
}

@Observable
@preconcurrency
private class DocumentData: Codable {
    var url: URL?
    
    var chatModel: ChatViewModel
    var locked: Bool
    var password: Bool
    var id: UUID
    
    private enum CodingKeys: String, CodingKey {
        case url, chatModel, locked, password, id
    }
    private enum ChatKeys: String, CodingKey {
        case role, content
    }
    
    init(url: URL?, chatModel:ChatViewModel, locked: Bool, password: Bool, id: UUID) {
        self.url = url
        self.chatModel = chatModel
        self.locked = locked
        self.password = password
        self.id = id
    }
    
    required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        
        url = try c.decodeIfPresent(URL.self, forKey: .url)
        
        locked = try c.decode(Bool.self, forKey: .locked)
        password = try c.decode(Bool.self, forKey: .password)
        
        
        
        self.chatModel = try c.decodeIfPresent(ChatViewModel.self, forKey: .chatModel) ?? ChatViewModel(mlxService: MLXService())
        
        
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(url, forKey: .url)
        try c.encodeIfPresent(chatModel, forKey: .chatModel)
        try c.encode(locked, forKey: .locked)
        try c.encode(password, forKey: .password)
        try c.encode(id, forKey: .id)
    }
}

enum DocumentError: Error {
    case noData(String)
}
