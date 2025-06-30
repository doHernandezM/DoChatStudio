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
                Text(messages[0].content)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 5).foregroundColor(.accentColor)
                    )
                    .font(.headline).monospaced()
                    
            } else {
                EmptyView()
            }
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageView(message)
                        .padding(.horizontal, 12)
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
