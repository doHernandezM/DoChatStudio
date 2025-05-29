//  ModelConfigView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI


struct ModelConfigView: View {
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: LLM
    
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        ScrollView(.vertical){
            SelectModelView(document: document)
            
            Divider()
           
            ModelInfoView(document: document, llm: llm)
            
            Divider()
           
            ModelAdjustmentView(document: document, llm: llm)
        }
//        .background(Color.black.opacity(0.075)).cornerRadius(10)
//        .background(.black.opacity(0.075))
        .background(colorScheme == .dark ? .brown.opacity(0.25) : .brown.opacity(0.25) )
        .blendMode(.normal/*.luminosity*/)
        .cornerRadius(10.0)

    }
}

#Preview {
    ModelConfigView(document: DoChatStudioDocument(text: "Chat"), llm: LLM(from: "")!)
}
