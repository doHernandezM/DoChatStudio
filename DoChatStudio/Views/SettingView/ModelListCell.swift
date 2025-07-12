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

struct ModelListCell: View {
    //    let action: (_ model:DoModel) -> Void
    @FocusState private var isUsernameFocused: Bool

    @Bindable var vm: ChatViewModel
    @State var selectedModelKey: String? = nil
    
    //    @Binding var popoverVisible: Bool = false
    @State var showModelList:Bool = false
    
    var body: some View {

        VStack {
            List(MLXService.availableModels, id: \.self, selection: $vm.selectedModel) {model in
                    ModelListView(selectedModel: Binding<DoModel?>(
                        get: {
                            model
                        },
                        set: { _ in }))
                
                    .padding(3)
                
                    .focused($isUsernameFocused)
                    
                    .onAppear{
                        isUsernameFocused.toggle()
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
                    
            }
#if os(macOS)
            .listStyle(.sidebar)
#else
            .listStyle(.plain)
#endif
        }
        //        }
        //        .buttonStyle(.plain)
        
        //        .popover(isPresented: $popoverVisible) {
        //            List(MLXService.availableModels, id: \.self, selection: $selectedModel) {model in
        //                withAnimation(.default){
        //                    ModelListView(selectedModel: Binding(get: {model}, set: {_ in} ), popoverVisible: $popoverVisible)
        //                        .onTapGesture {
        //                            popoverVisible.toggle()
        //                            selectedModel = model
        //                        }
        //                }
        //            }
        //            .listStyle(.plain)
        //        }
        //        VStack {
        //            ModelListCell(vm: vm)
        //            .padding(.top)
        //
        ////
        //            Divider().foregroundColor(.transparentAccent)
        //
        //        }
    }
    
    
}

#Preview {
    ModelListCell(vm: ChatViewModel(mlxService: MLXService()))}
