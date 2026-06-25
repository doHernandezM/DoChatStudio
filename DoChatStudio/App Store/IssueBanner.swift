//
//  PurchaseIssue.swift
//  DoChatStudio
//
//  Created by Cosas on 9/21/25.
//

// Presents a dismissible in-app banner for purchase and configuration issues.

import SwiftUI
import StoreKit

struct IssueBanner: View {
    @ObservedObject private var config = ConfigurationManager.shared
    
    let title: String
    let description: String
    
    var body: some View {
            HStack {
                Text(config.bannerTitle)
                    .font(.title3)
                    .bold()
                Text(config.bannerDescription)
                    .font(.body)
            }
           
    }
}
    
#Preview {
    PurchaseIssue()
        .environmentObject(PurchaseManager(entitlementManager: EntitlementManager()))
}
