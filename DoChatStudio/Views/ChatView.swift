//  Chat.swift
//  DoChatStudio
//
//  Created by Cosas on 1/30/25.
//

import SwiftUI

struct ChatView: View {
    let chat: Chat
    
    var body: some View {
        let chatBackgroundColor = chat.role == .user ?  customGradient(Color.blue.opacity(0.2)) : chat.ignored ? customGradient(Color.orange.opacity(0.125)) : customGradient(Color.green.opacity(0.2))

        HStack{
            if chat.role == .user {Spacer(minLength: 25)}
            VStack(alignment: .leading) {
                Text(chat.content).monospaced().padding()
                
                
                HStack{
                    Text(chat.tokens == 0 ? "" : ("Tokens:" + String(chat.tokens))).monospaced()
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
    ChatView(chat: Chat(role: .bot, content: "Hello!"))
}

func customGradient(_ color: Color = .gray) -> LinearGradient{
    let lightColor: Color = color//.mix(with: .white, by: 0.05)
    let darkColor: Color = color.mix(with: .gray, by: 0.1)
    
    return LinearGradient(colors: [lightColor, darkColor], startPoint: .topLeading, endPoint: .bottomLeading)
}
