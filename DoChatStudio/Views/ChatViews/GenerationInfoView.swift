//
//  GenerationInfoView.swift
//  DoChatStudio
//
//  Created by Cosas on 10/1/25.
//

// Displays generation state, timing, token counts, and throughput for a message.

import SwiftUI

struct GenerationInfoView: View {
    
    @Binding var style:StyleModel
    let message: Message
    
    @State private var formattedPromptTime: String = ""
    @State private var formattedGenerationTime: String = ""

    private func updateFormattedTimes() {
        if let info = message.generationInfo {
            // Cache the string formatting to avoid recomputation on every redraw
            formattedPromptTime = "\(info.promptGenerationTime)"
            formattedGenerationTime = "\(info.generationTime)"
        } else {
            formattedPromptTime = ""
            formattedGenerationTime = ""
        }
    }
    
    var state: ModelState? {
        get {
            return message.modelState
        }
    }
    
    var body: some View {
        if style.showMetadata {
            if message.generationInfo != nil {
                VStack(){
                    VStack(spacing: 0){
                        Text("Token Usage")
                            .font(.system(.title3))
                            .bold()
                        
                        Grid(alignment:.leading, horizontalSpacing:0, verticalSpacing:0, content: {
                            GridRow{
                                Text("Prompt")
                                Spacer()
                                Text("Response")
                            }
                            .fontWeight(.heavy)
                            
                            Divider().foregroundStyle(style.accent)
                            
                            GridRow{
                                Text("Total Tokens")
                            }
                            .fontWeight(.bold)
                            
                            GridRow{
                                Text("\(message.generationInfo!.promptTokenCount)")
                                Spacer()
                                Text("\(message.generationInfo!.generationTokenCount)")
                            }
                            .fontDesign(.monospaced)
                            
                            Divider().foregroundStyle(style.transparentAccent)
                                .padding(4)
                            
                            GridRow{
                                Text("Tokens per Second")
                            }
                            .fontWeight(.bold)
                            
                            GridRow{
                                Text("\(message.generationInfo!.promptTokensPerSecond)")
                                Spacer()
                                Text("\(message.generationInfo!.tokensPerSecond)")
                            }
                            .fontDesign(.monospaced)
                            
                            Divider().foregroundStyle(style.transparentAccent)
                                .padding(4)
                            
                            GridRow{
                                Text("Total Time")
                            }
                            .fontWeight(.bold)
                            
                            GridRow{
                                Text(formattedPromptTime)
                                Spacer()
                                Text(formattedGenerationTime)
                            }
                            .fontDesign(.monospaced)
                            
                        })
                        .padding(4)
                    }
                }
                .foregroundStyle(.secondary)
                .onAppear { updateFormattedTimes() }
                .onChange(of: message.generationInfo?.promptGenerationTime) { _ in updateFormattedTimes() }
                .onChange(of: message.generationInfo?.generationTime) { _ in updateFormattedTimes() }
            } else if message.generationInfo == nil && state == nil {
                EmptyView()
            } else if message.generationInfo != nil && state != nil {
                VStack{
                    Text("\(state!.rawValue.capitalized(with: .current))")
                        .font(.system(.title3))
                        .bold()
                        .padding(4)
                        .foregroundStyle(.secondary)
                }
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    GenerationInfoView(style: .constant(StyleModel()), message: Message(role: .user, content: ""))
}
