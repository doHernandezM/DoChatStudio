//
// AppUtilities.swift
// DoChatStudio
//
// Created by Cosas on 6/1/25.
//

//
//  AppUtilities.swift
//  DoChatStudio
//
//  Created by Cosas on 6/1/25.
//

import Foundation
import Darwin          // for sysctl
import Darwin.Mach     // for task_info, mach_task_self_, vm_statistics64, host_statistics64, etc.

#if canImport(os)
import os              // for os_proc_available_memory()
#endif

import Swift
import SwiftUI

/// Returns the approximate RAM usage (resident size) of your app in bytes.
/// Works on both iOS and macOS by calling `task_info(...)`.
func getAppMemoryUsage() -> UInt64? {
    // Prepare a mach_task_basic_info struct
    var info = mach_task_basic_info()
    // Count of "natural_t" slots
    var count = mach_msg_type_number_t(
        MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
    )
    
    // Call task_info(mach_task_self_, MACH_TASK_BASIC_INFO, &info, &count)
    let kr: kern_return_t = withUnsafeMutablePointer(to: &info) { ptr in
        ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            task_info(
                mach_task_self_,
                task_flavor_t(MACH_TASK_BASIC_INFO),
                intPtr,
                &count
            )
        }
    }
    
    guard kr == KERN_SUCCESS else {
        return nil
    }
    
    // resident_size is in bytes
    return UInt64(info.resident_size)
}

/// Returns the approximate amount of system RAM still available (in bytes).
///
/// - On **iOS 15+**, this returns `os_proc_available_memory()`.
/// - On **macOS 12+**, it uses `vm_statistics64` + `sysctl` to compute “free + inactive” pages.
/// - Falls back to `nil` on older OS versions or if any call fails.
/// Returns the approximate RAM usage (resident size) of your app in bytes.
/// Works on both iOS and macOS by calling `task_info(...)`.
///
func getAvailableMemory() -> UInt64? {
#if os(iOS)
    if #available(iOS 15.0, *) {
        let available = os_proc_available_memory()
        // `os_proc_available_memory()` returns `Int64.max` if it can’t determine a value.
        guard available != Int64.max else {
            return nil
        }
        return UInt64(available)
    } else {
        return nil
    }
    
#elseif os(macOS)
    // 1) Fetch total physical RAM via `sysctl(CTL_HW, HW_MEMSIZE)` (not strictly needed for "available," but shown for completeness).
    var totalRAM: UInt64 = 0
    var mib: [Int32] = [CTL_HW, HW_MEMSIZE]
    var sizeOfTotal = MemoryLayout<UInt64>.size
    let sysctlResult = sysctl(&mib, UInt32(mib.count), &totalRAM, &sizeOfTotal, nil, 0)
    guard sysctlResult == 0 else {
        return nil
    }
    
    // 2) Fetch `vm_statistics64_data_t` using `host_statistics64`.
    var vmStats = vm_statistics64_data_t()
    // Calculate how many `integer_t` slots `vm_statistics64_data_t` occupies.
    var vmStatsCount = mach_msg_type_number_t(
        MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
    )
    
    // `mach_host_self()` gives us the “host port” for the current machine.
    let hostPort: host_t = mach_host_self()
    
    let hostResult = withUnsafeMutablePointer(to: &vmStats) { ptr -> kern_return_t in
        ptr.withMemoryRebound(to: integer_t.self, capacity: Int(vmStatsCount)) { intPtr in
            host_statistics64(
                hostPort,
                HOST_VM_INFO64,
                intPtr,
                UnsafeMutablePointer<mach_msg_type_number_t>(mutating: &vmStatsCount)
            )
        }
    }
    
    guard hostResult == KERN_SUCCESS else {
        return nil
    }
    
    // 3) `vm_kernel_page_size` is the size (in bytes) of one VM page.
    let pageSize = UInt64(vm_kernel_page_size)
    
    // 4) “Available-ish” memory = free + inactive pages.
    let freePages     = UInt64(vmStats.free_count)
    let inactivePages = UInt64(vmStats.inactive_count)
    let availableBytes = (freePages + inactivePages) * pageSize
    
    return availableBytes
    
#else
    return nil
#endif
}


extension String {
    var isNumber: Bool {
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
    }
}



#if os(iOS)
typealias PlatformColor = UIColor
extension Color {
    init(platformColor: PlatformColor) {
        self.init(uiColor: platformColor)
    }
}
#elseif os(macOS)
typealias PlatformColor = NSColor
extension Color {
    init(platformColor: PlatformColor) {
        self.init(nsColor: platformColor)
    }
}
#endif

extension PlatformColor {
    var color:Color {
        get {
            return Color(self)
        }
    }
}

extension Color {
    var platformColor: PlatformColor {
        get {
            return PlatformColor.init(self)
        }
    }
    var codableColor : CodableColor {
        get {
            return CodableColor(platformColor: self.platformColor)
        }
    }
}

struct CodableColor : Codable {
    var red : CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
    
    var name: String = "Color"
    
    var platformColor : PlatformColor {
        return PlatformColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    init(platformColor : PlatformColor) {
#if os(macOS)
        if let converted = platformColor.usingColorSpace(.deviceRGB) {
            converted.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
#endif
#if os(iOS)
        // Try direct extraction first.
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if platformColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            red = r; green = g; blue = b; alpha = a
        } else if let converted = platformColor.cgColor.converted(
            to: CGColorSpace(name: CGColorSpace.extendedSRGB)!,
            intent: .relativeColorimetric,
            options: nil
        ) {
            let rgb = UIColor(cgColor: converted)
            if rgb.getRed(&r, green: &g, blue: &b, alpha: &a) {
                red = r; green = g; blue = b; alpha = a
            }
        }
        // If both attempts fail (e.g., pattern colors), defaults remain 0.
#endif
    }
    
    var color:Color {
        get {
            return Color(self.platformColor)
        }
    }
}
