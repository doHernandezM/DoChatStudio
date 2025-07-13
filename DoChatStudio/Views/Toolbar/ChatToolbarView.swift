//
//  ChatToolbarView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import SwiftUI

/// Toolbar view for the chat interface that displays error messages, download progress,
/// generation statistics, and model selection controls.


struct ToolbarButtonsView: ToolbarContent {
    /// View model containing the chat state and controls
    @Bindable var vm: ChatModel
    
    var body: some ToolbarContent {
        ToolbarItem(id:"clearChat") {
            
            Button(action: {
                vm.clear([.chat])
            }, label: {
                VStack{
                    Image(systemName: "bubble.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.accentColor)
                        .font(.system(.title2))
                        .padding([.top,.leading,.trailing], 2)
                        .overlay(alignment: .topTrailing, content: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.white, Color.red)
                                .font(.system(.caption))
                        })
                    Text("Clear Chat")
                }
            })
       }
    }
}
