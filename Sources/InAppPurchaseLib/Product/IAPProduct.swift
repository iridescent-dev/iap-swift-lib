//
//  IAPProduct.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation


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

public enum IAPProductType {
    case consumable
    case nonConsumable
    case nonRenewingSubscription
    case autoRenewableSubscription
}
