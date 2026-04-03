//
//  MessageMetadataView.swift
//  DoChatStudio
//
//  Created by Cosas on 9/19/25.
//

import SwiftUI

struct TimeStampView: View {
//    @Binding var style:StyleModel
    let message: Message
    
    var body: some View {
        
        HStack(spacing:0){
                Text(message.timeStampString)
            }
            .foregroundStyle(.secondary)
            .font(.system(.caption))
            .monospaced()
            .padding(2)
    }
}



#Preview {
    TimeStampView(message: Message(role: .user, content: "I have a question."))
}
