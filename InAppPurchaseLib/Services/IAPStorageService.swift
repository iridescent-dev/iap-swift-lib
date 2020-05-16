//
//  IAPStorageService.swift
//  
//
//  Created by Veronique on 13/05/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation


internal let INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY = "ineligibleForIntroPriceProductIDs"
internal let HAS_ALREADY_PURCHASED_KEY = "hasAlreadyPurchased"
internal let PURCHASE_DATE_KEY = "purchase"
internal let EXPIRY_DATE_KEY = "expiry"
internal let NEXT_EXPIRY_DATE_KEY = "nextExpiry"
internal let QUANTITY_KEY = "quantity"
internal let PREFIX_KEY = "iaplib"


internal class IAPStorageService {
    static func getBool(forKey key: String, productIdentifier: String = "") -> Bool {
        return UserDefaults.standard.bool(forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_Bool")
    }
    
    static func setBool(_ value: Bool?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_Bool")
    }
    
    static func getDate(forKey key: String, productIdentifier: String = "") -> Date? {
        return UserDefaults.standard.object(forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_Date") as? Date
    }
    
    static func setDate(_ value: Date?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_Date")
    }
    
    static func getInt(forKey key: String, productIdentifier: String = "") -> Int? {
        return UserDefaults.standard.object(forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_Int") as? Int
    }
    
    static func setInt(_ value: Int?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_Int")
    }
    
    static func getString(forKey key: String, productIdentifier: String = "") -> String? {
        return UserDefaults.standard.object(forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_String") as? String
    }
    
    static func setString(_ value: String?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_String")
    }
    
    static func getStringArray(forKey key: String, productIdentifier: String = "") -> [String] {
        return UserDefaults.standard.object(forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_StringArray") as? [String] ?? [String]()
    }
    
    static func setStringArray(_ value: [String], forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(PREFIX_KEY)_\(productIdentifier)_\(key)_StringArray")
    }
}
