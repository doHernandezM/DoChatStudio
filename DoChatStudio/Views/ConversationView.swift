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
    let messages: [Message]
    
    var body: some View {
        ScrollView {
            if messages.count > 0 {
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
                    RoundedRectangle(cornerRadius: 8).foregroundStyle(DoStyle.gradient(color:Color.accentColor.mix(with: .transparentAccent, by: 0.5),angle: (.top,.bottom)).opacity(0.25))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .stroke(Color.transparentAccent.opacity(0.5), lineWidth: 1.0)
                    
                )
                .onHover { _ in
                    NSCursor.iBeam.push()
                }
            } else {
                EmptyView()
            }
            //            }
            
            if messages.count > 1 {
                LazyVStack(spacing: 12) {
                    ForEach(messages.dropFirst()) { message in
                        MessageView(message)
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        //        .padding(.vertical, 8)
        //        .defaultScrollAnchor(.bottom, for: .alignment)
        //        .defaultScrollAnchor(.bottom)
        
    }
}

#Preview {
    // Display sample conversation in preview
    ConversationView(messages: SampleData.conversation)
}
