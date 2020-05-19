//
//  InAppPurchaseLib.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation
import StoreKit


/* MARK: - The protocol that InAppPurchase adopts. */
public protocol InAppPurchaseLib {
    static var iapProducts: Array<IAPProduct> { get }
    static var iapPurchaseDelegate: IAPPurchaseDelegate? { get }
    static var validatorUrlString: String? { get }
    static var applicationUsername: String? { get set }
    
    // Start observing the payment queue, as soon as possible, and refresh Product list and user Receipt.
    static func initialize(iapProducts: Array<IAPProduct>, iapPurchaseDelegate: IAPPurchaseDelegate, validatorUrlString: String, applicationUsername: String?)
    
    // Stop observing the payment queue, when the application will terminate, for proper cleanup.
    static func stop()
    
    // Refresh Product list and user Receipt.
    static func refresh(callback: @escaping IAPRefreshCallback)
    
    
    /* MARK: - Products information */
    // Returns all products retrieved from the App Store.
    static func getProducts() -> Array<SKProduct>
    
    // Gets the product by its identifier from the list of products retrieved from the App Store.
    static func getProductBy(identifier: String) -> SKProduct?
    
    
    /* MARK: - Purchasing and Restoring */
    // Checks if the user is allowed to authorize payments.
    static func canMakePayments() -> Bool
    
    // Request a Payment from the App Store.
    static func purchase(productIdentifier: String, quantity: Int, callback: @escaping IAPPurchaseCallback)
    
    // Restore purchased products.
    static func restorePurchases(callback: @escaping IAPRefreshCallback)
    
    // Finish all transactions for the product.
    static func finishTransactions(for productIdentifier: String)
    
    // Checks if the last transaction state for a given product was deferred.
    static func hasDeferredTransaction(for productIdentifier: String) -> Bool
    
    
    /* MARK: - Purchases information */
    // Checks if the user has already purchased at least one product.
    static func hasAlreadyPurchased() -> Bool
    
    // Checks if the user currently own (or is subscribed to) a given product (nonConsumable or autoRenewableSubscription).
    static func hasActivePurchase(for productIdentifier: String) -> Bool
    
    // Checks if the user has an active auto renewable subscription.
    static func hasActiveSubscription() -> Bool
    
    // Returns the latest purchased date for a given product.
    static func getPurchaseDate(for productIdentifier: String) -> Date?
    
    // Returns the expiry date for a subcription. May be past or future.
    static func getExpiryDate(for productIdentifier: String) -> Date?
}

public extension InAppPurchaseLib {
    // Sets default IAPPurchaseDelegate
    static func initialize(iapProducts: Array<IAPProduct>, iapPurchaseDelegate: IAPPurchaseDelegate = DefaultPurchaseDelegate(), validatorUrlString: String, applicationUsername: String? = nil) {
        return initialize(iapProducts: iapProducts, iapPurchaseDelegate: iapPurchaseDelegate, validatorUrlString: validatorUrlString, applicationUsername: applicationUsername)
    }
    
    // Sets 1 as default value for the quantity.
    static func purchase(productIdentifier: String, quantity: Int = 1, callback: @escaping IAPPurchaseCallback) {
        return purchase(productIdentifier: productIdentifier, quantity: quantity, callback: callback)
    }
}


/* MARK: - The protocol that you must adopt. */
public protocol IAPPurchaseDelegate {
    // Initialize the IAPPurchaseDelegate instance.
    init()
    
    // Called when a product is newly purchased, updated or restored.
    func productPurchased(productIdentifier: String)
}


// The default implementation of IAPPurchaseDelegate if no other is provided.
public class DefaultPurchaseDelegate: IAPPurchaseDelegate {
    public required init(){}
    public func productPurchased(productIdentifier: String) {
        // Finish the product transactions.
        InAppPurchase.finishTransactions(for: productIdentifier)
    }
}
