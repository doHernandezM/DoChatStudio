//
//  ChatAdjustmentView.swift
//  DoChatStudio
//
//  Created by Cosas on 6/19/25.
//

import SwiftUI
import Charts

struct ChatAdjustmentView: View {
    /// View model that manages the chat state and business logic
    @Bindable private var vm: ChatViewModel
    
    /// Initializes the chat view with a view model
    /// - Parameter viewModel: The view model to manage chat state
    init(viewModel: ChatViewModel) {
        self.vm = viewModel
    }
    
    

    var body: some View {
        VStack {
            
            ScrollView(.vertical, content: {
                VStack{
                    //Max Tokens
                    
                    DisclosureGroup(content:{
                        Toggle(isOn: Binding<Bool>(
                            get:{vm.generateParameters.maxTokens == nil},
                            set: { newValue in
                                vm.generateParameters.maxTokens = newValue ? nil : 200
                            }
                        )
                        ) {
                            Label{Text("Use Unlimited Token")} icon: {
                                
                            }
                        }
                        .help(Text("Generate an unlimited number of tokens."))
                        .padding(.leading)
                    }, label: {
                        HStack() {
                            Image(systemName: vm.generateParameters.maxTokens != nil ? "equal.circle" : "infinity.circle")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(vm.generateParameters.maxTokens != nil ? .blue.opacity(1.0) : .blue, Color.transparentAccent)
                                .font(.system(.largeTitle))
                            
                            Text(vm.generateParameters.maxTokens != nil ?"Tokens:" : "Tokens: Unlimited")
                            if vm.generateParameters.maxTokens != nil {
                                TextField(text: Binding<String>(
                                    get: {
                                        let tokens = vm.generateParameters.maxTokens
                                        let tokenString = tokens == nil ? "" : "\(tokens!)"
                                        return String("\(tokenString)")
                                    },
                                    set: { newValue in
                                        vm.generateParameters.maxTokens = Int(newValue)
                                    }
                                ),
                                          label: {}
                                )
                                .disabled(vm.generateParameters.maxTokens == nil)
                                .help(Text("The max number of tokens that can be generated."))
                                .textFieldStyle(.plain)
                                .fixedSize(horizontal: true, vertical: false)
                                
                            }
                            Spacer()
                        }
                    })
                    
                    Divider().foregroundColor(.transparentAccent.opacity(1.0))
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:"shuffle.circle", variableValue:Double(vm.generateParameters.temperature))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(vm.generateParameters.temperature < 0.5 ? .blue.opacity(Double(vm.generateParameters.temperature * 2)) : .blue, Color.transparentAccent)
                                .font(.system(.largeTitle))
                            Text("Temperature: \(vm.generateParameters.temperature, specifier: "%.2f")")
                        }
                        
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(vm.generateParameters.temperature)
                                },
                                set: { newValue in
                                    vm.objectWillChange.send()
                                    
                                    vm.generateParameters.temperature = Float(newValue)
                                }
                            ),
                            in: 0.0...2.0,
                            label: {
                                EmptyView()
                            }
                        )
                        .tint(vm.generateParameters.temperature < 0.5 ? .blue : (vm.generateParameters.temperature < 1.0 ? Color.transparentAccent : .green))
                    }
                    .help(Text("Controls the randomness of the generated text."))
                    
                    Divider().foregroundColor(.transparentAccent.opacity(1.0))
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:"chart.bar.fill", variableValue:Double(vm.generateParameters.topP))
                                .foregroundStyle(Color.transparentAccent)
                                .font(.system(.largeTitle))
                            Text("TopP: \(vm.generateParameters.topP, specifier: "%.2f")")
                        }
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(vm.generateParameters.topP)
                                },
                                set: { newValue in
                                    vm.generateParameters.topP = Float(newValue)
                                }
                            ),
                            in: 0.0...1.0,
                            label: {
                                EmptyView()
                            }
                        )
                        .tint(Color.transparentAccent)
                    }
                    .help(Text("Controls creativity vs. determinism. Low Temperature (0.1-0.3) → For predictable, repetitive outputs. Low Temperature (0.1-0.3) → For predictable, repetitive outputs. High Temperature (1.2+) → For wild, unexpected responses:."))
                    
                    Divider().foregroundColor(.transparentAccent.opacity(1.0))
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:vm.generateParameters.repetitionPenalty == nil ? "circle.hexagongrid.fill" : (vm.generateParameters.repetitionPenalty! > 1.0 ? "circle.grid.3x3.circle" : "circle.hexagongrid.circle"), variableValue:Double(vm.generateParameters.repetitionPenalty ?? 0.0))
                                .foregroundStyle(.blue, Color.transparentAccent)
                                .font(.system(.largeTitle))
                                .animation(.easeOut, value: 1)
                            Toggle(isOn: Binding<Bool>(
                                get:{vm.generateParameters.repetitionPenalty != nil},
                                set: { newValue in
                                    vm.generateParameters.repetitionPenalty = newValue ? 1.0 : nil
                                }
                            )
                            ) {
                                EmptyView()
                            }
                            
                            Text("Repetition Penalty: \(vm.generateParameters.repetitionPenalty ?? 0.0, specifier: "%.2f")")
                            
                            Spacer()
                            
                        }
                        
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(vm.generateParameters.repetitionPenalty ?? 0.0)
                                },
                                set: { newValue in
                                    vm.generateParameters.repetitionPenalty = Float(newValue)
                                }
                            ),
                            in: 0.0...2.0,
                            label: {
                                EmptyView()
                            }
                        )
                        .tint(Color.transparentAccent)
                        .disabled(vm.generateParameters.repetitionPenalty == nil)
                        
                    }
                    .help(Text("Penalizes repetition of tokens, reducing loops. Range: >1.0 to discourage repeating; <1.0 encourages repetition. When to adjust: Use around 1.1–1.2 for long-form content or dialogue to avoid stuttering."))
                    
                    Divider().foregroundColor(.transparentAccent.opacity(1.0))
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:"square.grid.3x3.square", variableValue:Double(vm.generateParameters.repetitionContextSize))
                                .foregroundStyle(.blue, Color.transparentAccent)
                                .font(.system(.largeTitle))
                                .animation(.easeOut, value: 1)
                            
                            Text("Repetition Context Size: \(Double(vm.generateParameters.repetitionContextSize), specifier: "%.0f")")
                            
                            Spacer()
                            
                        }
                        
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(vm.generateParameters.repetitionContextSize)
                                },
                                set: { newValue in
                                    vm.generateParameters.repetitionContextSize = Int(newValue)
                                }
                            ),
                            in: 0.0...512.0,
                            label: {
                                EmptyView()
                            }
                        )
                        .tint(Color.transparentAccent)
                        
                    }
                    .help(Text("Number of previous tokens checked for penalizing repetition. Increase when generating longer text, to avoid repetition over a wider span."))
                    
//                    Divider().foregroundColor(.transparentAccent.opacity(1.0))
                    
                }
                
//                .padding()
            })
            //        .padding(5)
        }
//        .background(content: {
//            RoundedRectangle(cornerRadius: CGFloat(3))
//                .stroke(Color.transparentAccent.opacity(0.25), lineWidth: 1.0)
//        })
//        .border(.teal, width: 1.0)
        .padding()
        
    }
}

#Preview {
    ChatAdjustmentView(viewModel: ChatViewModel(mlxService: MLXService()))
}
