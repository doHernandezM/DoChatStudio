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
//    @Environment(\.dismiss) private var dismiss
//    
    @Bindable var vm: ChatModel
    @State var optionKeyPressed = false
    
    @State private var modelCardState: ModelCardState = .hidden
    @State private var fetchTask: Task<Void, Never>? = nil
    
    var body: some View {
        
        VStack {
            HStack{
                Image(systemName:"text.document")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(vm.style.accent)
                    .font(.system(.largeTitle))
                
                Text("Models:")
                    .font(.system(.title2))
                    .bold()
                
                Spacer()
            }
            .padding([.top, .leading])
            
            ModelAddView(vm: vm)
                .padding([.leading, .trailing])
            
            
            HStack {
                VStack {
                    ModelCardView(modelName: Binding<String?>(
                        get:{
                            return vm.model?.name
                        },
                        set:{_ in
                        }), modelCardState: $modelCardState, fetchTask: $fetchTask, style: vm.style)
                    Spacer()
                }
                .padding(2)
                .onChange(of: vm.model) { oldValue, newValue in
                    fetchTask?.cancel()
                    guard let modelName = newValue?.configuration.name else {
                        modelCardState = .hidden
                        return
                    }
                    
                    modelCardState = .loading
                    fetchTask = Task { @MainActor in
                        do {
                            let markdown = try await
                            ModelModel.hub.fetchModelCardMarkdown(repoId: modelName)
                            modelCardState = .loaded(markdown ?? "")
                        } catch {
                            modelCardState = .failed(error)
                        }
                    }
                }
                .onAppear() {
                    fetchTask?.cancel()
                    
                    modelCardState = .loading
                    
                    fetchTask = Task { @MainActor in
                        
                        do {
                            if let modelName = self.vm.model?.configuration.name {
                                let markdown = try await
                                ModelModel.hub.fetchModelCardMarkdown(repoId: modelName)
                                modelCardState = .loaded(markdown ?? "")
                            } else {
                                modelCardState = .hidden
                            }
                        } catch {
                            modelCardState = .failed(error)
                        }
                    }
                }
                
                Divider().foregroundStyle(vm.style.accent)
                
                VStack {
                    ModelList(vm: vm)
                }
            }
            .padding([.leading, .trailing])
        }
        
        
    }
}

#Preview {
    ModelsListView(vm: ChatModel(mlxService: MLXService()))
}

struct ModelList: View {
    
    @Bindable var vm: ChatModel
    @State var optionKeyPressed = false
    
    
    var body: some View {
        ScrollView(.vertical, content: {
            ForEach(MLXService.shared.allModels, id: \.self) { model in
                
                ModelCellView(
                    selectedModel: .constant(Optional(model)),
                    style: $vm.style
                )
                .tag(model)
                .padding(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(model == vm.model ? vm.style.accent : Color.clear, lineWidth: 1)
                )
                .background(model == vm.model ? vm.style.transparentAccent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    if vm.model != nil && optionKeyPressed {
                        vm.model = nil
                    } else {
                        vm.model = model
                        vm.style.currentSelectedTab = 1
                    }
                    //                            dismiss()
                }
#if os(macOS)
                .onModifierKeysChanged({ old, new in
                    optionKeyPressed = new == .option ? true : false
                })
#endif
                Divider().foregroundStyle(vm.style.transparentAccent)
                
            }
        })
    }
}
