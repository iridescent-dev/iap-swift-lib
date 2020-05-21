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
    public internal(set) var state: IAPPurchaseResultState
    public internal(set) var iapError: IAPError? = nil
    public internal(set) var skError: SKError? = nil
    
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
    public internal(set) var state: IAPRefreshResultState
    public internal(set) var iapError: IAPError? = nil
    public internal(set) var addedPurchases: Int = 0
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
