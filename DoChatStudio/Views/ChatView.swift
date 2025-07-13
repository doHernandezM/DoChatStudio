//
//  ChatView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

import AVFoundation
import AVKit
import SwiftUI

/// Main chat interface view that manages the conversation UI and user interactions.
/// Displays messages, handles media attachments, and provides input controls.
struct ChatView: View {
    /// View model that manages the chat state and business logic
    @Bindable private var vm: ChatModel
    
    /// Initializes the chat view with a view model
    /// - Parameter viewModel: The view model to manage chat state
    init(viewModel: ChatModel) {
        self.vm = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Display conversation history
                ConversationView(messages: vm.messages)
                
                Divider()
                
                // Show media previews if attachments are present
                if !vm.mediaSelection.isEmpty {
                    MediaPreviewsView(mediaSelection: vm.mediaSelection)
                }
                
                // Input field with send and media attachment buttons
                
                PromptField(
                    prompt: $vm.prompt, 
                    sendButtonAction: {
                        await vm.generate()
                    },
                    // Only show media button for vision-capable models
                    mediaButtonAction: vm.model?.isVisionModel ?? false
                    ? {
                        vm.mediaSelection.isShowing = true
                    } : nil
                )
                .padding()
//                .ignoresSafeArea(.container)
            }
//        }
        
//        .formStyle(.automatic)
//        .defaultScrollAnchor(.bottom)

        // Handle media file selection
        .fileImporter(
            isPresented: $vm.mediaSelection.isShowing,
            allowedContentTypes: [.image, .movie],
            onCompletion: vm.addMedia
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.tint.opacity(0.1), lineWidth: 1)
        )
        
    }
}

#Preview {
    ChatView(viewModel: ChatModel(mlxService: MLXService()))
}


extension Color {
    static var transparentAccent: Color {
        Color.accentColor.opacity(0.25)
    }
}
