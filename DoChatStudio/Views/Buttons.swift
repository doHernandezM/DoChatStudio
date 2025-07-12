//
//  Buttons.swift
//  DoChatStudio
//
//  Created by Cosas on 7/3/25.
//

import SwiftUI

struct MovingDashPhaseButton: View {
    
    @State var isMovingAround:Bool
    @Binding var secondaryColor:Color
    
    let action: (/*_ model:DoModel*/) -> ()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 27)
                .frame(width: 160, height: 54)
                .foregroundStyle(.indigo.gradient)
            RoundedRectangle(cornerRadius: 27)
                .strokeBorder(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [40, 400], dashPhase: isMovingAround ? 220 : -220))
                .frame(width: 160, height: 54)
                .foregroundStyle(
                    //RadialGradient(gradient: Gradient(colors: [.white, .indigo, .indigo]), center: .bottom, startRadius: 60, endRadius: 100)
                    LinearGradient(gradient: Gradient(colors: [secondaryColor, .transparentAccent, secondaryColor]), startPoint: .trailing, endPoint: .leading)
                )
                .shadow(radius: 2)
                .animation(
                          .linear.speed(0.1).repeatForever(autoreverses:false),
                          value: isMovingAround
                        )
            Button {
                withAnimation{
                    action()
                }
            } label: {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
                .bold()
            }
            .buttonStyle(.plain)
        }
//        .onAppear {
//            withAnimation(.linear.speed(0.1).repeatForever(autoreverses: false)) {
//                isMovingAround.toggle()
//            }
//        }
    }
}

#Preview {
    MovingDashPhaseButton(isMovingAround: (true), secondaryColor: .constant(Color.white), action: {return})
        .preferredColorScheme(.dark)
}
