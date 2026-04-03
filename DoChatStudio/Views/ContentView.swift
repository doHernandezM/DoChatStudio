//  ContentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI
import FlexView
import StoreKit

struct ContentView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    @ObservedObject var document: DoChatStudioDocument
    
    @State private var currentTab: Int = 0
    @State private var ratio: CGFloat = 0.5
    @State private var childRatio: CGFloat = 0.5
    @State private var isDragging: Bool = false
    @State var closeWindowAlert:Bool = false
    
#if os(iOS)
    @State var isiPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    @State var isiPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    @State var toolbarPlacement: ToolbarPlacement = .automatic
#elseif os(macOS)
    let isiPhone: Bool = false
    let isiPad: Bool = false
    let toolbarPlacement: ToolbarPlacement = .automatic
#endif
    var isMobile: Bool {
        get {
            return isiPad || isiPhone
        }
    }
    @State private var preferredColumn = NavigationSplitViewColumn.detail
    
    init(document: DoChatStudioDocument,
         url: URL?
    ) {
        
        self.document = document
        
        if url != nil{
            self.document.setFileURL(url: url!)
        }
    }
    
    var body: some View {
        
        //        if let model = document.chat {
        //            NavigationSplitView{
        
        //                    SidebarView(vm: Binding<ChatModel>(
        //                        get:{model},
        //                        set:{newValue in
        //                            document.chat = newValue}
        //                    ))
        
        //                .navigationSplitViewColumnWidth(min: CGFloat(StyleModel.sidebarMinWidth), ideal: CGFloat(StyleModel.sidebarMinWidth), max: CGFloat(StyleModel.sidebarMaxWidth))
        
        //            } detail: {
        NavigationStack{
            ChatView(viewModel: document.chat)//bacgrounds here
                .padding(4)
            
                .environmentObject(document)
#if os(macOS)
                .dismissalConfirmationDialog(
                    "Model Is Generating",
                    shouldPresent: document.blockTermination,
                    actions: {
                        
                        /// A destructive button that appears in red.
                        Button(role: .destructive) {
                            document.chat.cancelGeneration()
                        } label: {
                            Text("Stop Generation")
                        }
                        
                        /// A cancellation button that appears with bold text.
                        Button("Cancel", role: .cancel) {
                            // Perform cancellation
                        }
                        
                    },
                    message: {
                        Text(
                            "This model is still generation. Are you sure you want to close it now?"
                        )
                    })
#endif
            //            }
            //            } else {
            //                EmptyView()
            //            }
            
        }
    }
    
    #Preview {
        {
            let document = DoChatStudioDocument(text: "Chat")
            return ContentView(document: document, url: nil)
        }()
    }
    
    struct SideT: InsettableShape {
        var insetAmount = 0.0
        var thickness:CGFloat
        
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX - thickness, y: rect.minY))
                path
                    .addLine(
                        to: CGPoint(
                            x: rect.maxX - thickness,
                            y: rect.midY - (thickness / 2)
                        )
                    )
                path
                    .addLine(
                        to: CGPoint(x: rect.minX, y: rect.midY - (thickness / 2))
                    )
                path
                    .addLine(
                        to: CGPoint(x: rect.minX, y: rect.midY + (thickness / 2))
                    )
                path
                    .addLine(
                        to: CGPoint(
                            x: rect.maxX - thickness,
                            y: rect.midY + (thickness / 2)
                        )
                    )
                path.addLine(to: CGPoint(x: rect.maxX - thickness, y: rect.maxY))
                path.closeSubpath()
                
            }
        }
        
        func inset(by amount: CGFloat) -> some InsettableShape {
            var arc = self
            arc.insetAmount += amount
            return arc
        }
        
    }
}
    
    
