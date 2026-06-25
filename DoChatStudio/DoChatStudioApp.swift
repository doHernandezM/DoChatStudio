//
//  DoChatStudioApp.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

// Defines the app entry point, document scenes, inspectors, commands, and shared purchase state.

import SwiftUI
import Combine
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif


@main
struct DoChatStudioApp: App {
    /*
     UI-to-MLX interaction path:
     1. DocumentGroup opens or creates a DoChatStudioDocument.
     2. ContentView renders the document's ChatModel.
     3. ChatView binds prompt, model, and generation controls to that ChatModel.
     4. ChatModel calls MLXService, which prepares input and starts MLX generation.
     5. Streamed MLX output mutates the document's messages and refreshes SwiftUI.
     */
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    @StateObject
    private var entitlementManager: EntitlementManager
    
    @StateObject
    private var purchaseManager: PurchaseManager


    static var documents: [DoChatStudioDocument] = []
    
    init() {
        let entitlementManager = EntitlementManager()
        let purchaseManager = PurchaseManager(entitlementManager: entitlementManager)
        self._entitlementManager = StateObject(wrappedValue: entitlementManager)
        self._purchaseManager = StateObject(wrappedValue: purchaseManager)
        
    }
    
    /// Creates the document UI and gives every view access to shared purchase state.
    ///
    /// The LLM state itself is not global: each `DoChatStudioDocument` owns its
    /// own `ChatModel`, selected model, conversation, and generation settings.
    var body: some Scene {
        
#if os(macOS)
        DocumentGroup(newDocument: DoChatStudioDocument(text: "")) { file in
            // Passing the document into ContentView begins the UI-to-inference chain.
            ContentView(document: file.document, url: file.fileURL)
                .environmentObject(entitlementManager)
                .environmentObject(purchaseManager)
                .inspector(isPresented: Binding<Bool>(
                    get:{file.document.chat.style.showInspector},
                    set:{newValue in
                        file.document.chat.style.showInspector = newValue}
                ), content: {
                    // The inspector edits the same ChatModel used by ChatView, so model
                    // selection and sampling changes apply to the next generation.
                    SidebarView(vm: Binding<ChatModel>(
                        get:{file.document.chat},
                        set:{newValue in
                            file.document.chat = newValue}
                    ))
                    .environmentObject(entitlementManager)
                    .environmentObject(purchaseManager)
                    
                })
        }
        .commands {
            SidebarCommands()
            InspectorCommands()
            ToolbarCommands()
        }

        //        .windowToolbarStyle(.unified)
#else
        DocumentGroup(newDocument: DoChatStudioDocument(text: "")) { file in
            ContentView(document: file.document, url: file.fileURL)
                .environmentObject(entitlementManager)
                .environmentObject(purchaseManager)
                .inspector(isPresented: Binding<Bool>(
                    get:{file.document.chat.style.showInspector},
                    set:{newValue in
                        file.document.chat.style.showInspector = newValue}
                ), content: {
                    SidebarView(vm: Binding<ChatModel>(
                        get:{file.document.chat},
                        set:{newValue in
                            file.document.chat = newValue}
                    ))
                    .environmentObject(entitlementManager)
                    .environmentObject(purchaseManager)
                })
        }
        .commands {
            SidebarCommands()
            InspectorCommands()
            ToolbarCommands()
        }
        DocumentGroupLaunchScene("poos", {
            NewDocumentButton("Foos", for: DoChatStudioDocument.self) {
                try await withCheckedThrowingContinuation { continuation in
                    continuation.resume(returning: DoChatStudioDocument(text: ""))
                }
            }
        })
        
//        DocumentLaunchView(for: [.doChat]){
//            NewDocumentButton("Poo")
//        } onDocumentOpen: { file in
//            
//        }

        
#endif
        
#if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(entitlementManager)
                .environmentObject(purchaseManager)
        }
#endif
        
    }
    
    
}
//
//func loadDoChatStudioModel(from url: URL) throws -> DoChatStudioDocument {
//    let data = try Data(contentsOf: url)
//    let decoded = try JSONDecoder().decode(DoChatStudioDocument.self, from: data)
//    return decoded.chatModel
//}
