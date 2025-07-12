//
//  ChatToolbarView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import SwiftUI

/// Toolbar view for the chat interface that displays error messages, download progress,
/// generation statistics, and model selection controls.
struct ToolbarSelectedModelView: View {
    /// View model containing the chat state and controls
    @Bindable var vm: ChatViewModel
    
    var body: some View {
        HStack{
            Image(systemName: vm.selectedModel != nil ? "book.circle" : "filemenu.and.selection")
                .font(.system(.largeTitle))
                .foregroundStyle(vm.selectedModel != nil ? vm.selectedModel!.folderURL.existsAsDirectory ? Color.blue : Color.pink.opacity(0.75) : Color.transparentAccent, vm.selectedModel != nil ? Color.transparentAccent : Color.white)
            
            if vm.selectedModel != nil {
                ModelListView(selectedModel: $vm.selectedModel)
            } else {
                Text("\("Choose a new model...")").font(.title3)
            }
        }
        
    }
}

struct ToolbarButtonsView: View {
    /// View model containing the chat state and controls
    @Bindable var vm: ChatViewModel
    
    var body: some View {
        HStack(alignment: .bottom){
            
            Button(action: {
                vm.clear([.gpuCache, .meta])
            }, label: {
                VStack{
                    Image(systemName: "memorychip.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.accentColor)
                        .font(.system(.title2))
                        .overlay(alignment: .topLeading, content: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white, Color.red)
                                .font(.system(.caption))
                        })
                    Text("Clear Cache")
                }
                .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
            })
            
            Button(action: {
                vm.clear([.chat])
            }, label: {
                VStack{
                    Image(systemName: "bubble.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.accentColor)
                        .font(.system(.title2))
                        .overlay(alignment: .topLeading, content: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white, Color.red)
                                .font(.system(.caption))
                        })
                    Text("Clear Chat")
                }
                .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
            })
            
            Button(action: {
                vm.clear([.gpuCache ,.chat, .meta])
            }, label: {
                VStack{
                    Image(systemName: "trash.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.accentColor)
                        .font(.system(.title2))
                        .overlay(alignment: .topLeading, content: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white, Color.red)
                                .font(.system(.caption))
                        })
                    Text("Clear All")
                }
                .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
            })
        }
        .buttonStyle(.plain)
    }
}
