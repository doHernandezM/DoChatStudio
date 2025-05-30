//
//  ModelInfoView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI


struct ModelInfoView: View {
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: StatefulLLM
    
    
    var body: some View {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("Name: \("llm.modelName" )")
                }
                VStack(alignment: .leading) {
                    Text("Author: \("llm.modelAuthor")")
                }
                VStack(alignment: .leading) {
                    Text("Architecture: \("document.llm?.modelArchitecture ?? ")")
                }
                VStack(alignment: .leading) {
                    Text("Path: \("document.url?.absoluteString ?? ")")
                }
//                VStack(alignment: .leading) {
//                    Text("hparams: \(llm.systemInfo())")
//                }
                Spacer()
            }
            .padding()

    }
}

#Preview {
    ModelInfoView(document: DoChatStudioDocument(text: "Chat"), llm: StatefulLLM(from: "")!)
}
