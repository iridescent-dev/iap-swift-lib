//
//  IAPProduct.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation

/// Basic product information used by `InAppPurchase`.
public struct IAPProduct {
    
    /// The identifier of the product.
    public var productIdentifier: String
    
    /// The type of the product.
    /// - See also: `IAPProductType`.
    public var productType: IAPProductType
    
    /// Initializes an `IAPProduct` with its identifier and type.
    /// - Parameters:
    ///   - productIdentifier: The identifier of the product.
    ///   - productType: The type of the product.
    /// - See also: `IAPProductType`.
    public init(productIdentifier: String, productType: IAPProductType) {
        self.productIdentifier = productIdentifier
        self.productType = productType
    }
}

/// Types of in-app purchases.
public enum IAPProductType {
    /// Consumable in-app purchases are used once, are depleted, and can be purchased again.
    case consumable
    /// Non-consumables are purchased once and do not expire.
    case nonConsumable
    /// This type of subscription does not renew automatically, so users need to renew each time.
    case nonRenewingSubscription
    /// Users are charged on a recurring basis until they decide to cancel.
    case autoRenewableSubscription
}
