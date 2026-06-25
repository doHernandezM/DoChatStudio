//
//  ModelListView.swift
//  ModelMule
//
//  Created by Cosas on 6/29/25.
//

// Displays model status, size, download progress, cancellation, and deletion actions.

import MLX
import MLXLMCommon
import MLXLLM

import SwiftUI

struct ModelCellView: View {
    
    
    @Binding var selectedModel:ModelModel?
    @Binding var style:StyleModel
    @State var showTrash: Bool = false
    
    
    var body: some View {
        
        if let model = selectedModel {
            
            HStack{
                deleteButton(model: model)
                
                VStack(alignment: .leading){
                    
                    HStack{
                        Text("\(model.displayName)" )
                            .foregroundStyle(.primary)
                            .truncationMode(.middle)
                            .fixedSize(horizontal: false, vertical: false)
                            .font(.title3)
                    }
                    HStack{
                        if model.size > 0 {
                            Text("\(model.sizeString)")
                                .font(.caption).monospaced()
                                .foregroundStyle(Color.secondary)
                        } else {
                            Text("--")
                                .font(.caption).monospaced()
                                .foregroundStyle(Color.secondary)
                        }
                        
                        if model.modelDownloadProgress != nil {
                            ProgressView(value: model.modelDownloadProgress!.fractionCompleted)
                                .progressViewStyle(BarProgressStyle(barColor: style.accent, backgroundColor: style.transparentAccent))
                        } else {
                            if model.isCustomModel {
                                Text("Custom Model")
                                    .font(.caption).monospaced()
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                }
                Spacer()
                
            }
        } else {
            HStack{
                Image(systemName: "filemenu.and.selection")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(style.accent, Color.primary)
                    .font(.system(.title))
                
                Text("Choose a model...")
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: false)
                    .font(.title3)
            }
            .padding([.top, .bottom])
        }
    }
    
    func downloadButton(model: ModelModel) -> some View {
        Button(action: {
            
            withAnimation(.easeIn(duration: 0.1)){
                
                if model.downloadTask != nil {
                    model.cancelDownload()
                    model.deleteModel()
                    showTrash = false
                } else {
                    Task { @MainActor in
                        do {
                            try await model.downloadModel(model: model)
                        } catch {
                            print("Downloady error:\n----------\n\(model.localURL?.absoluteString ?? "nil localURL")\n\(model.folderURL.absoluteString)\n")
                            print(error)
                        }
                    }
                }
                
            }
        } ) {
            let isDownloading  = model.modelDownloadProgress != nil
            let isFinishedDownloading  = model.finishedSize != 0
            let downloadSymbolString:String = "arrow.down.circle"
            let downloadButtonColor = isDownloading ? style.accent : isFinishedDownloading ? Color.green : Color.blue
            Image(systemName: downloadSymbolString, variableValue: model.modelDownloadProgress?.fractionCompleted ?? 100)
                .symbolVariableValueMode(.draw)
                .symbolRenderingMode(.palette)
                .foregroundStyle(downloadButtonColor, isDownloading ? style.accent : style.transparentAccent)
                .font(.system(.largeTitle))
        }
        .buttonStyle(.plain)
        
    }
    
    func deleteButton(model: ModelModel) -> some View {
        VStack{
            HStack(spacing: 0) {
                if (model.size > 0 || model.modelDownloadProgress != nil) {
                    
                    Button(action: {
                        Task { @MainActor in
                            withAnimation(.easeIn(duration: 0.1)) {
                                showTrash = !showTrash
                                if model.downloadTask != nil {
                                    model.cancelDownload()
                                    model.deleteModel()
                                    showTrash = false
                                }
                            }
                        }
                    } ) {
                        ZStack{
                            if model.downloadTask == nil {
                                Image(systemName: showTrash ? "xmark.circle" : "trash.circle")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(showTrash ? .green.mix(with: .yellow, by: 0.25) : .yellow.mix(with: .orange, by: 0.75), style.transparentAccent)
                                    .font(.system(.largeTitle))
                            } else {
                                Image(systemName: "arrow.down")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.blue)
                                    .font(.system(.title3))
                                    .fontWeight(.bold)
                                Image(systemName: "nosign")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.red)
                                    .font(.system(.largeTitle))
                                //                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
                    .help(model.modelDownloadProgress != nil ? "Stop Download" : showTrash ? "Hide Delete Options" : "Show Delete Options")
                    
                    if showTrash {
                        HStack{
                            Button(action: {
                                model.deleteModel()
                                showTrash = false
                            } ) {
                                Image(systemName: "folder.badge.minus")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.red, style.accent)
                                    .font(.system(.headline))
                            }
                            .buttonStyle(.plain)
                            .padding()
                            .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
                            .help("Delete Model Folder")

                            if model.isCustomModel {
                                Divider().foregroundStyle(.red.opacity(0.7))
                                
                                Button(action: {
                                    MLXService.shared.removeCustomModel(model)
                                    showTrash = false
                                } ) {
                                    Image(systemName: "document.on.trash")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.red, style.accent)
                                        .font(.system(.headline))
                                }
                                
                                .buttonStyle(.plain)
                                .padding()
                                .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
                                .help("Remove Model From Model List")
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.7))
                            .fill(Color.red.opacity(0.1))
                        )
                        .padding([.leading])
                        
                    }
                } else {
                    downloadButton(model: model)
                }
            }
            .buttonStyle(.plain)
        }
        
    }
}


#Preview {
    ModelCellView(selectedModel: .constant(ModelModel(name: "llama3.2:1b", configuration: LLMRegistry.llama3_2_1B_4bit, type: .llm)), style: .constant(StyleModel()))
}

struct BarProgressStyle: ProgressViewStyle {
    
    var barColor: Color
    var backgroundColor: Color
    var labelFontStyle: Font = .caption
    
    func makeBody(configuration: Configuration) -> some View {
        
        let progress = configuration.fractionCompleted ?? 0.0
        
        GeometryReader { geometry in
            
            ZStack {
                
                HStack{
                    Capsule()
                        .fill(backgroundColor)
                        .frame(width: geometry.size.width)
                    Spacer()
                }
                HStack{
                    
                    Capsule()
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress)
                    Spacer()
                }
                    HStack{
                        Text(String(format: "%.0f%%", (progress * 100).rounded(.up)))
                            .padding([.leading])
                        Spacer()
                }
            }
        }
    }
}
