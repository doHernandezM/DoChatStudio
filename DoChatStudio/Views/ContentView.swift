//  ContentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI
import FlexView

struct ContentView: View {
    
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State var nav: NavigationSplitViewVisibility
    
    @ObservedObject var document: DoChatStudioDocument
    
    @State private var currentTab: Int = 0
    @State private var ratio: CGFloat = 0.5
    @State private var childRatio: CGFloat = 0.5
    @State private var isDragging: Bool = false
    @State var closeWindowAlert:Bool = false
    
#if os(iOS)
    @State var isiPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    @State var isiPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    @State var toolbarPlacement: ToolbarPlacement = .navigationBar
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
    
    
    init(
        nav: NavigationSplitViewVisibility = .all,
        document: DoChatStudioDocument,
        url: URL?
    ) {
        self.nav = nav
        self.document = document
        
        if url != nil{
            self.document.setFileURL(url: url!)
        }
    }
    
    var body: some View {
        
        
        if let model = document.chat {
            Group {
                NavigationSplitView(sidebar: {
                    VStack{
                        SidebarTabView(vm: Binding<ChatModel>(
                            get:{model},
                            set:{newValue in
                                document.chat = newValue}
                        ))
                        
                        SidebarTabGroupView(vm: Binding<ChatModel>(
                            get:{model},
                            set:{newValue in
                                document.chat = newValue}
                        ))
                    }
                }, detail: {
                    ChatView(viewModel: model)
                        .padding(8)
                        .toolbar(id: "mainToolBar"){
                            ToolbarItem(id:"clearChat") {
                                Button(action: {model.clear([.chat])}){
                                    VStack{
                                        Image(systemName: "bubble.fill")
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(Color.accentColor)
                                            .font(.system(.title3))
                                            .overlay(alignment: .topTrailing, content: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(Color.white, Color.red)
                                                    .font(.system(.caption))

                                            })
                                        Text("Clear Chat").font(.system(.caption))
                                    }
                                    .frame(maxHeight: .infinity)
                                }
                                .buttonStyle(.plain)
                                .padding()
                            }
                            
                        }
                })
                .environmentObject(document)
#if os(macOS)
                .dismissalConfirmationDialog(
                    "Model Is Generating",
                    shouldPresent: document.blockTermination,
                    actions: {
                        
                        /// A destructive button that appears in red.
                        Button(role: .destructive) {
                            document.chat?.cancelGeneration()
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
            }
        } else {
            EmptyView()
        }
        
        
    }
    
}
//#endif
/*       } else {
 FlexView(
 children: [
 {AnyView(ChatAdjustmentView(viewModel: document.chatModel!)
 .background(.black.opacity(0.5))
 .clipShape(RoundedRectangle(cornerRadius: 10))
 )
 }(),
 {AnyView(PerformanceView(viewModel: document.chatModel!)
 .background(.black.opacity(0.5))
 .clipShape(RoundedRectangle(cornerRadius: 10))
 )
 }(),
 {AnyView(ChatView(viewModel: model)
 .clipShape(RoundedRectangle(cornerRadius: 2))
 )
 }(),
 ],
 ratio: $ratio,
 childRatio: $childRatio,
 isDragging: $isDragging,
 configuration: FlexView.Configuration(
 splitDirection: .horizontal,
 innerPadding: 12,
 showsCrosshair: true,
 crosshairView: crosshairView(),
 secondaryOrientation: true
 )
 )
 .padding()
 .environmentObject(document)
 .dismissalConfirmationDialog("Model Is Generating", shouldPresent:
 document.blockTermination, actions: {
 
 /// A destructive button that appears in red.
 Button(role: .destructive) {
 document.chatModel?.cancelGeneration()
 } label: {
 Text("Stop Generation")
 }
 
 /// A cancellation button that appears with bold text.
 Button("Cancel", role: .cancel) {
 // Perform cancellation
 }
 
 }, message: {
 Text("This model is still generation. Are you sure you want to close it now?")
 })
 }
 }
 }
 }
 */
#Preview {
    {
        //         let model = ChatViewModel(mlxService: MLXService())
        var document = DoChatStudioDocument(text: "Chat")
        //         document.chat = model
        return ContentView(document: document, url: nil)
    }()
}
/*
 extension Color {
 
 enum Level {
 case light
 case medium
 case high
 }
 
 func opacity(_ colorScheme: ColorScheme, _ level: Level = .light) -> Color {
 switch level {
 case .light:
 return self.opacity(colorScheme == .light ? 0.5 : 0.157)
 case .medium:
 return self.opacity(colorScheme == .light ? 0.7 : 0.314)
 case .high:
 return self.opacity(colorScheme == .light ? 0.9 : 0.928)
 }
 }
 }
 
 struct DoErrorView: View {
 let errorString: String
 let errorDescription: String? = nil
 
 var body: some View {
 VStack(){
 Text(errorString)
 .font(.largeTitle)
 Text(errorDescription ?? "")
 .font(.body)
 }
 }
 }
 
 private func crosshairView(_ hue: Double = 0.1175) -> AnyView {
 let crossHairReturnView =
 Group {
 Circle()
 .fill(DoStyle.gradient(color: Color.transparentAccent))
 .shadow(radius: 2)
 .overlay(SideT(thickness: 4).fill(Color.gray.opacity(0.5)).strokeBorder(DoStyle.gradient(color: Color.black.opacity(0.25)), lineWidth: 1).shadow(radius: 2).padding(6))
 .frame(width: 24, height: 24)
 }
 return AnyView(crossHairReturnView)
 }
 
 struct Triangle: InsettableShape {
 var insetAmount = 0.0
 
 func path(in rect: CGRect) -> Path {
 Path { path in
 path.move(to: CGPoint(x: rect.midX, y: rect.minY))
 path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
 path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
 path.closeSubpath()
 }
 }
 
 func inset(by amount: CGFloat) -> some InsettableShape {
 var arc = self
 arc.insetAmount += amount
 return arc
 }
 
 }
 */
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


struct SidebarTabView: View {
    //    @Binding var currentTab: Int
    @Binding var vm: ChatModel
    @State var size: CGSize = .zero
    
    var body: some View {
        HStack(alignment: .bottom){
            Button {
                vm.viewData.currentSelectedTab = 0
            } label: {
                VStack{
                    Image(systemName: "book.circle")
                        .font(.system(.title2))
                    Text("Models")
                }
                .foregroundStyle(
                    vm.viewData.currentSelectedTab == 0 ? Color.accentColor : Color.primary
                )
                .contentShape(
                    RoundedRectangle(cornerRadius: 5)
                ) // Defines tappable area
            }
            
            
            Button {
                vm.viewData.currentSelectedTab = 1
            } label: {
                VStack{
                    Image(systemName: "gear")
                        .font(.system(.title2))
                    Text("Settings")
                }
                .foregroundStyle(
                    vm.viewData.currentSelectedTab == 1 ? Color.accentColor : Color.primary
                )
                .contentShape(
                    RoundedRectangle(cornerRadius: 5)
                ) // Defines tappable area
                
            }
            
            Button {
                vm.viewData.currentSelectedTab = 2
            } label: {
                VStack{
                    Image(systemName: "gauge.with.needle")
                        .font(.system(.title2))
                    Text("Performance")
                }
                .foregroundStyle(
                    vm.viewData.currentSelectedTab == 2 ? Color.accentColor : Color.primary
                )
                .contentShape(
                    RoundedRectangle(cornerRadius: 5)
                ) // Defines tappable area
            }
            
            
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct SidebarTabGroupView: View {
    //    @Binding var currentTab: Int
    @Binding var vm: ChatModel
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, content: {
                LazyVStack(pinnedViews: [.sectionFooters]){
                    Section() {
                        
                        switch vm.viewData.currentSelectedTab {
                        case 1:
                            ConfigurationView(viewModel: vm)
                                .padding()
                        case 2:
                            PerformanceView(viewModel: vm)
                                .padding()
                        default:
                            ModelsListView(vm: vm)
                        }
                    } footer: {
                        
                        ModelListView(selectedModel: Binding<DoModel?>(
                            get: {
                                vm.model
                            },
                            set: { _ in }))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial, in: Rectangle())

                    }
                }
            })
            .scrollContentBackground(.hidden)

        }
        .frame(minWidth: 44 * 6)
    }
    
}
