//
//  IAPProductService.swift
//  InAppPurchaseLib
//
//  Created by Veronique on 30/04/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation
import StoreKit

private let INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY = "IneligibleForIntroPriceProductIDs"

class IAPProductService: NSObject, SKProductsRequestDelegate {
    
    /* MARK: - Properties */
    @objc private var products : Array<SKProduct>?
    private var productIDs: Set<String> = []
    
    
    /* MARK: - Main methods */
    // Init productIDs list, and load Products from the App Store.
    func start(productIDs: Set<String>){
        self.productIDs = productIDs
        self.loadProducts()
    }
    
    // Load Products from the App Store.
    @objc func loadProducts(){
        let request = SKProductsRequest.init(productIdentifiers: self.productIDs)
        request.delegate = self
        request.start()
    }
    
    // Returns all products retrieved from the App Store.
    func getProducts() -> Array<SKProduct> {
        return self.products ?? []
    }
        
    // Gets the product by its identifier from the list of products retrieved from the App Store.
    func getProduct(identifier: String) -> SKProduct? {
        guard let product = (self.products?.filter { $0.productIdentifier.contains(identifier) }.first) else { return nil }
        return product
    }
    
    // Refresh the list of products ineligible for introductory price.
    func refreshIneligibleForIntroPriceProduct(identifiers: [String]){
        var ineligibleForIntroPriceProductIDs: Set<String> = []
        
        for productId in identifiers {
            // Checks if the product exists and if it has not already been added to the list
            if !ineligibleForIntroPriceProductIDs.contains(productId),
                let product = getProduct(identifier: productId) {
                
                if product.isAutoRenewableSubscription() {
                    // Only one introductory offer can be activated within a group of auto-renewable subscriptions
                    // Add all the identifiers of the group's products
                    let groupProductIDs = self.products?.filter { $0.isAutoRenewableSubscription()
                            && $0.subscriptionGroupIdentifier == product.subscriptionGroupIdentifier }
                        .map { $0.productIdentifier } ?? []
                    
                    ineligibleForIntroPriceProductIDs = ineligibleForIntroPriceProductIDs.union(groupProductIDs)
                    
                } else {
                    // Add the product identifier.
                    ineligibleForIntroPriceProductIDs.insert(product.productIdentifier)
                }
            }
        }
        UserDefaults.standard.set(ineligibleForIntroPriceProductIDs.map{$0}, forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY)
    }
    
    
    /* MARK: - SKProducts Request Delegate */
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iapProductsLoaded, object: nil)
        }
    }
}


extension SKProduct {
    // Checks if the product has a subscription period. This property is nil if the product is not a subscription.
    func isSubscription() -> Bool {
        return subscriptionPeriod != nil
    }
    
    // All auto-renewable subscriptions must be a part of a group. This property is nil if the product is not an auto-renewable subscription.
    func isAutoRenewableSubscription() -> Bool {
        return subscriptionGroupIdentifier != nil
    }
    
    // Checks if the user is eligible and if the product has an introductory price.
    func hasIntroductoryPriceAvailable() -> Bool {
        let ineligibleForIntroPriceProductIDs = UserDefaults.standard.object(forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY) as? [String] ?? [String]()
        return !ineligibleForIntroPriceProductIDs.contains(productIdentifier) && introductoryPrice != nil
    }
    
    // Returns a localized string with the current cost of the product, with reduction if available, in the local currency.
    func getLocalizedCurrentPrice() -> String? {
        if hasIntroductoryPriceAvailable() {
            return getLocalizedPrice(locale: introductoryPrice!.priceLocale, price: introductoryPrice!.price)
        } else {
            return getLocalizedPrice(locale: priceLocale, price: price)
        }
    }
    
    // Returns a localized string with the current period of the subscription product.
    func getLocalizedCurrentPeriod() -> String? {
        if !isSubscription() {
            return ""
        }
        let period = hasIntroductoryPriceAvailable() ? introductoryPrice!.subscriptionPeriod : subscriptionPeriod
        return getLocalizedSubscriptionPeriod(subscriptionPeriod: period)
    }
    
    // Returns a localized string with the initial cost of the product in the local currency.
    func getLocalizedInitialPrice() -> String? {
        return getLocalizedPrice(locale: priceLocale, price: price)
    }
    
    // Returns a localized string with the initial period of the subscription product.
    func getLocalizedInitialPeriod() -> String? {
        return getLocalizedSubscriptionPeriod(subscriptionPeriod: subscriptionPeriod)
    }
    
    func getLocalizedIntroductoryPricePeriod() -> String? {
        if hasIntroductoryPriceAvailable() {
            let numberOfUnits = introductoryPrice!.numberOfPeriods
            let period = getLocalizedPeriod(unit: introductoryPrice?.subscriptionPeriod.unit, numberOfUnits: numberOfUnits)
            return "\(numberOfUnits) \(period)"
        } else {
            return ""
        }
    }
    
    
    /* MARK: - Private method. Returns formatted product Price and Period */
    private func getLocalizedPrice(locale: Locale, price: NSDecimalNumber) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price)
    }
    
    private func getLocalizedSubscriptionPeriod(subscriptionPeriod: SKProductSubscriptionPeriod?) -> String? {
        let numberOfUnits = subscriptionPeriod?.numberOfUnits ?? 1
        let numUnits = numberOfUnits > 1 ? "\(numberOfUnits) " : ""  // Add space for formatting
        let period = getLocalizedPeriod(unit: subscriptionPeriod?.unit, numberOfUnits: numberOfUnits)
        return "\(numUnits)\(period)"
    }
    
    private func getLocalizedPeriod(unit: SKProduct.PeriodUnit?, numberOfUnits: Int) -> String {
        let period:String = {
            switch unit {
            case .day: return numberOfUnits > 1 ? NSLocalizedString("days", comment: "") : NSLocalizedString("day", comment: "")
            case .week: return numberOfUnits > 1 ? NSLocalizedString("weeks", comment: "") : NSLocalizedString("week", comment: "")
            case .month: return numberOfUnits > 1 ? NSLocalizedString("months", comment: "") : NSLocalizedString("month", comment: "")
            case .year: return numberOfUnits > 1 ? NSLocalizedString("years", comment: "") : NSLocalizedString("year", comment: "")
            case .none: return ""
            @unknown default:
                debugPrint("Unknown period unit")
                return ""
            }
        }()
        return period
    }
}
