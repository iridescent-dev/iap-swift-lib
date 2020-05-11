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
    internal static let versionNumber = "1.0.1"
    
    
    /* MARK: - Properties */
    private static let productService = IAPProductService()
    private static let receiptService = IAPReceiptService()
    
    public static var applicationUsername: String? = nil
    public static var iapProducts: Array<IAPProduct> = []
    
    
    /* MARK: - Main methods */
    // Start In App Purchase services.
    static func initialize(iapProducts: Array<IAPProduct>, validatorUrlString: String, applicationUsername: String? = nil){
        InAppPurchase.applicationUsername = applicationUsername
        InAppPurchase.iapProducts = iapProducts
        
        IAPTransactionObserver.shared.start()
        productService.initialize(productIDs: Set(iapProducts.map { $0.identifier }))
        receiptService.initialize(validatorUrlString: validatorUrlString)
    }
    
    // Stop In App Purchase services.
    static func stop(){
        IAPTransactionObserver.shared.stop()
    }
    
    // Refresh App Store Products and Receipt.
    static func refresh(){
        refreshProducts()
        refreshReceipt()
    }
    
    // Refresh Products from the App Store.
    static func refreshProducts(){
        productService.loadProducts()
    }
    
    // Refresh and validate the App Store Receipt.
    static func refreshReceipt(){
        receiptService.validateReceipt()
    }
    
    
    /* MARK: - Product methods */
    // Returns all products retrieved from the App Store.
    static func getProducts() -> Array<SKProduct> {
        return productService.getProducts()
    }
    
    // Gets the product by its identifier from the list of products retrieved from the App Store.
    static func getProduct(identifier: String) -> SKProduct? {
        return productService.getProduct(identifier: identifier)
    }
    
    // Returns the product type.
    static func getType(for productId: String) -> IAPProductType? {
        return iapProducts.first{ $0.identifier == productId }?.type
    }
    
    
    /* MARK: - Transaction methods */
    // Request a Payment from the App Store.
    static func purchase(productId: String, quantity: Int = 1
        , callback: @escaping CallbackBlock) throws {
        guard let product = productService.getProduct(identifier: productId) else {
            callback()
            throw IAPError.productNotFound
        }
        try IAPTransactionObserver.shared.purchase(product: product, quantity: quantity, applicationUsername: applicationUsername, callback: callback)
    }
    
    // Restore purchased products.
    static func restorePurchases(callback: @escaping CallbackBlock) {
        IAPTransactionObserver.shared.restorePurchases(callback: callback)
    }
    
    // Finish all transactions for the product.
    static func finishTransactions(for productId: String) {
        IAPTransactionObserver.shared.finishTransactions(for: productId)
    }
    
    // Checks if the user is allowed to authorize payments.
    static func canMakePayments() -> Bool {
        return IAPTransactionObserver.shared.canMakePayments()
    }
    
    
    /* MARK: - Receipt methods */
    // Checks if the user has already purchased at least one product.
    static func hasAlreadyPurchased() -> Bool {
        return receiptService.hasAlreadyPurchased()
    }
    
    // Checks if the user currently own (or is subscribed to) a given product.
    static func hasActivePurchase(for productId: String) -> Bool {
        return receiptService.hasActivePurchase(for: productId)
    }
    
    // Checks if the user has an active subscription.
    static func hasActiveSubscription() -> Bool {
        for productId in (iapProducts.filter{ $0.isSubscription() }.map{ $0.identifier }) {
            if receiptService.hasActivePurchase(for: productId){
                return true
            }
        }
        return false;
    }
    
    // Returns the latest purchased date for a given product.
    static func getPurchaseDate(for productId: String) -> Date? {
        return receiptService.getPurchaseDate(for: productId)
    }
    
    // Returns the expiry date for a subcription. May be past or future.
    static func getExpiryDate(for productId: String) -> Date? {
        return receiptService.getExpiryDate(for: productId)
    }
    
    // Returns the expiry date for an active subcription. It returns nil if the subscription is expired.
    static func getNextExpiryDate(for productId: String) -> Date? {
        return receiptService.getNextExpiryDate(for: productId)
    }
}


/*  MARK: - Service notifications. */
extension Notification.Name {
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

/* MARK: - Error */
enum IAPError: Error {
    case productNotFound
}
