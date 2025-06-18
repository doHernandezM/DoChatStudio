////
////  HubExtension.swift
////  DoChatStudio
////
////  Created by Cosas on 6/17/25.
////
//
//import Foundation
//import Hub
//import MLX
//import MLXLMCommon
//import Tokenizers
//
//extension ModelConfiguration {
//    
//    public init(downloadBase: URL? = nil, hfToken: String? = nil, endpoint: String = "https://huggingface.co", useBackgroundSession: Bool = false, useOfflineMode: Bool? = nil) {
//        self.hfToken = hfToken ?? Self.hfTokenFromEnv()
//        if let downloadBase {
//            self.downloadBase = downloadBase
//        } else {
//            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            self.downloadBase = documents.appending(component: "huggingface").appending(component: "models").appending(component: "mlx-community")
//        }
//        self.endpoint = endpoint
//        self.useBackgroundSession = useBackgroundSession
//        self.useOfflineMode = useOfflineMode
//        NetworkMonitor.shared.startMonitoring()
//    }
//    
//    public func modelDirectory(hub: HubApi = HubApi()) -> URL {
//        switch id {
//        case .id(let id):
//            // download the model weights and config
//            let repo = Hub.Repo(id: id)
//            
//            return hub.localRepoLocation(repo)
//
//        case .directory(let directory):
//            return directory
//        }
//    }
//}
//
//public extension HubApi {
//    func localRepoLocation(_ repo: Repo) -> URL {
//        downloadBase.appending(component: repo.type.rawValue).appending(component: repo.id)
//    }
//}
//
