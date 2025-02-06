//
//  ModelAdjustmentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/29/25.
//

import SwiftUI

fileprivate var randomTint = Color.random

struct ModelAdjustmentView: View {
    
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: LLM
    
    var body: some View {
        
        ScrollView(.vertical){
            VStack {
                if let llm = document.llm {
                    // Seed Slider
                    VStack(alignment: .leading) {
                        Text("Seed: \(llm.seed)")
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(llm.seed)
                                },
                                set: { newValue in
                                    llm.seed = UInt32(newValue)
                                    randomTint = Color.random
                                }
                            ),
                            in: 0...Double(UInt32.max),
                            //step: 1,
                            label: {
                                Text("🎲")
                            }, minimumValueLabel: {
                                Text("")
                            },
                            maximumValueLabel: {
                                Text("IOU ResetView").foregroundColor(.primary)
                            }
                        )
                        .tint(randomTint)
                    }
                    
                    Divider().overlay(Color.brown)
                    
                    VStack(alignment: .leading) {
                        Text("TopK: \(llm.topK, specifier: "%d")")
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(llm.topK)
                                },
                                set: { newValue in
                                    llm.topK = Int32(newValue)
                                }
                            ),
                            in: 1...100,
                            //step: 1,
                            label: {
                                Text("TopK")
                            },
                            minimumValueLabel: {
                                Text("🔁")
                            },
                            maximumValueLabel: {
                                Text("🎨")
                            }
                        )
                        .tint(.green)
                    }
                    
                    Divider().hidden()
                    
                    VStack(alignment: .leading) {
                        Text("TopP: \(llm.topP, specifier: "%.2f")")
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(llm.topP)
                                },
                                set: { newValue in
                                    llm.topP = Float(newValue)
                                }
                            ),
                            in: 0.0...1.0,
                            //step: 0.01,
                            label: {
                                Text("TopP")
                            },
                            minimumValueLabel: {
                                Text("📜")
                            },
                            maximumValueLabel: {
                                Text("🖌️")
                            }
                        )
                        .tint(.green)
                    }
                    
                    Divider().overlay(Color.brown)

                    VStack(alignment: .leading) {
                        Text("Temperature: \(llm.temp, specifier: "%.2f")")
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(llm.temp)
                                },
                                set: { newValue in
                                    llm.temp = Float(newValue)
                                }
                            ),
                            in: 0.0...5.0,
                            //step: 0.01,
                            label: {
                                Text("Temperature")
                            },
                            minimumValueLabel: {
                                Text("❄️")
                            },
                            maximumValueLabel: {
                                Text("🔥")
                            }
                        )
                        .tint(.blue)
                    }
                    
                    Divider().overlay(Color.brown)
                    
                    VStack(alignment: .leading) {
                        Text("History Limit: \(llm.historyLimit, specifier: "%d")")
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(llm.historyLimit)
                                },
                                set: { newValue in
                                    llm.historyLimit = Int(newValue)
                                }
                            ),
                            in: 0...100,
                            //step: 1,
                            label: {
                                Text("History Limit")
                            },
                            minimumValueLabel: {
                                Text("❓")
                            },
                            maximumValueLabel: {
                                Text("📖")
                            }
                        )
                        .tint(.brown)
                    }

                }
                Spacer()
            }
            .padding()
        }
        .background(Color.black.opacity(0.075)).cornerRadius(10)
    }
}

#Preview {
    ModelAdjustmentView(document: DoChatStudioDocument(text: "Chat"), llm: LLM(from: "")!)
}
