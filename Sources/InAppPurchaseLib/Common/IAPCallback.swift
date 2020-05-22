//
//  IAPCallback.swift
//  
//
//  Created by Veronique on 30/04/2020.
//

import Foundation
import StoreKit


public typealias IAPPurchaseCallback = (IAPPurchaseResult) -> Void

/// The result returned in the `purchase()` callback.
public struct IAPPurchaseResult {
    /// The result state.
    public internal(set) var state: IAPPurchaseResultState
    
    /// If the state is `failed`, the result can return an `IAPError`.
    /// The error occurred during the processing of the purchase by the library.
    public internal(set) var iapError: IAPError? = nil
    
    /// If the state is `failed`, the result can return an `SKError`.
    /// The error occurred during the processing of the purchase by the App Store.
    public internal(set) var skError: SKError? = nil
    
    /// If there is an error, return the localized description.
    /// - See also: `IAPError` and `SKError`.
    public var localizedDescription: String? {
        if skError != nil { return skError!.localizedDescription }
        if iapError != nil { return iapError!.localizedDescription }
        return nil
    }
}

/// The list of the different states of the `IAPPurchaseResult`.
public enum IAPPurchaseResultState {
    /// The purchase was successful.
    case purchased
    
    /// Puchase failed.
    case failed
    
    /// The purchase was cancelled by the user.
    case cancelled
    
    /// The purchase is deferred.
    case deferred
}


public typealias IAPRefreshCallback = (IAPRefreshResult) -> Void

/// The result returned in the `refresh()` or `restorePurchases()` callback.
public struct IAPRefreshResult {
    /// The result state.
    public internal(set) var state: IAPRefreshResultState
    
    /// If the state is `failed`, the result can return an `IAPError`.
    /// The error occurred during the processing of the purchase by the library.
    public internal(set) var iapError: IAPError? = nil
    
    /// If the state is `succeeded`, returns the number of purchases that have been added.
    public internal(set) var addedPurchases: Int = 0
    
    /// If the state is `succeeded`, returns the number of purchases that have been updated.
    public internal(set) var updatedPurchases: Int = 0
}

/// The list of the different states of the `IAPRefreshResult`.
public enum IAPRefreshResultState {
    /// Refresh was successful.
    case succeeded
    
    /// Refresh failed.
    case failed
    
    /// Refresh has been skipped because it is not necessary.
    case skipped
}
