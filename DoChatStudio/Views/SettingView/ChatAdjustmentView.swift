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
        ScrollView(.vertical, content: {
            VStack{
                
                Menu {
                    Button(action: {
                        print("newModel")
                    }  ) {
                        Text("Choose a new model...")
                        Text("Select a Llama .GGUF file")
                    }
                    
                    Divider()
                    
                    ForEach(MLXService.availableModels, id: \.self) { model in
                        
                        Button(action: {
                            vm.selectedModel = model
                        } ) {
                            Text("\(model.displayName)")
                                .tag(model)
                            Text("Size: ")
                        }
                    }
                    
                } label: {
                    Label(vm.selectedModel.displayName, systemImage: "book.fill")
                }
                //            .menuStyle(.button)
                .tint(.accentColor)
                
                Divider().hidden()
                
                // Show download progress for model loading
                if let progress = vm.modelDownloadProgress, !progress.isFinished {
                    DownloadProgressView(progress: vm.modelDownloadProgress!, fractionCompleted: vm.modelDownloadProgress!.fractionCompleted)
                    
                }
                
                Divider().hidden()
                
                // Display error message if present
                if let errorMessage = vm.errorMessage {
                    ErrorView(errorMessage: errorMessage)
                }
                
                Divider().foregroundColor(.accentColor)
                
                HStack() {
                    Image(systemName: vm.generateParameters.maxTokens != nil ? "equal.circle" : "infinity.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.generateParameters.maxTokens != nil ? .blue.opacity(1.0) : .blue, .tint)
                        .font(.system(.largeTitle))
                    
                    Toggle(isOn: Binding<Bool>(
                        get:{vm.generateParameters.maxTokens == nil},
                        set: { newValue in
                            vm.generateParameters.maxTokens = newValue ? nil : 200
                        }
                    )
                    ) {
                        Text(vm.generateParameters.maxTokens == nil ? "Unlimited Tokens" : "Limit to ")
                    }
                    .help(Text("Generate an unlimited number of tokens."))
                    
                    TextField(text: Binding<String>(
                        get: {
                            String("\(vm.generateParameters.maxTokens ?? 0)")
                        },
                        set: { newValue in
                            vm.generateParameters.maxTokens = Int(newValue)
                        }
                    ),
                              label: {
                        EmptyView()
                    }
                    )
                    .disabled(vm.generateParameters.maxTokens == nil)
                    .help(Text("The max number of tokens that can be generated."))
                    
                    if vm.generateParameters.maxTokens != nil {
                        Text("tokens.")
                    }
                    
                    Spacer()
                }
                    
                    Divider().hidden()
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:"shuffle.circle", variableValue:Double(vm.generateParameters.temperature))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(vm.generateParameters.temperature < 0.5 ? .blue.opacity(Double(vm.generateParameters.temperature * 2)) : .blue, Color.accentColor)
                                .font(.system(.largeTitle))
                            Text("Temperature: \(vm.generateParameters.temperature, specifier: "%.2f")")
                        }
                        Slider(
                            value: Binding<Double>(
                                get: {
                                    Double(vm.generateParameters.temperature)
                                },
                                set: { newValue in
                                    vm.generateParameters.temperature = Float(newValue)
                                }
                            ),
                            in: 0.0...2.0,
                            label: {
                                EmptyView()
                            }
                        )
                        .tint(vm.generateParameters.temperature < 0.5 ? .blue : (vm.generateParameters.temperature < 1.0 ? Color.accentColor : .green))
                    }
                    .help(Text("Controls the randomness of the generated text."))
                    
                    Divider().hidden()
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:"chart.bar.fill", variableValue:Double(vm.generateParameters.topP))
                                .foregroundStyle(Color.accentColor)
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
                        .tint(Color.accentColor)
                    }
                    .help(Text("Controls creativity vs. determinism. Low Temperature (0.1-0.3) → For predictable, repetitive outputs. Low Temperature (0.1-0.3) → For predictable, repetitive outputs. High Temperature (1.2+) → For wild, unexpected responses:."))
                    
                    Divider().hidden()
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName:vm.generateParameters.repetitionPenalty == nil ? "circle.hexagongrid.fill" : (vm.generateParameters.repetitionPenalty! > 1.0 ? "circle.grid.3x3.circle" : "circle.hexagongrid.circle"), variableValue:Double(vm.generateParameters.repetitionPenalty ?? 0.0))
                                .foregroundStyle(.blue, Color.accentColor)
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
                        .tint(Color.accentColor)
                        .disabled(vm.generateParameters.repetitionPenalty == nil)
                        
                    }
                    .help(Text("Penalizes repetition of tokens, reducing loops. Range: >1.0 to discourage repeating; <1.0 encourages repetition. When to adjust: Use around 1.1–1.2 for long-form content or dialogue to avoid stuttering."))
                    
                }
                .padding()
            })
            //        .padding(5)
        }
    }
    
    #Preview {
        ChatAdjustmentView(viewModel: ChatViewModel(mlxService: MLXService()))
    }
