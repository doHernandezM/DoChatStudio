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
        
        //        self.vm.takeMemorySnapshot()
    }
    
    
    var body: some View {
        VStack {
            memoryChartSection
            Divider().foregroundStyle(vm.style.transparentAccent.opacity(1.0))
            cacheSection
            Divider().foregroundStyle(vm.style.transparentAccent.opacity(1.0))
            gpuMemorySection
            Divider().foregroundStyle(vm.style.transparentAccent.opacity(1.0))
            tokensSection
            Divider().foregroundStyle(vm.style.transparentAccent)
            
        }
        .onAppear {
            if vm.performance.gpuSnapshots.isEmpty {
                vm.takeMemorySnapshot()
            }
        }
        //        .padding()
        Spacer()
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var memoryChartSection: some View {
        Grid {
            GridRow {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.blue, Color.clear)
                        .font(.system(.title))
                        .background {
                            Image(systemName: "square")
                                .foregroundStyle(vm.style.accent)
                                .font(.system(.largeTitle))
                                .background {
                                    Image(systemName: "square.fill")
                                        .foregroundStyle(vm.style.transparentAccent)
                                        .font(.system(.largeTitle))
                                }
                        }
                    Text("Memory Usage Chart")
                        .font(.system(.title3))
                        .bold()
                    Spacer()
                }
            }
            if !vm.performance.gpuSnapshots.isEmpty {
                GridRow {
                    //                    VStack {
                    gpuChart
                    //                            .padding(.top, 2)
                    //                    }
                    //                    .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(vm.style.transparentAccent, lineWidth: 1.0)
                        .foregroundColor(Color.secondary.opacity(0.1))
                )
            } else {
                GridRow {
                    HStack {
                        Spacer()
                        Text("There is no memory usage data.")
                    }
                }
            }
        }
    }
    
    private var gpuChart: some View {
        let snapshots = vm.performance.gpuSnapshots
        return Chart {
            ForEach(snapshots) { snapshot in
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
            "Cache (MB)": .green,
            "Active Memory(MB)": .blue
        ])
        .chartYAxis {
            AxisMarks { value in
                if let memorySize = value.as(Int.self) {
                    AxisValueLabel {
                        VStack(alignment: .leading) {
                            Text("\(memorySize)MB")
                        }
                    }
                }
            }
        }
        .defaultScrollAnchor(.trailing)
        .chartScrollableAxes(.horizontal)
    }
    
    @ViewBuilder
    private var cacheSection: some View {
        Grid {
            GridRow {
                HStack {
                    Image(systemName: "archivebox", variableValue: Double(vm.generateParameters.temperature))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.style.accent, vm.style.transparentAccent)
                        .font(.system(.largeTitle))
                        .background {
                            Image(systemName: "archivebox.fill")
                                .foregroundStyle(vm.style.transparentAccent)
                                .font(.system(.largeTitle))
                        }
                    Text("Cache")
                        .font(.system(.title3))
                        .bold()
                    Spacer()
                    clearCacheButton
                }
            }
            GridRow {
                HStack {
                    Spacer()
                    Text("Current:")
                    Text(currentCacheText)
                }
            }
            GridRow {
                HStack {
                    Spacer()
                    Text("Limit:")
                    Text(cacheLimitText)
                }
            }
        }
    }
    
    private var clearCacheButton: some View {
        Button(action: {
            vm.clear([.gpuCache])
            vm.takeMemorySnapshot()
        }, label: {
            VStack {
                Image("custom.archivebox.badge.minus")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.red, vm.style.accent)
                Text("Clear Cache")
            }
            .padding(5)
        })
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .buttonStyle(.plain)
        .padding(.bottom)
    }
    
    private var currentCacheText: String {
        let count = vm.performance.gpuSnapshots.count
        let cache = (count - 1 >= 1) ? vm.performance.gpuSnapshots[count - 1].cacheMemory : 0
        return ByteCountFormatter.string(fromByteCount: Int64(cache), countStyle: .file)
    }
    
    private var cacheLimitText: String {
        ByteCountFormatter.string(fromByteCount: Int64(vm.performance.cacheLimit), countStyle: .file)
    }
    
    @ViewBuilder
    private var gpuMemorySection: some View {
        Grid {
            GridRow {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundStyle(vm.style.accent)
                        .font(.system(.largeTitle))
                        .background {
                            Image(systemName: "memorychip.fill")
                                .foregroundStyle(vm.style.transparentAccent)
                                .font(.system(.largeTitle))
                        }
                        .overlay {
                            Image(systemName: "rainbow")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(.title3))
                                .bold()
                        }
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
                    Text(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.activeMemory), countStyle: .file))
                }
            }
            GridRow {
                HStack {
                    Spacer()
                    Text("Peak:")
                    Text(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.peakMemory), countStyle: .file))
                }
            }
            GridRow {
                HStack {
                    Spacer()
                    Text("Limit:")
                    Text(ByteCountFormatter.string(fromByteCount: Int64(vm.performance.memoryLimit), countStyle: .file))
                }
            }
        }
    }
    
    @ViewBuilder
    private var tokensSection: some View {
        Grid {
            GridRow {
                HStack{
                    StyleModel.TokenView(style: vm.style)
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
        }
    }
    
}

#Preview {
    ConfigurationView(viewModel: ChatModel(mlxService: MLXService()))
}
