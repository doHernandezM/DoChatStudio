//
//  ModelListView.swift
//  ModelMule
//
//  Created by Cosas on 6/28/25.
//

import MLX
import MLXLMCommon
import MLXLLM

import SwiftUI

struct ModelsListView: View {
    
    @Bindable var vm: ChatModel
    
    var body: some View {
        
        VStack {
            //            ScrollView() {
            ForEach(MLXService.availableModels, id: \.self) { model in
                
                ModelListView(selectedModel: Binding<DoModel?>(
                    get: {
                        model
                    },
                    set: { _ in }))
                .tag(model)
                .padding(3)
                .background(model == vm.model ? Color.transparentAccent : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
                .onTapGesture {
                    vm.model = model
                }
            }
        }
        .padding()
    }
}
//}
//            .padding()
//#if os(macOS)
//            .listStyle(.plain)
//#else
//            .listStyle(.plain)
//#endif
//}
//}
//
//
//}

#Preview {
    ModelsListView(vm: ChatModel(mlxService: MLXService()))
}
