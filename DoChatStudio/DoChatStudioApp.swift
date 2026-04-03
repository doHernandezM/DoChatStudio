//
//  DoChatStudioApp.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif


@main
struct DoChatStudioApp: App {
    
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
    
    var body: some Scene {
        
#if os(macOS)
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
