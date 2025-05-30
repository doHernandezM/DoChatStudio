//
//  ModelAdjustmentView.swift
//  DoChatStudio
//
//  Created by Cosas on 1/29/25.
//

import Security
import SwiftUI

fileprivate var randomTint = Color.random

struct ModelAdjustmentView: View {
    
    @ObservedObject var document: DoChatStudioDocument
    @ObservedObject var llm: StatefulLLM
    
    var body: some View {
        VStack {
            if let llm = document.llm {
                // Seed Slider
                VStack(alignment: .leading) {
                    Text("Seed: \(llm.seed)")
                    
                    HStack {
                        Button(action: {
                            
//                            let bytesCount = 4
//                            var random: UInt32 = 0
//                            var randomBytes = [UInt8](repeating: 0, count: bytesCount)
//
//                            SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
//
//                            NSData(bytes: randomBytes, length: bytesCount)
//                              .getBytes(&random, length: bytesCount)
//                            
                            if let random = generateRandomUInt32() {
                                print("Random UInt32: \(random)")
                                
                                llm.seed = UInt32(random)
                            }
                            
                        }  ) {
                            Text("Random Seed 🎲")
                                .padding()
                        }
                        
                        Spacer()
                        
                        Toggle(isOn:
                                Binding<Bool>(
                                    get: {
                                        Bool(document.resetSeedAfterResponse)
                                    },
                                    set: { newValue in
                                        document.resetSeedAfterResponse = newValue
                                    }
                                ) ){
                                    Text("Reset Seed After Each Response")
                                }
                        
                        Spacer()
                    }
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
}

#Preview {
    ModelAdjustmentView(document: DoChatStudioDocument(text: "Chat"), llm: StatefulLLM(from: "")!)
}

func generateRandomUInt32() -> UInt32? {
    var randomNumber: UInt32 = 0
    let result = withUnsafeMutableBytes(of: &randomNumber) { ptr in
        SecRandomCopyBytes(kSecRandomDefault, ptr.count, ptr.baseAddress!)
    }
    
    return result == errSecSuccess ? randomNumber : nil
}
