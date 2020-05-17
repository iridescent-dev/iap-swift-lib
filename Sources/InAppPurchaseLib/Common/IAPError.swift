//
//  IAPError.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation


public protocol IAPErrorProtocol: LocalizedError {
    var code: IAPErrorCode { get }
}

public enum IAPErrorCode {
    case libraryNotInitialized
    case productNotFound
    case cannotMakePurchase
    case alreadyPurchasing
    
    case bundleIdentifierInvalid
    case validatorUrlInvalid
    case refreshReceiptFailed
    case validateReceiptFailed
    case readReceiptFailed
    
    case refreshProductsFailed
}

public struct IAPError: IAPErrorProtocol {
    public var code: IAPErrorCode
    public var localizedDescription: String {
        switch code {
        case .libraryNotInitialized:
            return NSLocalizedString("You must call the `initialize` fuction before using the library.", comment: "Library Not Initialized")
            
        case .productNotFound:
            return NSLocalizedString("The product was not found on the App Store and cannot be purchased.", comment: "Product Not Found")
        case .cannotMakePurchase:
            return NSLocalizedString("The user is not allowed to authorize payments.", comment: "Cannot Make Purchase")
        case .alreadyPurchasing:
            return NSLocalizedString("A purchase is already in progress.", comment: "Already Purchasing")
            
        case .bundleIdentifierInvalid:
            return NSLocalizedString("The Bundle Identifier is invalid.", comment: "Bundle Identifier Invalid")
        case .validatorUrlInvalid:
            return NSLocalizedString("The Validator URL String is invalid.", comment: "Validator URL Invalid")
        case .refreshReceiptFailed:
            return NSLocalizedString("Failed to refresh the App Store receipt.", comment: "Refresh Receipt Failed")
        case .validateReceiptFailed:
            return NSLocalizedString("Failed to validate the App Store receipt with Fovea.", comment: "Validate Receipt Failed")
        case .readReceiptFailed:
            return NSLocalizedString("Failed to read the receipt validation.", comment: "Read Receipt Failed")
            
        case .refreshProductsFailed:
            return NSLocalizedString("Failed to refresh products from the App Store.", comment: "Refresh Products Failed")
        }
    }
}
