//  ContentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI
import FlexView

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var document: DoChatStudioDocument
    @State private var ratio: CGFloat = 0.5
    @State private var childRatio: CGFloat = 0.5
    @State private var isDragging: Bool = false
#if os(iOS)
    @State var oniPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
#elseif os(macOS)
    let oniPhone: Bool = false
#endif
    
    var body: some View {
        Group {
            //            Spacer(minLength: 0)
            //
            if document.url == nil {
                SelectModelView(document: document)
            }
            
            if  document.llm != nil {
                //                Group {
                if oniPhone {
#if os(iOS)
                    VStack {
                        TabView {
                            
                            ModelConfigView(document: document, llm: document.llm!)
                                .tabItem {
                                    Label("Model Configuration", systemImage: "book.fill")
                                }
                                .padding()
                            
                            ChatHistoryView(document: document, llm: document.llm!)
                                .tabItem {
                                    Label("Chat", systemImage: "message.fill")
                                }
                                .padding()
                            
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always   ))

                        Spacer()
                    }
#endif
                } else {
                    FlexView(
                        children: [
                            {AnyView(ModelConfigView(document: document, llm: document.llm!))
                            }(),
                            {AnyView(ChatHistoryView(document: document, llm: document.llm!))
                            }(),
                        ],
                        ratio: $ratio,
                        childRatio: $childRatio,
                        isDragging: $isDragging,
                        configuration: FlexView.Configuration(
                            splitDirection: .horizontal,
                            innerPadding: 5.0,
                            showsCrosshair: true,
                            crosshairView: crosshairView(),
                            secondaryOrientation: true
                        )
                    )
                    .padding()
                }
            } else {
                HStack {
                    Spacer()
                    VStack {
                        if (document.url != nil && document.llm == nil) {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                            ErrorView(errorString: "Model Loading...")
                        } else {
                            ErrorView(errorString: "No File Selected")
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
//                .background(colorScheme == .dark ? .brown.opacity(0.25) : .brown.opacity(0.25) )
//                .blendMode(.normal/*.luminosity*/)
        }
    }
    
    
    #Preview {
        ContentView(document: DoChatStudioDocument(text: "Chat"))
    }
    
    
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
    
    struct ErrorView: View {
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
        //    let yellowLight = Color.init(hue: hue, saturation: 1.0, brightness: 0.92, opacity: 1.0)
        //    let yellowDark = Color.init(hue: hue, saturation: 1.0, brightness: 0.65, opacity: 1.0)
        
        let crossHairReturnView =
        Group {
            //        let gradient = LinearGradient(colors: [yellowLight, yellowDark], startPoint: .bottomTrailing, endPoint: .topLeading)
            Circle()
                .fill(DoStyle.gradient(color: .orange))
                .shadow(radius: 2)
                .overlay(Circle().fill(Color.clear).strokeBorder(DoStyle.gradient(color: .orange), lineWidth: 5).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
                .frame(width: 24, height: 24)
        }
        return AnyView(crossHairReturnView)
    }
