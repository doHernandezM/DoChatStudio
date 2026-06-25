// Retains an experimental custom inspector toggle implementation for future reactivation.

////
////  InspectorToggleView.swift
////  DoChatStudio
////
////  Created by Cosas on 7/13/25.
////
//
//import Foundation
//import SwiftUI
//
//struct InspectorToggleStyle: ToggleStyle {
//    
//    var images: (on: String,off: String)
//    var labels: (on: String,off: String)
//    var activeColor: Color
//    
//    func makeBody(configuration: Configuration) -> some View {
//        GeometryReader{zeo in
//            HStack {
//                Text(labels.on)
//                GeometryReader{geo in
//                    RoundedRectangle(cornerRadius: 30)
//                        .fill(activeColor)
//                        .overlay {
//                            Circle()
//                                .fill(.white)
//                                .frame(width: zeo.size.height * 2, height: zeo.size.height * 2)
//                                .overlay {
//                                    Image(systemName: configuration.isOn ? images.on : images.off)
//                                        .foregroundColor(activeColor)
//                                        .frame(width: zeo.size.height * 3, height: zeo.size.height * 3)
//                                }
//                                .rotationEffect(.degrees(configuration.isOn ? 0 : 720))
//                                .offset(x: configuration.isOn ? (-geo.size.width / 2) + (zeo.size.height / 2) : (geo.size.width / 2) - (zeo.size.height / 2))
//                        }
//                        .frame(height: zeo.size.height * 0.8)
//                }
//                Text(labels.off)
//            }
//        }
//        .padding([.top,. bottom])
//        .contentShape(Rectangle())
//        .onTapGesture {
//            withAnimation(.spring()) {
//                configuration.isOn.toggle()
//            }
//        }
//    }
//}
