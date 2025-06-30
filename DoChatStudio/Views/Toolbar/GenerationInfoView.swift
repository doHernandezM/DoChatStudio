//
//  GenerationInfoView.swift
//  MLXChatExample
//
//  Created by İbrahim Çetin on 21.04.2025.
//

import SwiftUI

struct GenerationInfoView: View {
    let tokensPerSecond: Double

    var body: some View {
        HStack{
            Image(systemName:"dollarsign.ring", variableValue:tokensPerSecond)
                .symbolRenderingMode(.palette)
                .foregroundStyle(tokensPerSecond < 0.5 ? .blue.opacity(Double(tokensPerSecond * 2)) : .blue, .tint)
                .font(.system(.largeTitle))
            
            Text("\(tokensPerSecond, format: .number.precision(.fractionLength(2))) tokens/s")
        }
    }
}
//dollarsign.ring
#Preview {
    GenerationInfoView(tokensPerSecond: 58.5834)
}
