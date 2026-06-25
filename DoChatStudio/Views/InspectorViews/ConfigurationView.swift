//
//  ChatAdjustmentView.swift
//  DoChatStudio
//
//  Created by Cosas on 6/19/25.
//

// Presents generation parameters and style controls, including undoable sampling adjustments.

import SwiftUI
import Charts

struct ConfigurationView: View {
    /// View model that manages the chat state and business logic
    @Bindable private var vm: ChatModel
    @State private var flipped = true
    
    @Namespace private var animation
    
    /// Initializes the chat view with a view model
    /// - Parameter viewModel: The view model to manage chat state
    init(viewModel: ChatModel) {
        self.vm = viewModel
    }
    
    var body: some View {
            VStack(spacing: 0){
                HStack() {
                    
                    Button(action:{
                        vm.style.showOptions = true
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 4 )
                                .stroke(vm.style.showOptions ? vm.style.accent : Color.secondary, lineWidth: 1.0)
                                .fill(vm.style.showOptions ? vm.style.transparentAccent : Color.clear)
                            HStack{
                                Image(systemName: "gearshape.2.fill")
                                    .padding(.leading)
                                Text("Options")
                                Spacer()
                            }
                            .padding([.top,.bottom], 4)
                            .foregroundStyle(vm.style.showOptions ? Color.primary : Color.secondary)
                        }
                        //                            .frame(width: geo.size.width / 2.25)
                        .contentShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    
                    Button(action:{
                        vm.style.showOptions = false
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 4 )
                                .stroke(!vm.style.showOptions ? vm.style.accent : Color.secondary, lineWidth: 1.0)
                                .fill(!vm.style.showOptions ? vm.style.transparentAccent : Color.clear)
                            HStack{
                                Image(systemName: "paintpalette.fill")
                                    .padding(.leading)
                                    .symbolRenderingMode(.palette)
                                Text("Style")
                                Spacer()
                            }.padding([.top,.bottom], 4)
                                .foregroundStyle(!vm.style.showOptions ? Color.primary : Color.secondary)
                        }
                        //                        .frame(width: geo.size.width / 2.25)
                        .contentShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    //                    Spacer()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
                
                ZStack {
                    if vm.style.showOptions {
                        ModelConfigurationView(vm: vm)
                            .opacity(vm.style.showOptions ? 1.0 : 0.0)
                        
                    } else {
                        StyleView(vm: vm)
                            .opacity(vm.style.showOptions ? 0.0 : 1.0)
                    }
                }
                .padding([.top])
            }
    }
}

#Preview {
      let em = EntitlementManager()
      let pm = PurchaseManager(entitlementManager: em)
      return ConfigurationView(viewModel: ChatModel(mlxService: MLXService()))
          .environmentObject(em)
          .environmentObject(pm)
  }

struct ModelConfigurationView: View {
    @Environment(\.undoManager) var undoManager
    /// Edits `GenerateParameters` that ChatModel forwards directly to MLX.
    @Bindable var vm: ChatModel
    
    var body: some View {
        VStack{
                        
            VStack(alignment: .leading) {
                HStack() {
                    Image(systemName: vm.generateParameters.maxTokens != nil ? "equal.circle" : "infinity.circle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.generateParameters.maxTokens != nil ? .blue.opacity(1.0) : .blue, vm.style.accent)
                        .font(.system(.largeTitle))
                        .background(alignment: .center, content: {
                            Image(systemName:"circle.fill")
                                .foregroundStyle(vm.style.transparentAccent)
                                .font(.system(.largeTitle))
                        })
                    
                    Text(vm.generateParameters.maxTokens != nil ?"Tokens:" : "Tokens: Unlimited")
                        .font(.system(.title3))
                        .bold()
                    if vm.generateParameters.maxTokens != nil {
                        TextField(text: Binding<String>(
                            get: {
                                let tokens = vm.generateParameters.maxTokens
                                let tokenString = tokens == nil ? "" : "\(tokens!)"
                                return String(tokenString)
                            },
                            set: { newValue in
                                let oldValue = vm.generateParameters.maxTokens
                                vm.generateParameters.maxTokens = newValue.isNumber ? Int(newValue) : 200
                                undoManager?.registerUndo(withTarget: vm) { vm in
                                    let current: Int?  = vm.generateParameters.maxTokens
                                    vm.generateParameters.maxTokens = oldValue
                                    undoManager?.registerUndo(withTarget: vm) { vm in
                                        vm.generateParameters.maxTokens = current
                                    }
                                }
                            }
                        ),
                                  label: {}
                        )
                        .help(Text("The max number of tokens that can be generated."))
                        .textFieldStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    Spacer()
                }
                Toggle(isOn: Binding<Bool>(
                    get:{vm.generateParameters.maxTokens == nil},
                    set: { newValue in
                        let oldValue = vm.generateParameters.maxTokens
                        vm.generateParameters.maxTokens = newValue ? nil : 200
                        undoManager?.registerUndo(withTarget: vm) { vm in
                            let current: Int?  = vm.generateParameters.maxTokens
                            vm.generateParameters.maxTokens = oldValue
                            undoManager?.registerUndo(withTarget: vm) { vm in
                                vm.generateParameters.maxTokens = current
                            }
                        }
                    }
                )
                ) {
                    Label{Text("Use Unlimited Token")} icon: {
                        
                    }
                }
                .tint(vm.style.accent)
                .help(Text("Generate an unlimited number of tokens."))
                .padding(.leading)
            }
            
            Divider().foregroundStyle(vm.style.transparentAccent)
            
            VStack(alignment: .leading) {
                HStack{
                    Image(systemName:"shuffle.circle", variableValue:Double(vm.generateParameters.temperature))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.generateParameters.temperature < 0.5 ? .blue.opacity(Double(vm.generateParameters.temperature * 2)) : .blue, vm.style.accent)
                        .font(.system(.largeTitle))
                        .background(alignment: .center, content: {
                            Image(systemName:"circle.fill")
                                .foregroundStyle(vm.style.transparentAccent)
                                .font(.system(.largeTitle))
                        })
                    Text("Temperature: \(vm.generateParameters.temperature, specifier: "%.2f")")
                        .font(.system(.title3))
                        .bold()
                }
                
                Slider(
                    value: Binding<Double>(
                        get: {
                            Double(vm.generateParameters.temperature)
                        },
                        set: { newValue in
                            let oldValue = vm.generateParameters.temperature
                            vm.generateParameters.temperature = Float(newValue)
                            undoManager?.registerUndo(withTarget: vm) { vm in
                                let current = vm.generateParameters.temperature
                                vm.generateParameters.temperature = oldValue
                                undoManager?.registerUndo(withTarget: vm) { vm in
                                    vm.generateParameters.temperature = current
                                }
                            }
                            undoManager?.setActionName("Change Temperature")
                        }
                    ),
                    in: 0.0...2.0
                )
                .tint(vm.generateParameters.temperature < 0.5 ? .blue : (vm.generateParameters.temperature < 1.0 ? vm.style.accent : .green))
            }
            .help(Text("Controls the randomness of the generated text."))
            
            Divider().foregroundStyle(vm.style.transparentAccent)
            
            VStack(alignment: .leading) {
                HStack{
                    Image("custom.chart.pie.fill", variableValue:Double(vm.generateParameters.topP))
                        .background(alignment: .center, content: {
                            Image(systemName:"circle.fill")
                                .foregroundStyle(vm.style.transparentAccent)
                                .font(.system(.largeTitle))
                        })
                        .font(.system(.largeTitle))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.style.accent, .blue , vm.style.accent)
                    
                    Text("TopP: \(vm.generateParameters.topP, specifier: "%.2f")")
                        .font(.system(.title3))
                        .bold()
                }
                Slider(
                    value: Binding<Double>(
                        get: {
                            Double(vm.generateParameters.topP)
                        },
                        set: { newValue in
                            let oldValue = vm.generateParameters.topP
                            vm.generateParameters.topP = Float(newValue)
                            undoManager?.registerUndo(withTarget: vm) { vm in
                                let current  = vm.generateParameters.topP
                                vm.generateParameters.topP = oldValue
                                undoManager?.registerUndo(withTarget: vm) { vm in
                                    vm.generateParameters.topP = current
                                }
                            }
                        }
                    ),
                    in: 0.0...1.0,
                    label: {
                        EmptyView()
                    }
                )
                .tint(vm.style.accent)
            }
            .help(Text("Controls creativity vs. determinism. Low Temperature (0.1-0.3) → For predictable, repetitive outputs. Low Temperature (0.1-0.3) → For predictable, repetitive outputs. High Temperature (1.2+) → For wild, unexpected responses:."))
            
            Divider().foregroundStyle(vm.style.transparentAccent)
            
            VStack(alignment: .leading) {
                HStack{
                    Group{
                        if vm.generateParameters.repetitionPenalty == nil {
                            Image(systemName:"circle.hexagongrid.fill", variableValue:Double(vm.generateParameters.repetitionPenalty ?? 0.0))
                        } else {
                            Image(systemName:(vm.generateParameters.repetitionPenalty! > 1.0 ? "circle.grid.3x3.circle" : "circle.hexagongrid.circle"), variableValue:Double(vm.generateParameters.repetitionPenalty ?? 0.0))
                        }
                    }
                    .foregroundStyle(.blue, vm.style.accent)
                    .font(.system(.largeTitle))
                    .transition(.symbolEffect(.drawOn.wholeSymbol, options: .speed(5)))     .background(alignment: .center, content: {
                        Image(systemName:"circle.fill")
                            .foregroundStyle(vm.style.transparentAccent)
                            .font(.system(.largeTitle))
                    })
                    Toggle(isOn: Binding<Bool>(
                        get:{vm.generateParameters.repetitionPenalty != nil},
                        set: { newValue in
                            let oldValue = vm.generateParameters.repetitionPenalty
                            vm.generateParameters.repetitionPenalty = newValue ? 1.0 : nil
                            undoManager?.registerUndo(withTarget: vm) { vm in
                                let current = vm.generateParameters.repetitionPenalty
                                vm.generateParameters.repetitionPenalty = oldValue
                                undoManager?.registerUndo(withTarget: vm) { vm in
                                    vm.generateParameters.repetitionPenalty = current
                                }
                            }
                        }
                    )
                    ) {
                        EmptyView()
                    }
                    .tint(vm.style.accent)
                    
                    Text("Repetition Penalty: \(vm.generateParameters.repetitionPenalty ?? 0.0, specifier: "%.2f")")
                        .font(.system(.title3))
                        .bold()
                    Spacer()
                    
                }
                
                Slider(
                    value: Binding<Double>(
                        get: {
                            Double(vm.generateParameters.repetitionPenalty ?? 0.0)
                        },
                        set: { newValue in
                            let oldValue = vm.generateParameters.repetitionPenalty
                            vm.generateParameters.repetitionPenalty = Float(newValue)
                            undoManager?.registerUndo(withTarget: vm) { vm in
                                let current = vm.generateParameters.repetitionPenalty
                                vm.generateParameters.repetitionPenalty = oldValue
                                undoManager?.registerUndo(withTarget: vm) { vm in
                                    vm.generateParameters.repetitionPenalty = current
                                }
                            }
                        }
                    ),
                    in: 0.0...2.0,
                    label: {
                        EmptyView()
                    }
                )
                .tint(vm.style.accent)
                .disabled(vm.generateParameters.repetitionPenalty == nil)
                
            }
            .help(Text("Penalizes repetition of tokens, reducing loops. Range: >1.0 to discourage repeating; <1.0 encourages repetition. When to adjust: Use around 1.1–1.2 for long-form content or dialogue to avoid stuttering."))
            
            Divider().foregroundStyle(vm.style.transparentAccent.opacity(1.0))
            
            VStack(alignment: .leading) {
                HStack{
                    Image(systemName:"square.grid.3x3.square", variableValue:Double(vm.generateParameters.repetitionContextSize))
                        .foregroundStyle(.blue, vm.style.accent)
                        .font(.system(.largeTitle))
                        .animation(.easeOut, value: 1)
                        .background(alignment: .center, content: {
                            Image(systemName:"square.fill")
                                .foregroundStyle(vm.style.transparentAccent)
                                .font(.system(.largeTitle))
                        })
                    Text("Repetition Context Size: \(Double(vm.generateParameters.repetitionContextSize), specifier: "%.0f")")
                        .font(.system(.title3))
                        .bold()
                    Spacer()
                    
                }
                
                Slider(
                    value: Binding<Double>(
                        get: {
                            Double(vm.generateParameters.repetitionContextSize)
                        },
                        set: { newValue in
                            let oldValue = vm.generateParameters.repetitionContextSize
                            vm.generateParameters.repetitionContextSize = Int(newValue)
                            undoManager?.registerUndo(withTarget: vm) { vm in
                                let current = vm.generateParameters.repetitionContextSize
                                vm.generateParameters.repetitionContextSize = oldValue
                                undoManager?.registerUndo(withTarget: vm) { vm in
                                    vm.generateParameters.repetitionContextSize = current
                                }
                            }
                        }
                    ),
                    in: 0.0...512.0,
                    label: {
                        EmptyView()
                    }
                )
                .tint(vm.style.accent)
                
            }
            .help(Text("Number of previous tokens checked for penalizing repetition. Increase when generating longer text, to avoid repetition over a wider span."))
            
            Divider().foregroundStyle(vm.style.transparentAccent.opacity(1.0))
            
        }
    }
}


struct FlipEffect: GeometryEffect {
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    @Binding var flipped: Bool
    var angle: Double
    let axis: (x: CGFloat, y: CGFloat)
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        
        DispatchQueue.main.async {
            self.flipped = self.angle >= 90 && self.angle < 270
        }
        
        let tweakedAngle = flipped ? -180 + angle : angle
        let a = CGFloat(Angle(degrees: tweakedAngle).radians)
        
        var transform3d = CATransform3DIdentity;
        transform3d.m34 = -1/max(size.width, size.height)
        
        transform3d = CATransform3DRotate(transform3d, a, axis.x, axis.y, 0)
        transform3d = CATransform3DTranslate(transform3d, -size.width/2.0, -size.height/2.0, 0)
        
        let affineTransform = ProjectionTransform(CGAffineTransform(translationX: size.width/2.0, y: size.height / 2.0))
        
        return ProjectionTransform(transform3d).concatenating(affineTransform)
    }
}
