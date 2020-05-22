//
//  InAppPurchaseLib.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation
import StoreKit


/// The protocol that `InAppPurchase` adopts.
public protocol InAppPurchaseLib {
    /// The array of `IAPProduct`.
    static var iapProducts: Array<IAPProduct> { get }
    /// The validator url retrieved from Fovea.
    static var validatorUrlString: String? { get }
    /// The instance of class that adopts the `IAPPurchaseDelegate` protocol.
    static var iapPurchaseDelegate: IAPPurchaseDelegate? { get }
    /// The user name, if your app implements user login.
    static var applicationUsername: String? { get set }
    
    /// Start observing the payment queue, as soon as possible, and refresh Product list and user Receipt.
    /// - Parameters:
    ///     - iapProducts: An array of `IAPProduct`.
    ///     - validatorUrlString: The validator url retrieved from Fovea.
    ///     - iapPurchaseDelegate: An instance of class that adopts the `IAPPurchaseDelegate` protocol (default value = `DefaultPurchaseDelegate`).
    ///     - applicationUsername: The user name, if your app implements user login (default value = `nil`).
    static func initialize(iapProducts: Array<IAPProduct>, validatorUrlString: String, iapPurchaseDelegate: IAPPurchaseDelegate, applicationUsername: String?) -> Void
    
    /// Stop observing the payment queue, when the application will terminate, for proper cleanup.
    static func stop() -> Void
    
    /// Refresh Product list and user Receipt.
    /// - Parameter callback: The function that will be called after processing.
    /// - See also:`IAPRefreshResult`
    static func refresh(callback: @escaping IAPRefreshCallback) -> Void
    
    
    /* MARK: - Products information */
    /// Gets all products retrieved from the App Store
    /// - Returns: An array of products.
    /// - See also: `SKProduct`
    static func getProducts() -> Array<SKProduct>
    
    /// Gets the product by its identifier from the list of products retrieved from the App Store.
    /// - Parameter identifier: The identifier of the product.
    /// - Returns: The product if it was retrieved from the App Store.
    /// - See also: `SKProduct`
    static func getProductBy(identifier: String) -> SKProduct?
    
    
    /* MARK: - Purchasing and Restoring */
    /// Checks if the user is allowed to authorize payments.
    /// - Returns: A boolean indicates if the user is allowed.
    static func canMakePayments() -> Bool
    
    /// Request a Payment from the App Store.
    /// - Parameters:
    ///     - productIdentifier: The identifier of the product to purchase.
    ///     - quantity: The quantity to purchase (default value = `1`).
    ///     - callback: The function that will be called after processing.
    /// - See also:`IAPPurchaseResult`
    static func purchase(productIdentifier: String, quantity: Int, callback: @escaping IAPPurchaseCallback) -> Void
    
    /// Restore purchased products.
    /// - Parameter callback: The function that will be called after processing.
    /// - See also:`IAPRefreshResult`
    static func restorePurchases(callback: @escaping IAPRefreshCallback) -> Void
    
    /// Finish all transactions for the product.
    /// - Parameter productIdentifier: The identifier of the product.
    static func finishTransactions(for productIdentifier: String) -> Void
    
    /// Checks if the last transaction state for a given product was deferred.
    /// - Parameter productIdentifier: The identifier of the product.
    /// - Returns: A boolean indicates if the last transaction state was deferred.
    static func hasDeferredTransaction(for productIdentifier: String) -> Bool
    
    
    /* MARK: - Purchases information */
    /// Checks if the user has already purchased at least one product.
    /// - Returns: A boolean indicates if the .
    static func hasAlreadyPurchased() -> Bool
    
    /// Checks if the user currently own (or is subscribed to) a given product (nonConsumable or autoRenewableSubscription).
    /// - Parameter productIdentifier: The identifier of the product.
    /// - Returns: A boolean indicates if the user currently own (or is subscribed to) a given product.
    static func hasActivePurchase(for productIdentifier: String) -> Bool
    
    /// Checks if the user has an active auto renewable subscription regardless of the product identifier.
    /// - Returns: A boolean indicates if the user has an active auto renewable subscription.
    static func hasActiveSubscription() -> Bool
    
    /// Returns the latest purchased date for a given product.
    /// - Parameter productIdentifier: The identifier of the product.
    /// - Returns: The latest purchase `Date` if set  or `nil`.
    static func getPurchaseDate(for productIdentifier: String) -> Date?
    
    /// Returns the expiry date for a subcription. May be past or future.
    /// - Parameter productIdentifier: The identifier of the product.
    /// - Returns: The expiry `Date` is set or `nil`.
    static func getExpiryDate(for productIdentifier: String) -> Date?
}

public extension InAppPurchaseLib {
    /// Sets `DefaultPurchaseDelegate` as default value for `iapPurchaseDelegate` and `nil` for `applicationUsername`.
    static func initialize(iapProducts: Array<IAPProduct>, validatorUrlString: String, iapPurchaseDelegate: IAPPurchaseDelegate = DefaultPurchaseDelegate(), applicationUsername: String? = nil) {
        return initialize(iapProducts: iapProducts, validatorUrlString: validatorUrlString, iapPurchaseDelegate: iapPurchaseDelegate, applicationUsername: applicationUsername)
    }
    
    /// Sets `1` as default value for the `quantity`.
    static func purchase(productIdentifier: String, quantity: Int = 1, callback: @escaping IAPPurchaseCallback) {
        return purchase(productIdentifier: productIdentifier, quantity: quantity, callback: callback)
    }
}


/// The protocol that you must adopt if you have *consumable* and/or *non-renewing subscription* products.
public protocol IAPPurchaseDelegate {
    /// Called when a product is newly purchased, updated or restored.
    /// - Parameter productIdentifier: The identifier of the product.
    ///
    /// - Important: You have to acknowledge delivery of the (virtual) item to finalize the transaction. Then you have to call `InAppPurchase.finishTransactions(for: productIdentifier)`as soon as you have delivered the product.
    func productPurchased(productIdentifier: String) -> Void
}


/// The default implementation of `IAPPurchaseDelegate` if no other is provided. It is enough if you only have *non-consumable* and/or *auto-renewable subscription* products.
public class DefaultPurchaseDelegate: IAPPurchaseDelegate {
    public init(){}
    
    /// Finish the product transactions when a product is newly purchased, updated or restored.
    /// - Parameter productIdentifier: The identifier of the product.
    public func productPurchased(productIdentifier: String) -> Void {
        InAppPurchase.finishTransactions(for: productIdentifier)
    }
}
