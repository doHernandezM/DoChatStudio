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
        HStack{
            Spacer(minLength: 0)
            if document.url != nil && document.llm == nil {
                VStack {
                    Spacer()
                    Group {
                        Text("Model is Loading...")
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    }
                    //                        .scaleEffect(2.0, anchor: .center) // Makes the s pinner
                    Spacer()
                }
            }
            
            if document.url == nil {
                SelectModelView(document: document)
            }
            
            if  document.llm != nil {
                Group {
                    if oniPhone {
#if os(iOS)
                        TabView {
                            if let _ = document.llm {
                                VStack {
                                    ModelInfoView(document: document, llm: document.llm!)
                                    ModelAdjustmentView(document: document, llm: document.llm!)
                                }
                                ChatHistoryView(document: document, llm: document.llm!)
                                    .padding()
                                
                            } else {
                                ErrorView(errorString: "No Model Selected")
                            }
                        }
                        .tabViewStyle(.page)
#endif
                    } else {
                        FlexView(
                            children: [
                                {
                                    AnyView(ModelInfoView(document: document, llm: document.llm!))
                                }(),
                                {if let _ = document.llm {
                                    return AnyView(ModelAdjustmentView(document: document, llm: document.llm!))
                                } else {
                                    return AnyView(ErrorView(errorString: "No Model Selected"))
                                }}(),
                                {if let _ = document.llm {
                                    return AnyView(ChatHistoryView(document: document, llm: document.llm!))
                                } else {
                                    return AnyView(ErrorView(errorString: "No Model Selected"))
                                }}(),
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
                }
            }
            Spacer(minLength: 0)
        }
        .background(colorScheme == .dark ? .brown.opacity(0.25) : .brown.opacity(0.25) )
        .blendMode(.normal/*.luminosity*/)
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
