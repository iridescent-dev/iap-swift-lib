//
//  IAPCallback.swift
//  
//
//  Created by Veronique on 30/04/2020.
//

import Foundation
import StoreKit


public typealias IAPPurchaseCallback = (IAPPurchaseResult) -> Void
public struct IAPPurchaseResult {
    public internal(set) var state: IAPPurchaseResultState
    public internal(set) var iapError: IAPError? = nil
    public internal(set) var skError: SKError? = nil
}

public enum IAPPurchaseResultState {
    case purchased
    case failed
    case cancelled
    case deferred
}


public typealias IAPRefreshCallback = (IAPRefreshResult) -> Void
public struct IAPRefreshResult {
    public internal(set) var state: IAPRefreshResultState
    public internal(set) var iapError: IAPError? = nil
    public internal(set) var addedPurchases: Int = 0
    public internal(set) var updatedPurchases: Int = 0
}

public enum IAPRefreshResultState {
    case succeeded
    case failed
}
