//
//  ChatInputView.swift
//  DoChatStudio
//
//  Created by Cosas on 2/5/25.
//

import SwiftUI

struct ChatInputView: View {
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: LLM
    @State var input = "Give me seven national flag emojis people use the most; You must include South Korea."
    
    var body: some View {
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
                    Image(systemName: !llm.shouldPausePredicting ? "play" : "pause")
                        .frame(width:64, height: 64)
                        .background(Circle().fill(DoStyle.gradient(color: llm.llmState.color.mix(with: .black, by: 0.25))))
                        .overlay(Circle().fill(Color.clear).strokeBorder(DoStyle.gradient(color: llm.llmState.color.mix(with: .black, by: 0.35)), lineWidth: 2).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
                }
                .buttonStyle(.plain)
                
                if llm.isThinking {
                    Button(action: document.stop) {
                        Image(systemName: "stop")
                            .frame(width: 64, height: 48)
                            .background(RoundedRectangle(cornerRadius: 10).fill(DoStyle.gradient(color: .red)))
                            .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.clear).strokeBorder(DoStyle.gradient(color: .red.mix(with: .black, by: 0.1)), lineWidth: 2).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.title).fontWeight(.heavy)
            .padding()
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(DoStyle.gradient(color: .clear, transparent: true))
            .overlay(RoundedRectangle(cornerRadius: 6).fill(Color.clear).strokeBorder(DoStyle.gradient(color: .clear.mix(with: .black, by: 0.65), transparent: true), lineWidth: 2).shadow(radius: 2).rotationEffect(Angle(degrees: 180))))
    }
}

#Preview {
    ChatInputView(document: DoChatStudioDocument(), llm: LLM(from: "")!)
}
