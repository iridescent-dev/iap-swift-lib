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
    internal static let versionNumber = "1.0.2"
    
    
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
        productService.initialize(productIDs: Set(iapProducts.map { $0.productIdentifier }))
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
    static func getProductBy(identifier: String) -> SKProduct? {
        return productService.getProductBy(identifier: identifier)
    }
    
    
    /* MARK: - Transaction methods */
    // Request a Payment from the App Store.
    static func purchase(productIdentifier: String, quantity: Int = 1, callback: @escaping CallbackBlock) throws {
        guard let product = productService.getProductBy(identifier: productIdentifier) else {
            throw IAPError.productNotFound
        }
        try IAPTransactionObserver.shared.purchase(product: product, quantity: quantity, applicationUsername: applicationUsername, callback: callback)
    }
    
    // Restore purchased products.
    static func restorePurchases(callback: @escaping CallbackBlock) {
        IAPTransactionObserver.shared.restorePurchases(applicationUsername: applicationUsername, callback: callback)
    }
    
    // Finish all transactions for the product.
    static func finishTransactions(for productIdentifier: String) {
        IAPTransactionObserver.shared.finishTransactions(for: productIdentifier)
    }
    
    // Checks if the user is allowed to authorize payments.
    static func canMakePayments() -> Bool {
        return IAPTransactionObserver.shared.canMakePayments()
    }
    
    // Returns the last transaction state for a given product.
    static func getTransactionState(for productIdentifier: String) -> SKPaymentTransactionState? {
        return IAPTransactionObserver.shared.getTransactionState(for: productIdentifier)
    }
    
    
    /* MARK: - Receipt methods */
    // Checks if the user has already purchased at least one product.
    static func hasAlreadyPurchased() -> Bool {
        return receiptService.hasAlreadyPurchased()
    }
    
    // Checks if the user currently own (or is subscribed to) a given product (nonConsumable or autoRenewableSubscription).
    static func hasActivePurchase(for productIdentifier: String) -> Bool {
        return receiptService.hasActivePurchase(for: productIdentifier)
    }
    
    // Checks if the user has an active auto renewable subscription.
    static func hasActiveSubscription() -> Bool {
        for productIdentifier in (iapProducts.filter{ $0.productType == IAPProductType.autoRenewableSubscription }.map{ $0.productIdentifier }) {
            if receiptService.hasActivePurchase(for: productIdentifier){
                return true
            }
        }
        return false;
    }
    
    // Returns the latest purchased date for a given product.
    static func getPurchaseDate(for productIdentifier: String) -> Date? {
        return receiptService.getPurchaseDate(for: productIdentifier)
    }
    
    // Returns the expiry date for a subcription. May be past or future.
    static func getExpiryDate(for productIdentifier: String) -> Date? {
        return receiptService.getExpiryDate(for: productIdentifier)
    }
}


/*  MARK: - Service notifications. */
extension Notification.Name {
    // Products are loaded from the App Store.
    static let iapProductsLoaded = Notification.Name("iapProductsLoaded")
    
    // Failed to refresh products from the App Store.
    // notification.object contains the Error.
    static let iapRefreshProductsFailed = Notification.Name("iapRefreshProductsFailed")
    
    // The transaction failed.
    // notification.object contains the SKPaymentTransaction.
    static let iapTransactionFailed = Notification.Name("iapTransactionFailed")
    
    // The transaction is deferred.
    // notification.object contains the SKPaymentTransaction.
    static let iapTransactionDeferred = Notification.Name("iapTransactionDeferred")
    
    // All restorable transactions have been processed.
    static let iapRestoreCompleted = Notification.Name("iapRestoreCompleted")
    
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
    var productIdentifier: String
    var productType: IAPProductType
}

enum IAPProductType {
    case consumable
    case nonConsumable
    case nonRenewingSubscription
    case autoRenewableSubscription
}

/* MARK: - Error */
enum IAPError: Error {
    case productNotFound
    case cannotMakePurchase
    case alreadyPurchasing
}

extension IAPError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .productNotFound:
            return NSLocalizedString("The product was not found on the App Store and cannot be purchased.", comment: "Product Not Found")
        case .cannotMakePurchase:
            return NSLocalizedString("The user is not allowed to authorize payments.", comment: "Cannot Make Purchase")
        case .alreadyPurchasing:
            return NSLocalizedString("A purchase is already in progress.", comment: "Already Purchasing")
        }
    }
}
