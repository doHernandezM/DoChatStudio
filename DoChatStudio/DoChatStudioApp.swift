//
//  DoChatStudioApp.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI
import Combine

    
@main
struct DoChatStudioApp: App {

//    @Environment(\.colorScheme) var colorScheme
    
    init() {
        
        
        
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: DoChatStudioDocument(text: "")) { file in
            Group {
                ContentView(document: file.document, url: file.fileURL)
            }
            .onAppear() {
                
//                print("RAM:")
                print("getAppMemoryUsage", getAppMemoryUsage())
                print("getAvailableMemory", getAvailableMemory())
            }
        }
    }
}
