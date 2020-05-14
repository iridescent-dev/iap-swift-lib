//
//  IAPProductService.swift
//  InAppPurchaseLib
//
//  Created by Veronique on 30/04/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation
import StoreKit

private let INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY = "ineligibleForIntroPriceProductIDs"

class IAPProductService: NSObject, SKProductsRequestDelegate {
    
    /* MARK: - Properties */
    private var callbackBlock: IAPRefreshCallback?
    
    private var products : Array<SKProduct>?
    private var productIDs: Set<String> = []
    
    
    /* MARK: - Main methods */
    // Init productIDs list, and load Products from the App Store.
    func initialize(productIDs: Set<String>){
        self.productIDs = productIDs
        self.refresh(callback: {_ in})
    }
    
    // Load Products from the App Store.
    func refresh(callback: @escaping IAPRefreshCallback){
        self.callbackBlock = callback
        let request = SKProductsRequest.init(productIdentifiers: self.productIDs)
        request.delegate = self
        request.start()
    }
    
    // Returns all products retrieved from the App Store.
    func getProducts() -> Array<SKProduct> {
        return self.products ?? []
    }
    
    // Gets the product by its identifier from the list of products retrieved from the App Store.
    func getProductBy(identifier: String) -> SKProduct? {
        return self.products?.filter { $0.productIdentifier.contains(identifier) }.first
    }
    
    // Refresh the list of products ineligible for introductory price.
    func refreshIneligibleForIntroPriceProduct(identifiers: [String]){
        var ineligibleForIntroPriceProductIDs: Set<String> = []
        
        for productIdentifier in identifiers {
            // Checks if the product exists and if it has not already been added to the list
            if !ineligibleForIntroPriceProductIDs.contains(productIdentifier),
                let product = getProductBy(identifier: productIdentifier) {
                
                if product.subscriptionGroupIdentifier != nil {
                    // Only one introductory offer can be activated within a group of auto-renewable subscriptions
                    // Add all the identifiers of the group's products
                    let groupProductIDs = getProducts().filter { $0.subscriptionGroupIdentifier == product.subscriptionGroupIdentifier }
                        .map { $0.productIdentifier }
                    
                    ineligibleForIntroPriceProductIDs = ineligibleForIntroPriceProductIDs.union(groupProductIDs)
                    
                } else {
                    // Add the product identifier.
                    ineligibleForIntroPriceProductIDs.insert(product.productIdentifier)
                }
            }
        }
        IAPStorageService.setStringArray(ineligibleForIntroPriceProductIDs.map{$0}, forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY)
    }
    
    
    /* MARK: - SKProducts Request Delegate */
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        notifyIsRefreshed(state: .succeeded)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            notifyIsRefreshed(state: .failed)
        }
        print("[product error] \(error.localizedDescription)")
    }
    
    /* MARK: - Private methods. */
    private func notifyIsRefreshed(state: IAPRefreshResultState) {
        self.callbackBlock?(IAPRefreshResult(state: state))
        self.callbackBlock = nil
    }
}


/* MARK: - SKProduct Extension */
enum IAPPeriodFormat {
    case short
    case long
}

extension SKProduct {
    static var localizedPeriodFormat: IAPPeriodFormat = .short
    
    // Checks if the product has an introductory price the user is eligible to.
    func hasIntroductoryPriceEligible() -> Bool {
        let ineligibleForIntroPriceProductIDs = IAPStorageService.getStringArray(forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY)
        return !ineligibleForIntroPriceProductIDs.contains(productIdentifier) && introductoryPrice != nil
    }
    
    // Returns a localized string with the cost of the product in the local currency.
    var localizedPrice: String {
        return getLocalizedPrice(locale: priceLocale, price: price)
    }
    
    // Returns a localized string with the period of the subscription product.
    var localizedSubscriptionPeriod: String? {
        if subscriptionPeriod == nil { return nil }
        return getLocalizedPeriod(unit: subscriptionPeriod!.unit, numberOfUnits: subscriptionPeriod!.numberOfUnits)
    }
    
    // Returns a localized string with the introductory price if available, in the local currency.
    var localizedIntroductoryPrice: String? {
        if introductoryPrice == nil { return nil }
        return getLocalizedPrice(locale: introductoryPrice!.priceLocale, price: introductoryPrice!.price)
    }
    
    // Returns a localized string with the introductory price period of the subscription product.
    var localizedIntroductoryPeriod: String? {
        if introductoryPrice == nil { return nil }
        return getLocalizedPeriod(unit: introductoryPrice!.subscriptionPeriod.unit, numberOfUnits: introductoryPrice!.subscriptionPeriod.numberOfUnits)
        
    }
    
    // Returns a localized string with the duration of the introductory price.
    var localizedIntroductoryDuration: String? {
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
