//
//  EntitleControl.swift
//  DoChatStudio
//
//  Created by Cosas on 9/21/25.
//

// Wraps Studio-only controls with entitlement-aware visibility and upgrade behavior.

import SwiftUI

struct EntitledControl<Content: View>: View {
    private let content: () -> Content
    let hideBag: Bool
    
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @AppStorage("showStudioFeatures") private var showStudioFeatures = true

    let productId: PurchasedItem = .studioPurchase
    
    init(hideBag: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.hideBag = hideBag
        self.content = content
    }
    
    var body: some View {
        Group {
            if entitlementManager.hasStudio {
                content()
            } else if !entitlementManager.hasStudio && showStudioFeatures == false {
                EmptyView()
            } else {
                ZStack {
                    HStack {
                        Image(systemName: "bag.fill")
                            .font(.body)
                            .foregroundStyle(.clear)
                            .padding([.leading])
                            .hidden()
                        content()
                            .disabled(true)
                    }
                    .overlay{
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.thinMaterial)
                            .stroke(.ultraThickMaterial, lineWidth: 0.5)
                            .opacity(0.75)
                    }
                    
                    HStack {
                        Image(systemName: "bag.fill")
                            .font(.body)
                            .foregroundStyle(
                                LinearGradient(colors: [
                                    (PlatformColor(named: "Gold")?.color ?? .yellow).opacity(0.47), (PlatformColor(named: "Gold")?.color ?? .yellow)], startPoint: .bottom, endPoint: .top)
                            )
                            .padding([.leading])
                            .opacity(hideBag ? 0 : 1)
                        Spacer()
                    }
                }
                .allowsHitTesting(true)
                .help("Upgrade to doChat Studio to get these features")
                .sheet(isPresented: Binding<Bool>(
                    get: {purchaseManager.showPurchaseSheet}, set: { presentSheet in
                        purchaseManager.showPurchaseSheet = presentSheet}
                )) {
                    PurchaseSheet()
                }
                .onTapGesture {
                    purchaseManager.showPurchaseSheet.toggle()
                }
            }
        }
        .sheet(isPresented: Binding<Bool>(
            get: {purchaseManager.showPurchaseIssue}, set: { presentIssue in
                purchaseManager.showPurchaseIssue = presentIssue}
        )) {
            PurchaseIssue()
        }
    }
}
