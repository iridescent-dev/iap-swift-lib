//
//  InAppPurchaseLib.swift
//
//  Created by Veronique on 15/05/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
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
    
    // Returns the last transaction state for a given product.
    static func getTransactionState(for productIdentifier: String) -> SKPaymentTransactionState?
    
    
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
    func productPurchased(identifier: String, callback: @escaping () -> Void) -> Void
}


/* MARK: - IAP Callback */
public typealias IAPPurchaseCallback = (IAPPurchaseResult) -> Void
public struct IAPPurchaseResult {
    var state: IAPPurchaseResultState
    var iapError: IAPError? = nil
    var skError: SKError? = nil
}

public enum IAPPurchaseResultState {
    case purchased
    case failed
    case cancelled
    case deferred
}


public typealias IAPRefreshCallback = (IAPRefreshResult) -> Void
public struct IAPRefreshResult {
    var state: IAPRefreshResultState
    var iapError: IAPError? = nil
    var addedPurchases: Int = 0
    var updatedPurchases: Int = 0
}

public enum IAPRefreshResultState {
    case succeeded
    case failed
}


/* MARK: - IAP Error */
protocol IAPErrorProtocol: LocalizedError {
    var code: IAPErrorCode { get }
}

public enum IAPErrorCode {
    case libraryNotInitialized
    case productNotFound
    case cannotMakePurchase
    case alreadyPurchasing
    
    case bundleIdentifierInvalid
    case validatorUrlInvalid
    case refreshReceiptFailed
    case validateReceiptFailed
    case readReceiptFailed
    
    case refreshProductsFailed
}

public struct IAPError: IAPErrorProtocol {
    public var code: IAPErrorCode
    public var localizedDescription: String {
        switch code {
        case .libraryNotInitialized:
            return NSLocalizedString("You must call the `initialize` fuction before using the library.", comment: "Library Not Initialized")
            
        case .productNotFound:
            return NSLocalizedString("The product was not found on the App Store and cannot be purchased.", comment: "Product Not Found")
        case .cannotMakePurchase:
            return NSLocalizedString("The user is not allowed to authorize payments.", comment: "Cannot Make Purchase")
        case .alreadyPurchasing:
            return NSLocalizedString("A purchase is already in progress.", comment: "Already Purchasing")
            
        case .bundleIdentifierInvalid:
            return NSLocalizedString("Bundle Identifier invalid.", comment: "Bundle Identifier Invalid")
        case .validatorUrlInvalid:
            return NSLocalizedString("Validator URL String invalid.", comment: "Validator URL Invalid")
        case .refreshReceiptFailed:
            return NSLocalizedString("Failed to refresh the App Store receipt.", comment: "Refresh Receipt Failed")
        case .validateReceiptFailed:
            return NSLocalizedString("Failed to validate the App Store receipt with Fovea.", comment: "Validate Receipt Failed")
        case .readReceiptFailed:
            return NSLocalizedString("Failed to read the receipt validation.", comment: "Read Receipt Failed")
            
        case .refreshProductsFailed:
            return NSLocalizedString("Failed to refresh products from the App Store.", comment: "Refresh Products Failed")
        }
    }
}


/* MARK: - IAP Product and Type definition */
public struct IAPProduct {
    public var productIdentifier: String
    public var productType: IAPProductType
}

public enum IAPProductType {
    case consumable
    case nonConsumable
    case nonRenewingSubscription
    case autoRenewableSubscription
}


/* MARK: - SKProduct Extension */
public enum IAPPeriodFormat {
    case short
    case long
}

@available(OSX 10.13.2, *)
@available(iOS 11.2, *)
extension SKProduct {
    public static var localizedPeriodFormat: IAPPeriodFormat = .short
    
    // Checks if the product has an introductory price the user is eligible to.
    public func hasIntroductoryPriceEligible() -> Bool {
        let ineligibleForIntroPriceProductIDs = IAPStorageService.getStringArray(forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY)
        return !ineligibleForIntroPriceProductIDs.contains(productIdentifier) && introductoryPrice != nil
    }
    
    // Returns a localized string with the cost of the product in the local currency.
    public var localizedPrice: String {
        return getLocalizedPrice(locale: priceLocale, price: price)
    }
    
    // Returns a localized string with the period of the subscription product.
    public var localizedSubscriptionPeriod: String? {
        if subscriptionPeriod == nil { return nil }
        return getLocalizedPeriod(unit: subscriptionPeriod!.unit, numberOfUnits: subscriptionPeriod!.numberOfUnits)
    }
    
    // Returns a localized string with the introductory price if available, in the local currency.
    public var localizedIntroductoryPrice: String? {
        if introductoryPrice == nil { return nil }
        return getLocalizedPrice(locale: introductoryPrice!.priceLocale, price: introductoryPrice!.price)
    }
    
    // Returns a localized string with the introductory price period of the subscription product.
    public var localizedIntroductoryPeriod: String? {
        if introductoryPrice == nil { return nil }
        return getLocalizedPeriod(unit: introductoryPrice!.subscriptionPeriod.unit, numberOfUnits: introductoryPrice!.subscriptionPeriod.numberOfUnits)
        
    }
    
    // Returns a localized string with the duration of the introductory price.
    public var localizedIntroductoryDuration: String? {
        if introductoryPrice == nil { return nil }
        let numberOfUnits = introductoryPrice!.subscriptionPeriod.numberOfUnits * introductoryPrice!.numberOfPeriods
        return getLocalizedDuration(unit: introductoryPrice!.subscriptionPeriod.unit, numberOfUnits: numberOfUnits)
    }
    
    /* MARK: - Private method. Returns formatted product Price, Period and Duration. */
    private func getLocalizedPrice(locale: Locale, price: NSDecimalNumber) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price)!
    }
    
    private func getLocalizedPeriod(unit: SKProduct.PeriodUnit, numberOfUnits: Int) -> String? {
        let period = getLocalizedDuration(unit: unit, numberOfUnits: numberOfUnits)
        switch SKProduct.localizedPeriodFormat {
        case .long:
            return period
        case .short:
            return period.replacingOccurrences(of: "^1 ", with: "", options: .regularExpression, range: nil)
        }
    }
    
    private func getLocalizedDuration(unit: SKProduct.PeriodUnit, numberOfUnits: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        formatter.formattingContext = .middleOfSentence
        
        let calendarUnit = unit.toCalendarUnit()
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar.current
        formatter.allowedUnits = [calendarUnit]
        
        switch calendarUnit {
        case .day:
            dateComponents.setValue(numberOfUnits, for: .day)
            if numberOfUnits == 7 {
                formatter.allowedUnits = [.weekOfMonth]
            }
        case .weekOfMonth:
            dateComponents.setValue(numberOfUnits, for: .weekOfMonth)
        case .month:
            dateComponents.setValue(numberOfUnits, for: .month)
            if numberOfUnits == 12 {
                formatter.allowedUnits = [.year]
            }
        case .year:
            dateComponents.setValue(numberOfUnits, for: .year)
        default:
            debugPrint("Unknown period unit")
            return ""
        }
        
        return formatter.string(from: dateComponents)!
    }
}

@available(OSX 10.13.2, *)
@available(iOS 11.2, *)
extension SKProduct.PeriodUnit {
    func toCalendarUnit() -> NSCalendar.Unit {
        switch self {
        case .day: return .day
        case .month: return .month
        case .week: return .weekOfMonth
        case .year: return .year
        @unknown default:
            debugPrint("Unknown period unit")
        }
        return .day
    }
}
