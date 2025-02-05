//  ChatView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI

struct ChatHistoryView: View {
    
    let emptyID: UUID = UUID()
    
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: LLM
    @State var input = "Give me seven national flag emojis people use the most;\rYou must include South Korea."
    
    
    var body: some View {
        VStack(alignment: .leading) {
            
            ScrollView {
                ForEach(document.history, id: \.id) { chat in
                    ChatView(chat: chat)
                        .padding(2)
                }
                if (document.llm?.isThinking ?? false) {
                    ChatView(chat: Chat(role: .bot, content: document.llm?.output ?? "", ignored: false))
                }
            }
            .defaultScrollAnchor(.bottom)
            .cornerRadius(4)
            
            HStack(spacing: 1) {
                HStack() {
                    TextField("Chat", text: $input, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .onSubmit {document.respond(input: input)}
                        .padding(.leading)
                }
                
                HStack() {
                    Button(action: {document.respond(input: input)}) {
                        Image(systemName: "play")
                            .frame(width:64, height: 64)
                            .background(Circle().fill(DoStyle.gradient(color: .blue.mix(with: .black, by: 0.25))))
                            .overlay(Circle().fill(Color.clear).strokeBorder(DoStyle.gradient(color: .blue.mix(with: .black, by: 0.35)), lineWidth: 2).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
                    }
                    .buttonStyle(.plain)
                   
                    
                    Button(action: document.stop) {
                        Image(systemName: "pause")
                            .frame(width: 64, height: 48)
                            .background(RoundedRectangle(cornerRadius: 10).fill(DoStyle.gradient(color: .red)))
                            .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.clear).strokeBorder(DoStyle.gradient(color: .red.mix(with: .black, by: 0.1)), lineWidth: 2).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
                    }
                    .buttonStyle(.plain)
            
                }
                .font(.title).fontWeight(.heavy)
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 6).fill(DoStyle.gradient(color: .clear, transparent: true))
            .overlay(RoundedRectangle(cornerRadius: 6).fill(Color.clear).strokeBorder(DoStyle.gradient(color: .clear.mix(with: .black, by: 0.65), transparent: true), lineWidth: 2).shadow(radius: 2).rotationEffect(Angle(degrees: 180))))
        }
        .padding(6)
        
        .background(Color.black.opacity(0.075)).cornerRadius(10)
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(emptyID, anchor: .bottom)
        }
    }
}

#Preview {
    ChatHistoryView(document: DoChatStudioDocument(), llm: LLM(from: "")!)
}
