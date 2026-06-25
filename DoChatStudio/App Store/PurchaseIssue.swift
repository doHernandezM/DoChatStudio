//
//  PurchaseIssue.swift
//  DoChatStudio
//
//  Created by Cosas on 9/21/25.
//

// Displays transaction problems and lets the user dismiss or resolve them.

import SwiftUI
import StoreKit

struct PurchaseIssue: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        ZStack(alignment: .topLeading){
            VStack {
                if let transaction: StoreKit.Transaction? = purchaseManager.lastTransaction {
                    if let reason = transaction?.revocationReason {
                        Text("Purchase revoked: \(reason.localizedDescription)")
                            .padding()
                    } else {
                        Text("No revocation reason provided.")
                            .padding()
                    }
                }
            }
            .padding()
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .background(
                RoundedRectangle(cornerRadius:8)
                    .fill(Color.clear)
            )
            Button {
                purchaseManager.showPurchaseIssue = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.circle)
        }
        .padding()
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .background(
            RoundedRectangle(cornerRadius:8)
                .fill(Color.clear)
        )
    }
}
    
#Preview {
    PurchaseIssue()
        .environmentObject(PurchaseManager(entitlementManager: EntitlementManager()))
}
