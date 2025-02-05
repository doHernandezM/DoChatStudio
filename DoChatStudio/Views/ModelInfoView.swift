//
//  ModelInfoView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/28/25.
//

import SwiftUI


struct ModelInfoView: View {
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: LLM
    
    
    var body: some View {
        ScrollView(.vertical){
            VStack(alignment: .leading) {
                SelectModelView(document: document)
                
                VStack(alignment: .leading) {
                    Text("Name: \(llm.modelName )")
                }
                VStack(alignment: .leading) {
                    Text("Author: \(llm.modelAuthor)")
                }
                VStack(alignment: .leading) {
                    Text("Architecture: \(document.llm?.modelArchitecture ?? "")")
                }
                VStack(alignment: .leading) {
                    Text("Path: \(document.url?.absoluteString ?? "")")
                }
                VStack(alignment: .leading) {
                    Text("hparams: \(llm.systemInfo())")
                }
                Spacer()
            }
            .padding()
        }
        .background(.black.opacity(0.075))
        .cornerRadius(10.0)

    }
}

#Preview {
    ModelInfoView(document: DoChatStudioDocument(), llm: LLM(from: "")!)
}
