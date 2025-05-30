//  ChatView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI

struct ChatHistoryView: View {
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: StatefulLLM
    @Environment(\.colorScheme) var colorScheme
        
    @State var showX: Bool = false
    
    let emptyID: UUID = UUID()
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ScrollView {
                ForEach(document.messageHistory) { message in
                    ChatBubbleView(chat: message)
                        .padding(2)
                        .overlay(alignment: .topTrailing) {
                            if showX {
//                                GeometryReader { geometry in
                                    Image(systemName: "x.square.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.red)
//                                        .padding(.leading, chat.role == .bot ? geometry.frame(in: .local).width : 0)
//                                }
                            }
                        }
                }
                if (document.llm?.isThinking ?? false) {
                    ChatBubbleView(chat: Message(role: .bot, content: document.llm?.output ?? "", ignored: false, llmState: llm.llmState))
                }
            }
            .defaultScrollAnchor(.bottom)
            .cornerRadius(4)
            .onHover { i in
                showX = i
            }
            
            ChatInputView(document: document, llm: llm)
            
                
            
        }
        .padding()
//        .background(Color.black.opacity(0.075)).cornerRadius(10)
        .background(colorScheme == .dark ? .brown.opacity(0.25) : .brown.opacity(0.25) )
        .blendMode(.normal/*.luminosity*/)
        .cornerRadius(10)
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(emptyID, anchor: .bottom)
        }
    }
}

#Preview {
    ChatHistoryView(document: DoChatStudioDocument(text: "Chat"), llm: StatefulLLM(from: "")!)
}

// A view that lays out the color swatches in a grid
struct ColorsSwatchesView: View {
    // List of SwiftUI built-in colors with their display names
    let colors: [(name: String, color: Color)] = [
        ("primary", .primary),
        ("secondary", .secondary),
        ("black", .black),
        ("blue", .blue),
        ("gray", .gray),
        ("green", .green),
        ("indigo", .indigo),
        ("cyan", .cyan),
        ("teal", .teal),
        ("brown", .brown),
        ("mint", .mint),
        ("orange", .orange),
        ("pink", .pink),
        ("purple", .purple),
        ("red", .red),
        ("white", .white),
        ("yellow", .yellow),
        ("clear", .clear)
    ]
    
    // Configure a grid layout with three columns
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        //        ScrollView {
        LazyVGrid(columns: columns) {
            ForEach(colors, id: \.name) { item in
                ColorSwatch(color: item.color, name: item.name)
            }
        }.frame(width: 640, height: 640)
        //            .padding()
        //        }
    }
}

// Preview for the ColorsSwatchesView
struct ColorsSwatchesView_Previews: PreviewProvider {
    static var previews: some View {
        ColorsSwatchesView()
    }
}
