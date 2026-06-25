//
//  SelectedModelView.swift
//  DoChatStudio
//
//  Created by Cosas on 9/30/25.
//

// Summarizes the active model and opens the full model selection interface.

import SwiftUI

struct SelectedModelView: View {
    /// Binding to the same ChatModel used by ChatView; changing `vm.model`
    /// changes which MLX container is loaded for the next prompt.
    @Binding var vm: ChatModel
    @State private var showingModelsSheet: Bool = false
    
    var body: some View {
        VStack {
            if vm.model == nil {
                VStack(spacing: 0) {
                    HStack{
                        Image(systemName:"text.document")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(vm.style.accent)
                            .font(.system(.largeTitle))
                        
                        Text("No Model Selected")
                            .font(.system(.title3))
                            .bold()
                        
                        Spacer()
                    }
                }
            } else {
                HStack{
                    Image(systemName:"text.document")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.style.accent)
                        .font(.system(.largeTitle))
                    
                    Text("Current Model:")
                        .font(.system(.title3))
                        .bold()
                    
                    Spacer()
                }
                .padding(4)
                ModelCellView(selectedModel: Binding<ModelModel?>(
                    get: {
                        vm.model
                    },
                    set: { _ in }), style: $vm.style)
                .padding([.leading, .trailing])
            }
            Button{
                showingModelsSheet.toggle()
            } label: {
                HStack{
                    Spacer()
                    Image(systemName: "filemenu.and.selection")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            showingModelsSheet ? Color.primary : vm.style.accent, showingModelsSheet ? vm.style.accent : Color.primary)
                    Text("Change Model")
                    Spacer()
                }
                .padding(4)
                .font(.system(.title3))
                .contentShape(
                    RoundedRectangle(cornerRadius: 5)
                )
            }
            .background(content:{
                RoundedRectangle(cornerRadius: 8 )
                    .stroke(showingModelsSheet ? vm.style.accent : Color.primary, lineWidth: 1.0)
                    .fill(showingModelsSheet ? vm.style.transparentAccent : Color.clear)
            })
            
            .buttonStyle(.plain)
#if os(macOS)
            .popover(isPresented: $showingModelsSheet) {
                ModelsListView(vm: vm)
                    .frame(minWidth: 800, minHeight: 480)
            }
            
#else
            .sheet(isPresented: $showingModelsSheet) {
                ModelsListView(vm: vm)
            }
#endif
            
            .padding()
            
        }
        .background(content: {
            RoundedRectangle(cornerRadius: 4.0)
                .fill(showingModelsSheet ? AnyShapeStyle(.clear) : AnyShapeStyle(.ultraThinMaterial))
                .stroke(showingModelsSheet ? vm.style.transparentAccent : vm.style.accent, lineWidth: 1.0)
        })
        .padding([.leading, .trailing], 4)
        
    }
}

#Preview {
    SelectedModelView(vm: .constant(ChatModel(mlxService: MLXService())))
}
