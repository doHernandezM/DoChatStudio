//
//  ConversationView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import SwiftUI

/// Displays the chat conversation as a scrollable list of messages.
struct ConversationView: View {
    /// Array of messages to display in the conversation
    @Binding var style:StyleModel
    let messages: [Message]
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(pinnedViews: [.sectionHeaders]){
                Section() {
                    if messages.count > 1 {
                        LazyVStack(spacing: 12) {
                            ForEach(messages.dropFirst()) { message in
                                MessageView(style: $style, message: message)
                                    .padding(.horizontal, 12)
                            }
                            Spacer()
                        }
                    } else {
                        EmptyView()
                    }
                } header : {
                    VStack {
                        VStack {
                            if messages.count > 0 && style.showPrompt {
                                TextField(messages[0].content,
                                          text: Binding<String>(
                                            get:{
                                                return messages[0].content
                                            },
                                            set:{prompt in
                                                messages[0].content = prompt
                                            }),
                                          axis: .vertical)
                                .textFieldStyle(.plain)
                                .onKeyPress(keys: [.return]) { event in
                                    if event.modifiers == .shift {
                                        messages[0].content += "\n"
                                        return .handled
                                    }
                                    return .ignored
                                }
                                
                                .padding(8)
                                .monospaced()
                                .font(.title3)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(
                                    RoundedRectangle(cornerRadius: 8).foregroundStyle(DoStyle.gradient(color:Color(style.agentColor?.platformColor ?? style.accent.platformColor),angle: (.top,.bottom)).opacity(0.35))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.clear)
                                        .stroke(Color(style.agentColor?.platformColor ?? style.accent.platformColor).opacity(0.5), lineWidth: 1.0)
                                )
#if os(macOS)
                                .onContinuousHover { phase in
                                    switch phase {
                                    case .active:
                                        NSCursor.iBeam.push()
                                    case .ended:
                                        NSCursor.arrow.push()
                                    }
                                }
#endif
                                .background(content:{
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                })
                        } else {
                            EmptyView()
                        }
                    }
                    .padding()
                    .background(content:{
                        RoundedRectangle(cornerRadius: 9)
                            .fill(.ultraThinMaterial)
                            .mask(LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom))
                    })
                }
            }
        }
    }
        .defaultScrollAnchor(.bottom)
}
}

#Preview {
    // Display sample conversation in preview
    ConversationView(style: .constant(StyleModel()), messages: SampleData.conversation)
}
