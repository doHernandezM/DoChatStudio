//
//  ViewModifiers.swift
//  DoChatStudio
//
//  Created by Cosas on 2/1/25.
//

import SwiftUI

struct DoStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
        
    let hue: Double
    
    func body(content: Content) -> some View {
        
        content
            .background(DoStyle.gradient(hue, colorScheme: colorScheme))
            .shadow(radius: 2)
            .overlay(Circle().fill(Color.clear).strokeBorder(DoStyle.gradient(hue, colorScheme: colorScheme), lineWidth: 5).shadow(radius: 2).rotationEffect(Angle(degrees: 180)))
    }
    
    static func gradient(_ hue: Double = 0.5, colorScheme: ColorScheme) -> LinearGradient {
        let brightnessLight: Double = colorScheme == .dark ? 0.92 : 0.01
        let brightnessDark: Double = colorScheme == .dark ? 0.65 : 0.01
        
        let light = Color.init(hue: hue, saturation: 1.0, brightness: brightnessLight, opacity: 1.0)
        let dark = Color.init(hue: hue, saturation: 1.0, brightness: brightnessDark, opacity: 1.0)
        return LinearGradient(colors: [light, dark], startPoint: .bottomTrailing, endPoint: .topLeading)
    }
    
    static func gradient(color: Color = .orange, transparent: Bool = false, angle: (UnitPoint, UnitPoint) = (.bottomTrailing, .topLeading)) -> LinearGradient {
        let light = color.mix(with: transparent ? .black : .gray, by: 0.1)
        let dark = color.mix(with: .black, by: 0.2)
        return LinearGradient(colors: [light, dark], startPoint: angle.0, endPoint: angle.1)
    }
}

extension Color {
    static var random: Color {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray
        ]
        return colors.randomElement() ?? .black
    }
    
    
}
