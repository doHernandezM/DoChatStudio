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
            VStack{
                
                Divider().hidden()
                
                VStack {
                    if vm.pm.gpuSnapshot.count > 2 {
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
                            .chartYScale(domain: 0...vm.pm.peakMemory / 1024 / 1024)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 5).foregroundColor(Color.accentColor.opacity(0.1))
                            )
                        }
                    }
                    HStack() {
                        HStack {
                            Image(systemName:"archivebox", variableValue:Double(vm.generateParameters.temperature))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, Color.accentColor)
                                .font(.system(.largeTitle))
                            HStack(alignment: .center) {
                                Text("Cache(Current/Limit): \(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.gpuSnapshot.count - 1 >= 1 ? vm.pm.gpuSnapshot[vm.pm.gpuSnapshot.count - 1].cacheMemory : 0), countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.cacheLimit), countStyle: .file))")
                            }
                        }
                        Spacer()
                        HStack {
                            Image(systemName:"memorychip", variableValue:Double(vm.generateParameters.temperature))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.blue, Color.accentColor)
                                .font(.system(.largeTitle))
                            HStack(alignment: .center) {
                                Text("GPU Memory(Active/Peak/Max): \(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.activeMemory), countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.peakMemory), countStyle: .file)) / \(ByteCountFormatter.string(fromByteCount: Int64(vm.pm.memoryLimit), countStyle: .file))")
                            }
                        }
                    }
                    HStack{
                        Spacer()
                        HStack{
                            Image(systemName:"dollarsign.ring")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.blue, Color.accentColor)
                                .font(.system(.largeTitle))
                            
                            Text("\(vm.tokensPerSecond, format: .number.precision(.fractionLength(2))) tokens/s")
                        }
                    }
                }
            }
            .padding()
            .animation(.easeOut, value: 1)
        })
    }
}

#Preview {
    ChatAdjustmentView(viewModel: ChatViewModel(mlxService: MLXService()))
}
