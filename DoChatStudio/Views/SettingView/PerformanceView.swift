//
//  ChatAdjustmentView.swift
//  DoChatStudio
//
//  Created by Cosas on 6/19/25.
//

import SwiftUI
import Charts

struct PerformanceView: View {
    /// View model that manages the chat state and business logic
    @Bindable private var vm: ChatModel
    
    /// Initializes the chat view with a view model
    /// - Parameter viewModel: The view model to manage chat state
    init(viewModel: ChatModel) {
        self.vm = viewModel
        
        
    }
    
    
    var body: some View {
        
        VStack {
            
            Grid() {
                GridRow {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.blue, Color.clear)
                            .font(.system(.title))
                            .background(alignment: .center, content: {
                                Image(systemName:"square")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.system(.largeTitle))
                                    .background(alignment: .center, content: {
                                        Image(systemName:"square.fill")
                                            .foregroundStyle(Color.transparentAccent)
                                            .font(.system(.largeTitle))
                                    })
                            })
                        Text("Memory Usage Chart")
                            .font(.system(.title3))
                            .bold()
                        Spacer()
                    }
                }
                if vm.performance.gpuSnapshots.count > 0 {
                    GridRow {
                        VStack{
                            Chart {
                                ForEach(vm.performance.gpuSnapshots) {  snapshot in
                                    LineMark(
                                        x: .value("Time", snapshot.date),
                                        y: .value("Active Memory Size", snapshot.activeMemory / 1024 / 1024),
                                        series: .value("GPU", "A")
                                    )
                                    .foregroundStyle(.blue.opacity(0.5))
                                    LineMark(
                                        x: .value("Time", snapshot.date),
                                        y: .value("Cache Size", snapshot.cacheMemory / 1024 / 1024),
                                        series: .value("Cache", "B")
                                    )
                                    .foregroundStyle(.green.opacity(0.5))
                                }
                            }
                            .chartForegroundStyleScale([
                                "Cache (MB)": .green, "Active Memory(MB)": .blue
                            ])
                            .chartYAxis {
                                AxisMarks() { value in
                                    if let memorySize = value.as(Int.self) {
                                        AxisValueLabel {
                                            VStack(alignment: .leading) {
                                                Text("\(memorySize)MB")
                                            }
                                        }
                                    }
                                }
                            }
                            .chartScrollPosition(initialX: vm.performance.gpuSnapshots.count)
                            .chartScrollableAxes(.horizontal)
                        }
                        .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 5).foregroundColor(Color.secondary.opacity(0.1)))
                    
                } else {
                    GridRow {
                        HStack {
                            Spacer()
                            Text("There is no memory usage data.")
                        }
                    }
                }
            }
            
            Divider().foregroundColor(.transparentAccent.opacity(1.0))
            
            VStack() {
                Grid() {
                    GridRow {
                        HStack {
                            Image(systemName:"archivebox", variableValue:Double(vm.generateParameters.temperature))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.transparentAccent)
                                .font(.system(.largeTitle))
                                .background(alignment: .center, content: {
                                    Image(systemName:"archivebox.fill")
                                        .foregroundStyle(Color.transparentAccent)
                                        .font(.system(.largeTitle))
                                })
                            Text("Cache")
                                .font(.system(.title3))
                                .bold()
                            Spacer()
                            
                            Button(action: {
                                vm.clear([.gpuCache])
                                vm.takeMemorySnapshot()
                            }, label: {
                                VStack{
                                    Image(systemName: "memorychip.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.accentColor)
                                    //                                            .font(.system(.title2))
                                        .overlay(alignment: .topTrailing, content: {
                                            Image(systemName: "xmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(Color.white, Color.red)
                                                .font(.system(.caption))
                                        })
                                    Text("Clear Cache")
                                }
                                .padding(5)
                            })
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .contentShape(RoundedRectangle(cornerRadius: 5)) // Defines tappable area
                            .buttonStyle(.plain)
                            .padding(.bottom)
                        }
                    }
                    GridRow {
                        HStack {
                            Spacer()
                            Text("Current:")
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.gpuSnapshots.count - 1 >= 1 ? vm.performance.gpuSnapshots[vm.performance.gpuSnapshots.count - 1].cacheMemory : 0), countStyle: .file))")
                        }
                    }
                    GridRow {
                        HStack {
                            Spacer()
                            Text("Limit:")
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.cacheLimit), countStyle: .file))")
                        }
                    }
                }
                
                Divider().foregroundColor(.transparentAccent.opacity(1.0))
                
                Grid() {
                    GridRow {
                        HStack {
                            Image(systemName:"memorychip")
                                .foregroundStyle(Color.accentColor)
                                .font(.system(.largeTitle))
                                .background(alignment: .center, content: {
                                    Image(systemName:"memorychip.fill")
                                        .foregroundStyle(Color.transparentAccent)
                                        .font(.system(.largeTitle))
                                })
                            Text("GPU Memory")
                                .font(.system(.title3))
                                .bold()
                            Spacer()
                        }
                    }
                    GridRow {
                        HStack {
                            Spacer()
                            Text("Active:")
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.activeMemory), countStyle: .file))")
                        }
                    }
                    GridRow {
                        HStack {
                            Spacer()
                            Text("Peak:")
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.peakMemory), countStyle: .file))")
                        }
                    }
                    GridRow {
                        HStack {
                            Spacer()
                            Text("Limit:")
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.memoryLimit), countStyle: .file))")
                        }
                    }
                    
                }
            }
            
            Divider().foregroundColor(.transparentAccent.opacity(1.0))
            
            Grid{
                GridRow {
                    HStack{
                        Image(systemName:"dollarsign.circle")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.blue, Color.accentColor)
                            .font(.system(.largeTitle))
                            .background(alignment: .center, content: {
                                Image(systemName:"circle.fill")
                                    .foregroundStyle(Color.transparentAccent)
                                    .font(.system(.largeTitle))
                            })
                        Text("Tokens")
                            .font(.system(.title3))
                            .bold()
                        Spacer()
                    }
                }
                GridRow {
                    HStack {
                        Spacer()
                        Text("Tokens per second:")
                        
                        Text("\(vm.tokensPerSecond, format: .number.precision(.fractionLength(2)))")
                        
                    }
                }
                GridRow {
                    HStack {
                        Spacer()
                        Text("Generation Time:")
                        if let generatedInfo = vm.messages.last?.generationInfo {
                            Text("\(generatedInfo.generationTime)")
                        }
                    }
                }
                GridRow {
                    HStack {
                        Spacer()
                        Text("Generated Tokens:")
                        if let generatedInfo = vm.messages.last?.generationInfo {
                            Text("\(generatedInfo.generationTokenCount)")
                        }
                    }
                }
                GridRow {
                    HStack {
                        Spacer()
                        Text("Generated Prompt Tokens:")
                        if let generatedInfo = vm.messages.last?.generationInfo {
                            Text("\(generatedInfo.promptTokenCount)")
                        }
                    }
                }
                //                        Spacer()
            }
            //                    Spacer()
        }
        Spacer()
    }
    
}

#Preview {
    ConfigurationView(viewModel: ChatModel(mlxService: MLXService()))
}
