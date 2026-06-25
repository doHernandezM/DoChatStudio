//
//  PerformanceModel.swift
//  DoChatStudio
//
//  Created by Cosas on 6/24/25.
//

// Defines codable GPU memory metrics and timestamped samples collected during generation.

import Foundation
import MLX
import MLXLMCommon

@Observable
class PerformanceModel: ObservableObject, Codable, Identifiable {
    
    var id: UUID = UUID()
    
    var activeMemory: Int = 0
    var memoryLimit: Int = 0
    var cacheLimit: Int = 0
    var peakMemory: Int = 0
    
    var gpuSnapshots: [Snapshot] = []
    
}

struct Snapshot: CustomStringConvertible, Codable, Sendable, Identifiable {
    
    public var id: UUID = UUID()
    
    public var date: Date = Date()
    
    /// See ``GPU/activeMemory``.
    public var activeMemory: Int = 0

    /// See ``GPU/cacheMemory``.
    public var cacheMemory: Int = 0

    /// See ``GPU/peakMemory``.
    public var peakMemory: Int = 0

    public var description: String {
        func scale(_ value: Int, width: Int = 12) -> String {
            let v: String
            if value > 1024 * 1024 * 10 {
                v = "\(value / (1024 * 1024))M"
            } else {
                v = "\(value / 1024)K"
            }
            let pad = String(repeating: " ", count: max(0, width - v.count))
            return v + pad
        }

        return """
            Peak:   \(scale(peakMemory)) (\(peakMemory))
            Active: \(scale(activeMemory)) (\(activeMemory))
            Cache:  \(scale(cacheMemory)) (\(cacheMemory))
            """
    }
    
}
