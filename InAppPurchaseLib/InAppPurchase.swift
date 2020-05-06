//
//  InAppPurchase.swift
//  InAppPurchaseLib
//
//  Created by Veronique on 30/04/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation
import StoreKit


class InAppPurchase: NSObject {
    // InAppPurchaseLib version number
    internal static let versionNumber = "1.0.0"
    
    
    /* MARK: - Shared instance Adopting the Singleton pattern */
    // - Instance of the class initialized as a static property.
    @objc static let shared = InAppPurchase()
    // - Keep the initializer private so no more instances of the class can be created anywhere in the app.
    private override init() {}
    
    
    /* MARK: - Properties */
    internal let transactionObserver = IAPTransactionObserver()
    internal let productService = IAPProductService()
    internal let receiptService = IAPReceiptService()
    
    public var applicationUsername: String? = nil
    public var iapProducts: Array<IAPProduct> = []
    
    
    /* MARK: - Main methods */
    // Start In App Purchase services.
    func start(iapProducts: Array<IAPProduct>, validatorUrlString: String, applicationUsername: String? = nil){
        self.applicationUsername = applicationUsername
        self.iapProducts = iapProducts
        transactionObserver.start()
        productService.start(productIDs: Set(iapProducts.map { $0.identifier }))
        receiptService.start(validatorUrlString: validatorUrlString)
    }
    
    // Stop In App Purchase services.
    func stop(){
        transactionObserver.stop()
    }
    
    
    /* MARK: - Product methods */
    // Returns all products retrieved from the App Store.
    func getProducts() -> Array<SKProduct> {
        return productService.getProducts()
    }
    
    // Gets the product by its identifier from the list of products retrieved from the App Store.
    func getProduct(identifier: String) -> SKProduct? {
        return productService.getProduct(identifier: identifier)
    }
    
    // Returns the product type.
    func getType(for productId: String) -> IAPProductType?{
        return iapProducts.first{ $0.identifier == productId }?.type
    }
    
    
    /* MARK: - Transaction methods */
    // Request a Payment from the App Store.
    func purchase(product: SKProduct, quantity: Int = 1, callback: @escaping CallbackBlock){
        transactionObserver.purchase(product: product, quantity: quantity, applicationUsername: applicationUsername, callback: callback)
    }
    
    // Restore purchased products.
    func restorePurchases(callback: @escaping CallbackBlock){
        transactionObserver.restorePurchases(callback: callback)
    }
    
    // Finish all transactions for the product.
    func finishTransactions(for productId: String) {
        transactionObserver.finishTransactions(for: productId)
    }
    
    
    /* MARK: - Receipt methods */
    // Checks if the user has already purchased.
    func hasAlreadyPurchased() -> Bool{
        return receiptService.hasAlreadyPurchased()
    }
    
    // Returns the purchased date for the product or nil.
    func getPurchaseDate(for productId: String) -> Date?{
        return receiptService.getPurchaseDate(for: productId)
    }
    
    // Returns the expiry date for the product or nil.
    func getExipryDate(for productId: String) -> Date?{
        return receiptService.getExipryDate(for: productId)
    }
    
    // Checks if the product is purchased / subscribed.
    func isPurchased(for productId: String) -> Bool{
        return receiptService.isPurchased(for: productId)
    }
    
    // Checks if the user has an active subscription.
    func hasActiveSubscription() -> Bool{
        for productId in (iapProducts.filter{ $0.isSubscription() }.map{ $0.identifier }) {
            if receiptService.isPurchased(for: productId){
                return true
            }
        }
        return false;
    }
}


/*  MARK: - Service notifications. */
extension Notification.Name{
    // Products are loaded from the App Store.
    static let iapProductsLoaded = Notification.Name("iapProductsLoaded")
    
    // The transaction failed.
    // notification.object contains the SKPaymentTransaction.
    static let iapTransactionFailed = Notification.Name("iapTransactionFailed")
    
    // The transaction is deferred.
    // notification.object contains the SKPaymentTransaction.
    static let iapTransactionDeferred = Notification.Name("iapTransactionDeferred")
    
    // The product is purchased.
    // notification.object contains the SKProduct.
    static let iapProductPurchased = Notification.Name("iapProductPurchased")
    
    // Failed to refresh the App Store receipt.
    // notification.object contains the Error.
    static let iapRefreshReceiptFailed = Notification.Name("iapRefreshReceiptFailed")
    
    // Failed to validate the App Store receipt with Fovea.Billing.
    // notification.object may contain the Error.
    static let iapReceiptValidationFailed = Notification.Name("iapReceiptValidationFailed")
    
    // The the App Store receipt is validated.
    static let iapReceiptValidationSuccessful = Notification.Name("iapReceiptValidationSuccessful")
}


/* MARK: - IAP Product and Type definition. */
struct IAPProduct {
    var identifier: String
    var type: IAPProductType
    
    func isSubscription() -> Bool{
        return type == IAPProductType.autoRenewableSubscription || type == IAPProductType.subscription
    }
}

enum IAPProductType {
    case consumable
    case nonConsumable
    case subscription
    case autoRenewableSubscription
}
