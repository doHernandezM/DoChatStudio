//
//  ColorPickerView.swift
//  DoChatStudio
//
//  Created by Cosas on 7/15/25.
//

// Provides entitlement-aware controls for the document's interface and message colors.

import SwiftUI

struct ColorPickerView: View {
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    @Bindable var vm: ChatModel
    
    var body: some View {
        let interfaceColor: Binding<Color> = Binding<Color>(
            get:{Color(vm.style.accent.platformColor)},
            set: { newValue in
                vm.style.interfaceColor = newValue.codableColor
            }
        )
        let agentColor: Binding<Color> = Binding<Color>(
            get:{Color(vm.style.agentColor?.platformColor ?? vm.style.accent.platformColor)},
            set: { newValue in
                vm.style.agentColor = newValue.codableColor
            }
        )
        let userColor: Binding<Color> = Binding<Color>(
            get:{Color(vm.style.userColor?.platformColor ?? vm.style.accent.platformColor)},
            set: { newValue in
                vm.style.userColor = newValue.codableColor
            }
        )
        let backgroundColor: Binding<Color> = Binding<Color>(
            get:{Color(vm.style.backgroundColor?.platformColor ?? .clear)},
            set: { newValue in
                vm.style.backgroundColor = newValue.codableColor
            }
        )
        
        VStack {
            HStack {
                Spacer()
                ColorPicker("Interface", selection: interfaceColor,supportsOpacity: true)
            }
            .help(Text("Sets the main interface color."))
            EntitledControl(){
                HStack {
                    Spacer()
                    ColorPicker(selection: agentColor,supportsOpacity: true)
                    {
                        Text("Agent")
                            .disabled(true)
//                            .foregroundStyle(entitlementManager.hasStudio ? .primary : .secondary)
                    }
                }
                .help(Text("Sets the color for the chat agent."))
            }
            EntitledControl(){
                HStack {
                    Spacer()
                    ColorPicker("User Chat Bubble", selection: userColor,supportsOpacity: true)
                    .foregroundStyle(entitlementManager.hasStudio ? .primary : .secondary)                }
                .help(Text("Sets the user chat bubble color."))
            }
            EntitledControl(){
                HStack {
                    Spacer()
                    ColorPicker("Background", selection: backgroundColor,supportsOpacity: true)
                    .foregroundStyle(entitlementManager.hasStudio ? .primary : .secondary)                }
                .help(Text("Sets the background color."))
            }
        }
    }
}

#Preview {
      let em = EntitlementManager()
      let pm = PurchaseManager(entitlementManager: em)
      return ColorPickerView(vm: ChatModel(mlxService: MLXService()))
          .environmentObject(em)
          .environmentObject(pm)
  }
