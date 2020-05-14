//
//  IAPStorageService.swift
//  InAppPurchaseLib
//
//  Created by Veronique on 13/05/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation

class IAPStorageService {
    private static let prefix = "iaplib"
    
    static func getBool(forKey key: String, productIdentifier: String = "") -> Bool {
        return UserDefaults.standard.bool(forKey: "\(prefix)_\(productIdentifier)_\(key)_Bool")
    }
    
    static func setBool(_ value: Bool?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(prefix)_\(productIdentifier)_\(key)_Bool")
    }
    
    static func getDate(forKey key: String, productIdentifier: String = "") -> Date? {
        return UserDefaults.standard.object(forKey: "\(prefix)_\(productIdentifier)_\(key)_Date") as? Date
    }
    
    static func setDate(_ value: Date?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(prefix)_\(productIdentifier)_\(key)_Date")
    }
    
    static func getInt(forKey key: String, productIdentifier: String = "") -> Int? {
        return UserDefaults.standard.object(forKey: "\(prefix)_\(productIdentifier)_\(key)_Int") as? Int
    }
    
    static func setInt(_ value: Int?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(prefix)_\(productIdentifier)_\(key)_Int")
    }
    
    static func getString(forKey key: String, productIdentifier: String = "") -> String? {
        return UserDefaults.standard.object(forKey: "\(prefix)_\(productIdentifier)_\(key)_String") as? String
    }
    
    static func setString(_ value: String?, forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(prefix)_\(productIdentifier)_\(key)_String")
    }
    
    static func getStringArray(forKey key: String, productIdentifier: String = "") -> [String] {
        return UserDefaults.standard.object(forKey: "\(prefix)_\(productIdentifier)_\(key)_StringArray") as? [String] ?? [String]()
    }
    
    static func setStringArray(_ value: [String], forKey key: String, productIdentifier: String = "") {
        UserDefaults.standard.set(value, forKey: "\(prefix)_\(productIdentifier)_\(key)_StringArray")
    }
}
