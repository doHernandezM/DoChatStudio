//
//  ChatView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 20.04.2025.
//

// Composes the conversation, attachment previews, prompt controls, importer, and chat toolbar.

import AVFoundation
import AVKit
import SwiftUI

/// Main chat interface view that manages the conversation UI and user interactions.
/// Displays messages, handles media attachments, and provides input controls.
struct ChatView: View {
    /// The shared document model observed by the conversation, prompt, toolbar,
    /// model picker, and generation status UI.
    @Bindable private var vm: ChatModel
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    /// Initializes the chat view with a view model
    /// - Parameter viewModel: The view model to manage chat state
    init(viewModel: ChatModel) {
        self.vm = viewModel
    }
    
    /// Binds visible controls to the state that `ChatModel` sends to MLX.
    var body: some View {
        VStack(spacing: 0) {
            // Display conversation history
            ConversationView(style: $vm.style, messages: vm.messages)
            
            Divider().foregroundStyle(vm.style.transparentAccent)
            
            // Show media previews if attachments are present
            if !vm.mediaSelection.isEmpty {
                MediaPreviewsView(mediaSelection: vm.mediaSelection)
            }
            
            // Input field with send and media attachment buttons
            Group {
                PromptField(
                    style: $vm.style, prompt: $vm.prompt,
                    sendButtonAction: {
                        // This closure is the UI boundary into the inference pipeline.
                        await vm.generate()
                    },
                    // Only show media button for vision-capable models
                    mediaButtonAction: vm.model?.isVisionModel ?? false
                    ? {
                        vm.mediaSelection.isShowing = true
                    } : nil
                )
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(vm.style.backgroundColor?.color ?? vm.style.transparentAccent, lineWidth: 1)
                .fill(vm.style.backgroundColor?.color.opacity(0.9) ?? .clear)
                
        )
        .fileImporter(
            isPresented: $vm.mediaSelection.isShowing,
            allowedContentTypes: [.image, .movie],
            // Imported URLs become UserInput image/video values in MLXService.
            onCompletion: vm.addMedia
        )
        .toolbar {
            ChatToolbarContent(model: vm)
        }
        
    }
}

#Preview {
    ChatView(viewModel: ChatModel(mlxService: MLXService()))
}
