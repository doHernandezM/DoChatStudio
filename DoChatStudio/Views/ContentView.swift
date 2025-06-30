//  ContentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI
import FlexView

struct ContentView: View {
    @ObservedObject var document: DoChatStudioDocument
    
    @State private var ratio: CGFloat = 0.5
    @State private var childRatio: CGFloat = 0.5
    @State private var isDragging: Bool = false
    
#if os(iOS)
    @State var oniPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone
#elseif os(macOS)
    let oniPhone: Bool = false
#endif
    
    init(document: DoChatStudioDocument, url: URL?) {
        self.document = document
        if url != nil{
            self.document.setFileURL(url: url!)
        }
    }
    
    var body: some View {
        if let model = document.chatModel {            if oniPhone {
#if os(iOS)
                TabView {
                    ChatAdjustmentView(viewModel: document.chatModel!)
                        .tabItem {
                            Label("Model Configuration", systemImage: "book.fill")
                        }
                    
                    PerformanceView(viewModel: document.chatModel!)
                        .tabItem {
                            Label("Peformance", systemImage: "chart.bar.fill")
                        }
                    
                    ChatView(viewModel: model)
                        .tabItem {
                            Label("Chat", systemImage: "message.fill")
                        }
                }
                .environmentObject(document)
                .tabViewStyle(PageTabViewStyle())

#endif
            } else {
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
            }
        }
    }
}

#Preview {
    ContentView(document: DoChatStudioDocument(text: "Chat"), url: nil)
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
            .fill(DoStyle.gradient(color: Color.accentColor))
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

struct SideT: InsettableShape {
    var insetAmount = 0.0
    var thickness:CGFloat
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - thickness, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - thickness, y: rect.midY - (thickness / 2)))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY - (thickness / 2)))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + (thickness / 2)))
            path.addLine(to: CGPoint(x: rect.maxX - thickness, y: rect.midY + (thickness / 2)))
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
