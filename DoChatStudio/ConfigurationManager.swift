//
//  ConfigurationManager.swift
//  DoChatStudio
//
//  Created by Cosas on 2/7/25.
//

import Foundation
import SwiftUI

enum DebugLevel {
    case detailed
    case minimal
}

var kDebugMode: DebugLevel? = DebugLevel.minimal


class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let fileManager = FileManager.default
    
    let modelController = FileController(folderName: "Models")

    private let appDir: URL

    @Published var models: [URL] = []
    
    init() {
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appDir = appSupportDir.appendingPathComponent("doChatStudio", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        reloadModels()
       
    }
    
    func reloadModels() {
        models = modelController.scanFolder(fileType: "gguf")
    }
    
}
