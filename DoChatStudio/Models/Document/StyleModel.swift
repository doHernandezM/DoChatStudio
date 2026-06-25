//
//  StyleModel.swift
//  DoChatStudio
//
//  Created by Cosas on 7/14/25.
//

// Stores the per-document appearance and inspector presentation preferences.

import Foundation
import SwiftUI

@Observable
class StyleModel: Codable {
    
    var showInspector: Bool = true
    
    var currentSelectedTab: Int = 1
    var showOptions: Bool = true
    
    var accent: Color {
        get {
#if os(macOS)
            return Color(interfaceColor?.platformColor ?? CodableColor(platformColor: PlatformColor.controlAccentColor).platformColor)
#else
            return Color(interfaceColor?.platformColor ?? CodableColor(platformColor: PlatformColor.systemBlue).platformColor)
#endif
        }
    }
    
//    static let sidebarMinWidth: Int = 44 * 6
//    static let sidebarMaxWidth: Int = 44 * 10
    
    var interfaceColor: CodableColor?
    var agentColor: CodableColor?
    var userColor: CodableColor?
    var backgroundColor: CodableColor?
    
    var transparentAccent: Color {
        get {
            Color(accent.platformColor).opacity(0.25)
        }
    }
    
    var showPrompt: Bool = true
    var showTimeStamp: Bool = true
    var showMetadata: Bool = true
    
    
    struct TokenView: View {
        let style: StyleModel
        
        var body: some View {
            HStack{
                Image(systemName: "dollarsign.circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, style.accent)
                    .font(.system(.largeTitle))
                    .background {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(style.transparentAccent)
                            .font(.system(.largeTitle))
                    }
                Text("Tokens")
                    .font(.system(.title3))
                    .bold()
            }
        }
    }
}
    
