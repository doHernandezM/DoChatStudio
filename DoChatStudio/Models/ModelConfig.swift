//ModelConfig.swift

import Foundation

// MARK: - ModelConfig

/// A model configuration that can save and load itself from disk.
class ModelConfig: Codable, Identifiable, ObservableObject {
    let id: UUID
    @Published public var name: String

    @Published var url: URL
    var urlExists: Bool { FileManager.default.fileExists(atPath: url.path) }
    
    @Published public var seed: UInt32
    @Published public var topK: Int32
    @Published public var topP: Float
    @Published public var temp: Float
    
    @Published public var historyLimit: Int32
    
    init(name: String, url: URL, seed: UInt32, topK: Int32, topP: Float, temp: Float, historyLimit: Int32) {
        self.id = UUID()
        self.name = name
        
        self.url = url
        self.seed = seed
        self.topK = topK
        self.topP = topP
        self.temp = temp
        
        self.historyLimit = historyLimit
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        
        case url
        case seed
        case topK
        case topP
        case temp
        
        case historyLimit
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(URL.self, forKey: .url)
        
        self.seed = try container.decode(UInt32.self, forKey: .seed)
        self.topK = try container.decode(Int32.self, forKey: .topK)
        self.topP = try container.decode(Float.self, forKey: .topP)
        self.temp = try container.decode(Float.self, forKey: .temp)
        
        self.historyLimit = try container.decode(Int32.self, forKey: .historyLimit)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        
        try container.encode(seed, forKey: .seed)
        try container.encode(topK, forKey: .topK)
        try container.encode(topP, forKey: .topP)
        try container.encode(temp, forKey: .temp)
        
        try container.encode(historyLimit, forKey: .historyLimit)
    }
}

// MARK: - ModelConfig Convenience Methods for Saving/Loading

extension ModelConfig {
    
    /// The folder name where model configurations are saved.
    private static let modelsFolderName = "models"
    
    /// Returns the URL for the "models" folder inside the sandboxed Documents directory.
    /// The folder is created if it does not exist.
    private static func modelsFolderURL() -> URL? {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
            let folderURL = documentsURL.appendingPathComponent(modelsFolderName, isDirectory: true)
            if !fileManager.fileExists(atPath: folderURL.path) {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            }
            return folderURL
        } catch {
            print("Error accessing or creating models folder: \(error)")
            return nil
        }
    }
    
    /// Returns the file URL (inside the models folder) for this configuration.
    /// In this example, the file name is based on the model's name.
    private func fileURL() -> URL? {
        guard let folderURL = Self.modelsFolderURL() else { return nil }
        // You can choose any naming convention here. For example, using the model name with a ".json" extension.
        return folderURL.appendingPathComponent("\(name).json")
    }
    
    /// Saves the model configuration to disk as JSON.
    /// - Returns: `true` if the save was successful; otherwise, `false`.
    @discardableResult
    func save() -> Bool {
        guard let fileURL = fileURL() else {
            print("Unable to get file URL for saving.")
            return false
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            try data.write(to: fileURL, options: [.atomic])
            print("Model configuration saved to \(fileURL.path)")
            return true
        } catch {
            print("Error saving model configuration: \(error)")
            return false
        }
    }
    
    /// Loads a model configuration from disk.
    /// - Parameter fileName: The name of the file (with extension) to load (for example, "MyModel.json").
    /// - Returns: A `ModelConfig` instance if loading and decoding succeeds; otherwise, `nil`.
    static func load(from fileName: String) -> ModelConfig? {
        guard let folderURL = modelsFolderURL() else {
            print("Unable to get models folder URL for loading.")
            return nil
        }
        let fileURL = folderURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File does not exist at \(fileURL.path)")
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let config = try decoder.decode(ModelConfig.self, from: data)
            print("Model configuration loaded from \(fileURL.path)")
            return config
        } catch {
            print("Error loading model configuration: \(error)")
            return nil
        }
    }
}
