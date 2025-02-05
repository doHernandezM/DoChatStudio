//  Chat.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI

struct ChatBubbleView: View {
    let chat: Chat
    
    var body: some View {
        let chatBackgroundColor = chat.role == .user ?  customGradient(Color.blue.opacity(0.2)) : chat.ignored ? customGradient(Color.orange.opacity(0.125)) : customGradient(Color.green.opacity(0.2))

        HStack{
            if chat.role == .user {Spacer(minLength: 25)}
            VStack(alignment: .leading) {
                if chat.content.count > 0 {
                    Text(chat.content).padding()
                }
                
                HStack{
                    if let llmState = chat.llmState {
                        switch llmState {
                        case .preparing, .thinking, .generating, .finishing, .stopped, .paused, .error:
                            Text(llmState.rawValue).monospaced()
                                .padding()
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(chatBackgroundColor)
                    .overlay(RoundedRectangle(cornerRadius: 8).fill(Color.clear).strokeBorder(chatBackgroundColor, lineWidth: 5).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
            )
            if chat.role == .bot {Spacer(minLength: 25)}
        }
    }
}

#Preview {
    ChatBubbleView(chat: Chat(role: .bot, content: "Hello!"))
}

func customGradient(_ color: Color = .gray) -> LinearGradient{
    let lightColor: Color = color//.mix(with: .white, by: 0.05)
    let darkColor: Color = color.mix(with: .gray, by: 0.1)
    
    return LinearGradient(colors: [lightColor, darkColor], startPoint: .topLeading, endPoint: .bottomLeading)
}


// A view to represent a single color swatch
struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                // Adding a subtle border to distinguish light colors
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding()
    }
}

