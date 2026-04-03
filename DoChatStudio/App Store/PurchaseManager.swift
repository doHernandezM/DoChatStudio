//
//  PurchaseManager.swift
//  Step10
//
//  Created by Josh Holtz on 9/19/22.
//

import Foundation
import StoreKit
import SwiftUI

typealias PurchasedItem = String

extension PurchasedItem {
    static let studioPurchase: PurchasedItem = "doChat.Studio.01"
}

@MainActor
class PurchaseManager: NSObject, ObservableObject {
    
    private let productIds: [PurchasedItem] = [.studioPurchase]
    
    @Published
    private(set) var products: [Product] = []
    @Published
    private(set) var purchasedProductIDs = Set<String>()
    
    var lastTransaction: StoreKit.Transaction?
    
    @Published
    var showPurchaseSheet:Bool = false
    @Published
    var showPurchaseIssue:Bool = false
    
    @AppStorage("showStudioFeatures") private var showStudioFeatures = true

    private let entitlementManager: EntitlementManager
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil
    private var listener: Task<Void, Never>? = nil
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.updates = observeTransactionUpdates()
        self.listener = observePurchaseIntents()
        
        Task { [weak self] in
            await self?.bootstrap()
        }
    }
    
    deinit {
        self.updates?.cancel()
        self.listener?.cancel()
    }
    
    private func bootstrap() async {
        do {
            try await loadProducts()
            await self.updatePurchasedProducts()
        } catch {
            print(error)
        }
    }
    
    func loadProducts() async throws {
        guard !self.productsLoaded else { return }
        self.products = try await Product.products(for: productIds)
        self.productsLoaded = true
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            await enableStudio(transaction: transaction)
        case let .success(.unverified(transaction, _/*error*/)):
            // Successful purchase but transaction/receipt can't be verified
            // Could be a jailbroken phone
            ConfigurationManager.shared.bannerTitle = "Purchase not verified"
            ConfigurationManager.shared.bannerDescription = "Unable to verify purchase. No charge will be applied."
            
            ConfigurationManager.shared.showBanner = true
            await transaction.finish()
            break
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or
            // approval from Ask to Buy
            ConfigurationManager.shared.bannerTitle = "Waiting for approval"
            ConfigurationManager.shared.bannerDescription = "Your purchase is being reviewed. You will be notified when it is complete."
            ConfigurationManager.shared.showBanner = true
            break
        case .userCancelled:
            // ^^^
            //            await self.updatePurchasedProducts()
            break
        @unknown default:
            break
        }
    }
    
    func updatePurchasedProducts() async {
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
                
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
            
        }
        
        entitlementManager.hasStudio = purchasedProductIDs.contains(PurchasedItem.studioPurchase)
        
    }
    
    private func handle(updatedTransaction verificationResult: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = verificationResult else {
            // Ignore unverified transactions.
            return
        }
        
        if transaction.revocationDate != nil {
            await revok(transaction: transaction)
        } else if let expirationDate = transaction.expirationDate,
                  expirationDate < Date() {
            // Do nothing, this subscription is expired.
            await revok(transaction: transaction)
            return
        } else if transaction.isUpgraded {
            // Do nothing, there is an active transaction
            // for a higher level of service.
            await enableStudio(transaction: transaction)
            return
        } else {
            await enableStudio(transaction: transaction)
            // Provide access to the product identified by
            // transaction.productID.
        }
    }
    
    private func enableStudio(transaction: StoreKit.Transaction) async {
        if transaction.revocationDate != nil {
            await revok(transaction: transaction)
            return
        }
        await self.updatePurchasedProducts()
        showPurchaseSheet = false
        showStudioFeatures = true
        await transaction.finish()
    }
    private func revok(transaction: StoreKit.Transaction) async {
        self.entitlementManager.hasStudio = false
        lastTransaction = transaction
        self.showPurchaseIssue = true
        showStudioFeatures = true
        await transaction.finish()
    }
    
    @MainActor
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("Restore failed: \(error)")
            // Optionally show a banner or alert here.
        }
    }
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in Transaction.updates {
                await self.handle(updatedTransaction: verificationResult)
            }
        }
    }
    
    private func observePurchaseIntents() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await purchaseIntent in PurchaseIntent.intents {
                do {
                    let product = purchaseIntent.product
                        try await self.purchase(product)
                    
                } catch {
                    // Optionally log the error
                    print("Failed to handle purchase intent: \(error)")
                }
            }
        }
    }
}

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults()
    
    @AppStorage("hasStudio", store: userDefaults)
    var hasStudio: Bool = false
}
