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
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
#endif
    static var documents: [DoChatStudioDocument] = []
    
    init() {
    }
    
    
    
    var body: some Scene {
#if os(macOS)
        DocumentGroup(newDocument: DoChatStudioDocument(text: "")) { file in
            ContentView(document: file.document, url: file.fileURL)
        }
//        .windowToolbarStyle(.unified)
#else
        DocumentGroup(newDocument: DoChatStudioDocument(text: "")) { file in
            ContentView(document: file.document, url: file.fileURL)

//            if let model = file.document.chatModel {
//                
//                NavigationSplitView(sidebar: {
//                    ExtractedView(currentTab: currentTab, vm: model)
//                }, detail: {
//                    ChatView(viewModel: model)
//                        .toolbar(content: {
//                            ToolbarItemGroup(content: {
//                                ToolbarSelectedModelView(vm: file.document.chatModel!)
//                            })
//                            ToolbarItemGroup(content: {
//                                ToolbarButtonsView(vm: file.document.chatModel!)
//                            })
//                            //
//                            //                            Button(action: {
//                            //                                file.document.chatModel?.clear([.chat, .meta])
//                            //                            }, label: {
//                            //                                ZStack(alignment: .center){
//                            //                                    VStack{
//                            //                                        Image(systemName: "text.badge.xmark")
//                            //                                            .symbolRenderingMode(.palette)
//                            //                                            .foregroundStyle(.red, Color.transparentAccent)
//                            //                                            .font(.system(.title))
//                            //                                        Text("Clear Chat")
//                            //                                    }
//                            //                                }
//                            //                            })
//                            //                            .buttonStyle(.plain)
//                            
//                        })
//                    
//                        .navigationSplitViewStyle(.prominentDetail)
//                    //                        .toolbarVisibility(/*isMobile ? .hidden :*/ .visible, for: .automatic)
//                        .padding()
//                    
//                    
//                })
//                .environmentObject(file.document)
//            } else {
//                EmptyView()
//            }
            
        }
        DocumentGroupLaunchScene("doChat", {}, background:{
            Color.accentColor
            
        })
#endif
        
    }
    
    
}
