//
//  ModelListView.swift
//  ModelMule
//
//  Created by Cosas on 6/29/25.
//

import MLX
import MLXLMCommon
import MLXLLM

import SwiftUI

struct ModelListView: View {
    
    
    @Binding var selectedModel:DoModel?
    @State var showTrash: Bool = false
   

    var body: some View {
        
        HStack{
            
            VStack{
                
                HStack{
                    Text(selectedModel != nil ? "\(selectedModel!.displayName)" : "Choose a new model...").font(.title3)
                    Spacer()
                }
                HStack{
                    if selectedModel?.size ?? 0 > 0 {
                        Text("\(selectedModel?.sizeString ?? " ")")
                    } else {
                        Text("--")
                    }
                    if selectedModel != nil {
                        
                        if selectedModel!.modelDownloadProgress == nil {
                            Spacer()
                        } else {
                            ProgressView(value: selectedModel!.modelDownloadProgress!.fractionCompleted)
                            Text("\(selectedModel!.modelDownloadProgress!.fractionCompleted,  specifier: "%.2f")%")
                        }
                    }
                }.font(.caption).monospaced()
            }
            
            if selectedModel != nil {
                
                HStack{
                    Button(action: {
                        
                        withAnimation(.easeIn(duration: 0.1)){
                            
                            if selectedModel!.downloadTask != nil {
                                selectedModel!.cancelDownload()
                                selectedModel!.deleteModel()
                            } else {
                                
                                
                                
                                Task { @MainActor in
                                    
                                    
                                    do {
                                        try await selectedModel!.downloadModel(model: selectedModel!)
                                    } catch {
                                        print("Downloady error")
                                    }
                                }
                            }
                        }
                    } ) {
                        let isDownloading  = selectedModel!.modelDownloadProgress != nil
                        let isFinishedDownloading  = selectedModel!.finishedSize != 0
                        let downloadSymbolString:String = "arrow.down.circle"
                        Image(systemName: downloadSymbolString)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(isDownloading ? Color.red : isFinishedDownloading ? Color.green : Color.blue, isDownloading ? .red : Color.transparentAccent)
                            .font(.system(.title))
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 0) {
                        if (selectedModel!.size > 0 || selectedModel!.modelDownloadProgress != nil) {
                            if showTrash {
                                Button(action: {
                                    selectedModel!.deleteModel()
                                } ) {
                                    Image(systemName: "trash.circle")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.red, Color.transparentAccent)
                                        .font(.system(.title))
                                }
                                .buttonStyle(.plain)
                                .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area

                            }
                            
                            Button(action: {
                                Task { @MainActor in
                                    withAnimation(.easeIn(duration: 0.1)) {
                                        showTrash = !showTrash
                                    }
                                }
                            } ) {
                                Image(systemName: "xmark.circle")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(showTrash ? .red.mix(with: .orange, by: 0.75) : Color.red, Color.transparentAccent)
                                    .font(.system(.title))
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area

                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        
    }
}

#Preview {
    ModelListView(selectedModel: .constant(DoModel(name: "llama3.2:1b", configuration: LLMRegistry.llama3_2_1B_4bit, type: .llm)))
}
