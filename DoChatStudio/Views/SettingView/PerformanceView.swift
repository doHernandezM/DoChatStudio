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
    @Bindable private var vm: ChatViewModel
    
    /// Initializes the chat view with a view model
    /// - Parameter viewModel: The view model to manage chat state
    init(viewModel: ChatViewModel) {
        self.vm = viewModel
    }
    
    
    var body: some View {
        ScrollView(.vertical, content: {
            VStack (){
                
                
                VStack {
                    
                    Grid() {
                        GridRow {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.green, Color.transparentAccent)
                                    .font(.system(.largeTitle))
                                Text("Memory Usage Chart")
                                    .font(.system(.title3))
                                    .bold()
                                Spacer()
                            }
                        }
                        if vm.pm.gpuSnapshot.count > 0 {
                            GridRow {
                                VStack{
                                    Chart {
                                        ForEach(vm.pm.gpuSnapshot) {  snapshot in
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
                                    .chartScrollPosition(initialX: vm.pm.gpuSnapshot.count)
                                    .chartScrollableAxes(.horizontal)
                                    
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 5).foregroundColor(Color.secondary.opacity(0.1)))
                            }
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
                                    Text("Cache")
                                        .font(.system(.title3))
                                        .bold()
                                    Spacer()
                                }
                            }
                            GridRow {
                                HStack {
                                    Spacer()
                                    Text("Current:")
                                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.gpuSnapshot.count - 1 >= 1 ? vm.pm.gpuSnapshot[vm.pm.gpuSnapshot.count - 1].cacheMemory : 0), countStyle: .file))")
                                }
                            }
                            GridRow {
                                HStack {
                                    Spacer()
                                    Text("Limit:")
                                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.cacheLimit), countStyle: .file))")
                                }
                            }
                        }
                        
                        Divider().foregroundColor(.transparentAccent.opacity(1.0))
                        
                        Grid() {
                            GridRow {
                                HStack {
                                    Image(systemName:"memorychip", variableValue:Double(vm.generateParameters.temperature))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.blue, Color.transparentAccent)
                                        .font(.system(.largeTitle))
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
                                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.activeMemory), countStyle: .file))")
                                }
                            }
                            GridRow {
                                HStack {
                                    Spacer()
                                    Text("Peak:")
                                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.peakMemory), countStyle: .file))")
                                }
                            }
                            GridRow {
                                HStack {
                                    Spacer()
                                    Text("Limit:")
                                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.memoryLimit), countStyle: .file))")
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
                                    .foregroundStyle(.blue, Color.transparentAccent)
                                    .font(.system(.largeTitle))
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
                    }
                }
            }
            .padding()
//            .animation(.easeOut, value: 1)
        })
    }
}

#Preview {
    ChatAdjustmentView(viewModel: ChatViewModel(mlxService: MLXService()))
}
