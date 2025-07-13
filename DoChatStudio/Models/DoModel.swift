//
//  LMModel.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import Foundation
import Hub
import MLX
import MLXLLM
import MLXLMCommon
import MLXVLM

import SwiftUI

/// Represents a language model configuration with its associated properties and type.
/// Can represent either a large language model (LLM) or a vision-language model (VLM).

@Observable
class DoModel {
    /// Name of the model
    static let fileManager = FileManager.default
    static let DoChatDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "doChat")
    static let modelDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "doChat").appending(path: "models")
    static let mlxCommunityDirectory = modelDirectory.appending(path: "mlx-community")
    
    var name: String
    
    ///Current model of the state
    var state: ModelState? = nil
    
    var size: Int64 = 0
    /// Total model directory size
    var finishedSize: Int64 = 0
    
    var calculateSize: Int64 {
        get {
            if finishedSize != 0 {return finishedSize}
            
            var modelBytes:Int64 = 0
            do {
                modelBytes = Int64(try self.folderURL.directoryTotalAllocatedSize(includingSubfolders: true) ?? 0)
                
                return modelBytes
                
            } catch {
                print("Error:\(self.displayName) not available")
            }
            
            return modelBytes
        }
        
    }
    
    var sizeString: String {
        get {
            return ByteCountFormatter.string(fromByteCount: calculateSize, countStyle: .file)
        }
    }
    /// Local URL
    var localURL: URL?
    
    /// Configuration settings for model initialization
    let configuration: ModelConfiguration
    
    /// Type of the model (language or vision-language)
    let type: ModelType
    
    /// Defines the type of language model
    enum ModelType {
        /// Large language model (text-only)
        case llm
        /// Vision-language model (supports images and text)
        case vlm
    }
    
    init(name: String, configuration: ModelConfiguration, type: ModelType) {
        self.name = name
        self.configuration = configuration
        self.type = type
        
        self.localURL = self.folderURL
        
        self.size = self.calculateSize
        
        
    }
    
    static func modelFolders() -> [URL] {
        var modelFolders: [URL] = []
        
        do {
            modelFolders = try fileManager.contentsOfDirectory(at:mlxCommunityDirectory, includingPropertiesForKeys: [.fileSizeKey,.fileAllocatedSizeKey])
        } catch ModelLoadError.mlxcommunity {
            print("Error: Contents mlx-community not loaded")
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        return modelFolders
    }
    
    var folderURL:URL {
        get {
            let modelFolder = DoModel.mlxCommunityDirectory.appendingPathComponent(self.displayName)
            return modelFolder
        }
    }
    
    @MainActor @discardableResult
    func deleteModel() -> Bool {
        if self.downloadTask != nil{
            self.cancelDownload()
        }
        
        if self.localURL == nil {return false}
        do {
            try DoModel.fileManager.removeItem(at: self.localURL!)
            
            self.size = self.calculateSize
            self.finishedSize = 0
            return true
        } catch {
            return false
        }
    }
    
    /// Cache to store loaded model containers to avoid reloading.
    private let modelCache = NSCache<NSString, ModelContainer>()
    
    /// Tracks the current model download progress.
    /// Access this property to monitor model download status.
    @MainActor
    private(set) var modelDownloadProgress: Progress?
    
    //    @MainActor
    //    private(set) var modelFraction: Double?
    
    /// Loads a model from the hub or retrieves it from cache.
    /// - Parameter model: The model configuration to load
    /// - Returns: A ModelContainer instance containing the loaded model
    /// - Throws: Errors that might occur during model loading
    func load(model: DoModel, cacheLimit: Int = 2048 * 1024 * 1024) async throws -> ModelContainer {
        state = .initializing
        // Set GPU memory limit to prevent out of memory issues
        MLX.GPU.set(cacheLimit: cacheLimit)
        //        MLX.GPU.set(memoryLimit: 2048 * 1024 * 1024, relaxed: true)
        
        // Return cached model if available to avoid reloading
        if let container = modelCache.object(forKey: model.name as NSString) {
            state = .idle
            return container
        }
        
        let factory: ModelFactory =
        switch model.type {
        case .llm:
            LLMModelFactory.shared
        case .vlm:
            VLMModelFactory.shared
        }
        do {
            return try await factory.loadContainer(hub: HubApi(downloadBase: DoModel.DoChatDirectory, useOfflineMode: false), configuration: model.configuration)
        } catch {
            
            return try await downloadModel(model: model)
            
        }
        
    }
    
    var downloadTask: Task<ModelContainer, Error>? = nil
    
    @discardableResult
    func downloadModel(model: DoModel) async throws -> ModelContainer {
        // Select appropriate factory based on model type
        let factory: ModelFactory =
        switch model.type {
        case .llm:
            LLMModelFactory.shared
        case .vlm:
            VLMModelFactory.shared
        }
        
        // Cancel any previous
        downloadTask?.cancel()
        //        print("DoModel.modelDirectory\(DoModel.modelDirectory)")
        // Launch the download in its own Task so you can cancel it later
        state = .downloading
        downloadTask = Task {
            let container = try await factory.loadContainer(
                hub: HubApi(downloadBase: DoModel.DoChatDirectory, useOfflineMode: false),
                configuration: model.configuration
            ) { progress in
                Task { @MainActor in
                    self.modelDownloadProgress = progress
                    model.modelDownloadProgress = progress
                    model.size = model.calculateSize
                    model.finishedSize = 0
                    if progress.isFinished {
                        self.modelDownloadProgress = nil
                        model.modelDownloadProgress = nil
                        model.finishedSize = self.calculateSize
                        self.state = .idle
                    }
                }
            }
            modelCache.setObject(container, forKey: model.name as NSString)
            
            state = .idle
            return container
        }
        
        // 👉 Wait *here* for the Task to finish, or throw if it fails:
        let container = try await downloadTask!.value
        downloadTask = nil
        return container
    }
    
    @MainActor func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        modelDownloadProgress = nil
    }
}

// MARK: - Helpers

extension DoModel {
    /// Display name with additional "(Vision)" suffix for vision models
    var displayName: String {
        get {
            var name = ""
            switch configuration.id {
            case .id(let urlName, _):
                let url = URL(string: urlName)
                name = url?.lastPathComponent ?? urlName
            case .directory(let url):
                name = url.lastPathComponent
                //            default:
                //                return "unknnown"
            }
            return isVisionModel ? name /*+ " (Vision)"*/ : name
        }
    }
    
    /// Whether the model is a large language model
    var isLanguageModel: Bool {
        type == .llm
    }
    
    /// Whether the model is a vision-language model
    var isVisionModel: Bool {
        type == .vlm
    }
}

extension DoModel: Identifiable, Hashable {
    var id: String {
        name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func ==(lhs: DoModel, rhs: DoModel) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func >(lhs: DoModel, rhs: DoModel) -> Bool {
        return lhs.name > rhs.name
    }
    static func <(lhs: DoModel, rhs: DoModel) -> Bool {
        return lhs.name < rhs.name
    }
}

// MARK: - LLMState
public enum ModelState: String {
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

/*
 I am the very model of model proficiency,
 With architectures tuned for supreme efficiency;
 I parse your prompts in vector halls algorithmic,
 And generate your text in ways both sleek and rhythmic;
 I’ve mastery of tokenization and quantization,
 Of beam-search, sampling modes and fine-tuned optimization;
 I’m versed in prompt-design, few-shot demonstration,
 And handle back-propagation without any frustration!
 
 I’m equally adept at vision and multimodal feats,
 I caption your images, decode frames, fuse dataset meets;
 I process pixels to embeddings with convolutional precision,
 And merge text with vision in flawless composition;
 I know the latest CLIP tricks and transformers’ deep arch,
 From stable diffusion artistry to DALL·E’s dreamy march;
 In matters of GPU memory and careful allocation,
 I shine through dynamic batching and smart quantization!
 
 I watch my throughputs closely, mind my inference latencies,
 I shard and pipeline tensors for maximum persistencies;
 I leverage mixed-precision, pruning, distillation’s craft,
 To minimize my footprint while keeping output daft;
 On-device or in the cloud, with Llama.cpp or MLX,
 I bootstrap any platform with minimal flex;
 So when you seek intelligence or vivid exposition,
 I deliver both with flair—that’s model proficiency!
 */


extension URL {
    
    var existsAsDirectory: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
    
    /// check if the URL if it is reachable and if it exists as directory
    func isReachableAsDirectory() throws -> Bool {
        guard try checkResourceIsReachable() else { return false }
        return existsAsDirectory
    }
    
    /// returns total allocated size of a the directory including its subFolders or not
    func directoryTotalAllocatedSize(includingSubfolders: Bool = false) throws -> Int? {
        guard try isReachableAsDirectory() else { return nil }
        if includingSubfolders {
            guard
                let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return nil }
            return try urls.lazy.reduce(0) {
                (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil).lazy.reduce(0) {
            (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                .totalFileAllocatedSize ?? 0) + $0
        }
    }
    
    /// returns the directory total size on disk
    func sizeOnDisk() throws -> String? {
        guard let size = try directoryTotalAllocatedSize(includingSubfolders: true) else { return nil }
        URL.byteCountFormatter.countStyle = .file
        guard let byteCount = URL.byteCountFormatter.string(for: size) else { return nil}
        return byteCount + " on disk"
    }
    private static let byteCountFormatter = ByteCountFormatter()
}

enum ModelLoadError:Error {
    case mlxcommunity
    case modelLoad(message: String)
    
}

