//
//  ChatToolbarView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import SwiftUI

/// Toolbar view for the chat interface that displays error messages, download progress,
/// generation statistics, and model selection controls.
struct ChatToolbarView: View {
    /// View model containing the chat state and controls
    @Bindable var vm: ChatViewModel

    var body: some View {
        
        // Button to clear chat history
        Button("Clear", systemImage: "square.and.arrow.up") {
            {vm.clear([.chat, .meta])}()
        }
    }
}
