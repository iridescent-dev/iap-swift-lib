//
//  SKProductExtension.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation
import StoreKit


public enum IAPPeriodFormat {
    case short
    case long
}

@available(OSX 10.13.2, *)
@available(iOS 11.2, *)
extension SKProduct {
    public static var localizedPeriodFormat: IAPPeriodFormat = .short
    
    /// Checks if the product has an introductory price the user is eligible to.
    public func hasIntroductoryPriceEligible() -> Bool {
        let ineligibleForIntroPriceProductIDs = IAPStorageService.getStringArray(forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY)
        return !ineligibleForIntroPriceProductIDs.contains(productIdentifier) && introductoryPrice != nil
    }
    
    /// Returns a localized string with the cost of the product in the local currency.
    public var localizedPrice: String {
        return getLocalizedPrice(locale: priceLocale, price: price)
    }
    
    /// Returns a localized string with the period of the subscription product.
    public var localizedSubscriptionPeriod: String? {
        if subscriptionPeriod == nil { return nil }
        return getLocalizedPeriod(unit: subscriptionPeriod!.unit, numberOfUnits: subscriptionPeriod!.numberOfUnits)
    }
    
    /// Returns a localized string with the introductory price if available, in the local currency.
    public var localizedIntroductoryPrice: String? {
        if introductoryPrice == nil { return nil }
        return getLocalizedPrice(locale: introductoryPrice!.priceLocale, price: introductoryPrice!.price)
    }
    
    /// Returns a localized string with the introductory price period of the subscription product.
    public var localizedIntroductoryPeriod: String? {
        if introductoryPrice == nil { return nil }
        return getLocalizedPeriod(unit: introductoryPrice!.subscriptionPeriod.unit, numberOfUnits: introductoryPrice!.subscriptionPeriod.numberOfUnits)
        
    }
    
    /// Returns a localized string with the duration of the introductory price.
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
