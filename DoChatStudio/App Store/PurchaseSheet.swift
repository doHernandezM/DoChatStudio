//
//  PurchaseSheet.swift
//  DoChatStudio
//
//  Created by Cosas on 9/21/25.
//

import SwiftUI
import StoreKit

struct PurchaseSheet: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    var body: some View {
        ZStack(alignment: .topLeading){
            VStack {
                Text("Upgrade to doChat Studio")
                    .font(.largeTitle)
                    .padding()
                ForEach(purchaseManager.products) { product in
                    VStack{
                        HStack{
                            Text(product.displayName)
                                .font(.headline)
                            Text(product.displayPrice)
                                .font(.footnote)
                        }
                        .padding()
                        Text(product.description)
                            .padding()
                        HStack{
                            Spacer()

                            Button {
                                    _ = Task<Void, Never> {
                                        await purchaseManager.restorePurchases()
                                    }
                                } label: {
                                    Text("Restore Purchase")
                                        .padding()
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.green)
                                )
                                .buttonStyle(.glass)
                                Button {
                                    _ = Task<Void, Never> {
                                        do {
                                            try await purchaseManager.purchase(product)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                } label: {
                                    Text("Purchase \(product.displayPrice)")
                                        .padding()
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.blue)
                                )
                                .buttonStyle(.glass)

                            Spacer()
                        }
                    }
                    .padding()
                }
            }
            Button {
                purchaseManager.showPurchaseSheet = false
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
        .task {
            do {
                try await purchaseManager.loadProducts()
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    PurchaseSheet()
}
