//
//  IAPProduct.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation


public struct IAPProduct {
    public var productIdentifier: String
    public var productType: IAPProductType
    
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
