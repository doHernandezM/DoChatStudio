//
//  ModelAddView.swift
//  DoChatStudio
//
//  Created by Cosas on 9/22/25.
//

// Validates and adds custom MLX Community LLM or VLM repositories to the model catalog.

import SwiftUI

struct ModelAddView: View {
    @Bindable var vm: ChatModel
    
    @State private var newIdOrURL = ""
    @State private var newType: ModelModel.ModelType = .llm
    
    var body: some View {
        
        HStack() {
            Image(systemName: "document.badge.plus.fill")
                .font(.system(.title3))
                .bold()
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.blue, vm.style.accent)
                .padding([.leading])
            Text("Add a model")
                .font(.system(.title3))
                .bold()
            TextField("", text: $newIdOrURL, prompt: Text("mlx-community/Foo-7B-4bit"))
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .onSubmit {addModel()}
                .padding([.leading, .trailing])
                .tint(vm.style.accent)
            Picker("Type", selection: $newType) {
                Text("LLM").tag(ModelModel.ModelType.llm)
                Text("VLM").tag(ModelModel.ModelType.vlm)
            }
            .tint(vm.style.accent)
            .pickerStyle(.segmented)
            
            Spacer()
            Button(action: {addModel()}, label: {
                Image(systemName: "plus")
                    .bold()
            })
            .tint(vm.style.accent)
            .padding([.top, .trailing])
            .buttonStyle(.borderedProminent)
            .disabled(!isValidMLXCommunityIdentifier(newIdOrURL))
            .padding([.bottom])
        }
        .background(
            RoundedRectangle(cornerRadius: 10).stroke(vm.style.accent, lineWidth: 1.0)
            //.background(vm.style.transparentAccent, in: RoundedRectangle(cornerRadius: 8))
        )
    }
    
    func addModel() {
        guard !newIdOrURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        //        print("Custom Models Count: \(MLXService.shared.customModels.count)")
        //        print("All Models Count: \(MLXService.shared.allModels.count)")
        if newIdOrURL.hasSuffix("/") {
            newIdOrURL.removeLast()
        }
        
        Task {
            if let model = await ModelModel.makeCustomModel(from: newIdOrURL, type: newType) {
                // Depending on how your list is sourced, append to MLXService or your VM.
                // If MLXService.allModels is mutable:
                MLXService.shared.customModels.append(model)
                vm.model = model
                newIdOrURL = ""
            }
            //            print("Custom Models Count II: \(MLXService.shared.customModels.count)")
            //            print("All Models Count II: \(MLXService.shared.allModels.count)")
            //            print("localURL: \(model.localURL?.absoluteString)")
            //            print("folderURL: \(model.folderURL.absoluteString)")
        }
    }
    
    private func isValidMLXCommunityIdentifier(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Accept either a short id or a full HF URL
        // 1) Full URL form
        if let url = URL(string: trimmed.lowercased()),
           let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let host = comps.host, host == "huggingface.co" {
            // Path components: e.g. "/mlx-community/Foo-7B-4bit"
            // First real component should be "mlx-community"
            let parts = url.path.split(separator: "/")
            guard parts.count >= 2 else { return false }
            return parts[0] == "mlx-community"
        }
        
        // 2) Short form: "mlx-community/ModelName"
        let lower = trimmed.lowercased()
        if lower.hasPrefix("mlx-community/") {
            // Ensure there is a model name after the prefix
            let remainder = trimmed.dropFirst("mlx-community/".count)
            return !remainder.isEmpty && !remainder.hasPrefix("/")
        }
        
        return false
    }
    
}

#Preview {
    ModelAddView(vm: ChatModel(mlxService: MLXService()))
}
