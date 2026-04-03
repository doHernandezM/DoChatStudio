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
class ModelModel {
    /// Name of the model
    static let fileManager = FileManager.default
    static let doChatDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "doChat")
    static let modelDirectory = doChatDirectory.appending(path: "models")
    static let mlxCommunityDirectory = modelDirectory.appending(path: "mlx-community")
    static func ensureDirectories() {
        let fm = FileManager.default
        for url in [doChatDirectory, modelDirectory, mlxCommunityDirectory] {
            do {
                try fm.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print("Failed to create directory \(url): \(error)")
            }
        }
    }
    
    var name: String
    
    ///Current model of the state
    var state: ModelState? = nil
    
    var size: Int64 = 0
    /// Total model directory size
    var finishedSize: Int64 = 0
    
    var calculateSize: Int64 {
        get {
            var modelBytes:Int64 = 0
            do {
                modelBytes = Int64(try self.folderURL.directoryTotalAllocatedSize(includingSubfolders: true) ?? 0)
                return modelBytes
                
            } catch {
                //Model not downloaded or available on disk
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
    
    var isCustomModel:Bool = false
    
    /// Configuration settings for model initialization
    let configuration: ModelConfiguration
    
    /// Type of the model (language or vision-language)
    let type: ModelType
    
    /// Defines the type of language model
    enum ModelType: String, Codable {
        /// Large language model (text-only)
        case llm
        /// Vision-language model (supports images and text)
        case vlm
    }
    
    init(name: String, configuration: ModelConfiguration, type: ModelType, isCustomModel: Bool = false) {
        ModelModel.ensureDirectories()
        
        self.name = name
        self.configuration = configuration
        self.type = type
        
        self.isCustomModel = isCustomModel
        
        self.localURL = self.folderURL
        
        self.size = self.calculateSize
        
    }
    
    //    static func modelFo55lders(isCustomModel: Bool) -> [URL] {
    //        var modelFolders: [URL] = []
    //
    //        do {
    //            if isCustomModel {
    //                modelFolders = try fileManager.contentsOfDirectory(at:customModelDirectory, includingPropertiesForKeys: [.fileSizeKey,.fileAllocatedSizeKey])
    //            } else {
    //                modelFolders = try fileManager.contentsOfDirectory(at:mlxCommunityDirectory, includingPropertiesForKeys: [.fileSizeKey,.fileAllocatedSizeKey])
    //            }
    //        } catch ModelLoadError.mlxcommunity {
    //            print("Error: Contents mlx-community not loaded")
    //        } catch ModelLoadError.custom {
    //            print("Error: Custom model: \(modelFolders)")
    //        } catch {
    //            print("modelFolders() Error: \(error.localizedDescription)")
    //        }
    //
    //        return modelFolders
    //    }
    
    static var hub: HubApi {
        get {
            let base: URL
            base = ModelModel.doChatDirectory
            
            
            return HubApi(downloadBase: base, useOfflineMode: false)
        }
    }
    var folderURL: URL {
        switch configuration.id {
        case .directory(let url):
            // If the model is a local directory, use it directly.
            return url
            
        case .id(let id, _):
            // Split the id into components like ["mlx-community", "Foo-7B-4bit"] or ["user", "repo"]
            let components = id.split(separator: "/").map(String.init)
            
            return components.reduce(ModelModel.modelDirectory) { partial, comp in
                partial.appendingPathComponent(comp, isDirectory: true)
            }
            
        }
    }
    
    @MainActor @discardableResult
    func deleteModel() -> Bool {
        if self.downloadTask != nil{
            self.cancelDownload()
        }
        
        if self.localURL == nil {return false}
        do {
            try ModelModel.fileManager.removeItem(at: self.localURL!)
            
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
    func load(model: ModelModel, cacheLimit: Int = 204 * 1024 * 1024) async throws -> ModelContainer {
        state = .initializing
        // Set GPU memory limit to prevent out of memory issues
#if targetEnvironment(simulator)
    // Simulator does not support MLX GPU metrics; skip to avoid crashes.
        #else
        MLX.GPU.set(cacheLimit: cacheLimit)
        //        MLX.GPU.set(memoryLimit: 2048 * 1024 * 1024, relaxed: true)
        #endif
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
            return try await factory.loadContainer(hub: ModelModel.hub, configuration: model.configuration)
        } catch {
            
            return try await downloadModel(model: model)
            
        }
        
    }
    
    var downloadTask: Task<ModelContainer, Error>? = nil
    
    @discardableResult
    func downloadModel(model: ModelModel) async throws -> ModelContainer {
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
        print("try to download model:\(model.configuration)")
        downloadTask = Task {
            print("start download task")
            let container = try await factory.loadContainer(
                hub:ModelModel.hub,
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
    
    static func makeCustomModel(from input: String, type: ModelModel.ModelType) async -> ModelModel? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
//        if let url = URL(string: trimmed), url.isFileURL, url.existsAsDirectory {
//            let config = ModelConfiguration(directory: url)
//            print("customURL: \(url)")
//            return ModelModel(name: url.lastPathComponent, configuration: config, type: type, isCustomModel: true)
//        }
        
        // Keep the full id (e.g., "user/repo" or "mlx-community/ModelName")
//        let cfg = try await ModelModel.hub.configurationFromHF(repoId: "mlx-community/Phi-3.5-mini-instruct-4bit")
//        let model = ModelModel(name: "phi3.5-mini-4bit", configuration: cfg, type: .llm, isCustomModel: true)
        print("custom: \(trimmed)")
        let config = (try? await ModelModel.hub.configurationFromHF(repoId: trimmed)) ?? ModelConfiguration(id: trimmed)
        return ModelModel(name: trimmed, configuration: config, type: type, isCustomModel: true)
    }
    
    
    
}

// MARK: - Helpers

extension ModelModel {
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

extension ModelModel: Identifiable, Hashable {
    var id: String {
        name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func ==(lhs: ModelModel, rhs: ModelModel) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func >(lhs: ModelModel, rhs: ModelModel) -> Bool {
        return lhs.name > rhs.name
    }
    static func <(lhs: ModelModel, rhs: ModelModel) -> Bool {
        return lhs.name < rhs.name
    }
}

// MARK: - LLMState
public enum ModelState: String, Codable {
    case missing
    case initializing
    case idle
    case preparing
    case thinking
    case generating
    case finishing
    case stopping
    case paused
    case error
    case downloading
    case updating
    
    public var color: Color {
        switch self {
        case .missing:      return .gray
        case .initializing: return .pink
        case .idle:         return .blue
        case .preparing:    return .mint
        case .thinking:     return .teal
        case .generating:   return .cyan
        case .finishing:    return .green
        case .stopping:      return .gray
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
    case custom
    case modelLoad(message: String)
    
}

