//
//  SettingsView.swift
//  DoChatStudio
//
//  Created by Cosas on 9/22/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @AppStorage("showStudioFeatures") private var showStudioFeatures = true

    var body: some View {
        VStack{
            Text("Settings")
                .font(.title)
                .padding()
            Toggle(isOn: Binding<Bool>(get: { showStudioFeatures }, set: { showStudioFeatures = $0 })
            ) {
                Label("Show Studio Features", systemImage: "circle")
            }
            .disabled(entitlementManager.hasStudio)
            .padding()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
