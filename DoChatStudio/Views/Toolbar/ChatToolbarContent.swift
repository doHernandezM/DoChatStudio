//
//  ChatToolbarView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import SwiftUI
import StoreKit

/// Toolbar view for the chat interface that displays error messages, download progress,
/// generation statistics, and model selection controls.


//@ToolbarContentBuilder
//func ToolbarButtonsView(model: ChatModel) -> some ToolbarContent {
//    let style = model.style
//    @EnvironmentObject var purchaseManager: PurchaseManager
//    
//    @State var preferredColumn = NavigationSplitViewColumn.detail
//    
//    ToolbarItem(placement: .automatic) {
//        Button {
//            preferredColumn = (preferredColumn == .sidebar) ? .detail : .sidebar
//        } label: {
//            Label("Toggle Sidebar", systemImage: "sidebar.leading")
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(Color(style.accent.platformColor))
//        }
//        .buttonStyle(.plain)
//        .padding()
//    }
//    
//    // Restore purchases at the top bar trailing
//    ToolbarItem(placement: .automatic) {
//        Button{
//            Task {
//                await purchaseManager.restorePurchases()
//            }
//        } label: {
//            Label("Clear Char", systemImage: "arrow.trianglehead.counterclockwise")
//                .symbolRenderingMode(.palette)
//            //                    .foregroundStyle(Color(style.accent.platformColor))
//        }
//        //             .padding()
//    }
//    
//    // Clear chat at the top bar trailing
//    ToolbarItem(placement: .automatic) {
//        Button{
//            model.clear([.chat])
//        } label: {
//            Label("Clear Char", image: "custom.bubble.badge.minus")
//                .symbolRenderingMode(.palette)
//                .foregroundStyle(Color.red, Color(style.accent.platformColor))
//        }
//        //            .padding()
//    }
//    
//}

struct ChatToolbarContent: ToolbarContent {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    let model: ChatModel


    var body: some ToolbarContent {
        ToolbarItem() {
            Button {
                model.clear([.meta])
            } label: {
                Label("Clear Metadata", systemImage: "chart.xyaxis.line")
                    .font(.system(.title3))
                    .foregroundStyle(model.style.accent)
                    .symbolRenderingMode(.palette)
                    .background(
                        Image(systemName: "squareshape.fill")
                            .font(.system(.title3))
                            .fontWeight(.heavy)
                            .foregroundStyle(.secondary)
                        )
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "delete.left.fill")
                            .font(.system(.caption2))
                            .foregroundStyle(.red)
//                            .background(
//                                Image(systemName: "circle.fill")
//                                .foregroundStyle(.secondary))
                    }
            }
        }

        ToolbarItem() {
            Button {
                model.clear([.chat])
            } label: {
                    Label("Clear Chat", systemImage: "bubble.left.fill")
                        .font(.system(.title3))
                        .foregroundStyle(model.style.transparentAccent)
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "trash.fill")
                                .font(.system(.caption2))
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                }
            }
        }
        
        ToolbarItem() {
            Button {
                model.style.showInspector.toggle()
            } label: {
                Label("Toggle Sidebar", systemImage: "sidebar.trailing")
                    .font(.system(.title3))
                    .foregroundStyle(model.style.accent)
            }
        }
    }
}
