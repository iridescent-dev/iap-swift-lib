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

/// The list of error codes that can be returned by the library.
public enum IAPErrorCode {
    /* MARK: - Errors returned by `refresh()`, `purchase()` or `restorePurchases()` */
    /// You must call the `initialize` fuction before using the library.
    case libraryNotInitialized
    
    /// The Bundle Identifier is invalid.
    case bundleIdentifierInvalid
    
    /// The Validator URL String is invalid.
    case validatorUrlInvalid
    
    /// Failed to refresh the App Store receipt.
    case refreshReceiptFailed
    
    /// Failed to validate the App Store receipt with Fovea.
    case validateReceiptFailed
    
    /// Failed to read the receipt validation.
    case readReceiptFailed
    
    /* MARK: - Errors returned by `refresh()` */
    /// Failed to refresh products from the App Store.
    case refreshProductsFailed
    
    /* MARK: - Errors returned by `purchase()` */
    /// The product was not found on the App Store and cannot be purchased.
    case productNotFound
    
    /// The user is not allowed to authorize payments.
    case cannotMakePurchase
    
    /// A purchase is already in progress.
    case alreadyPurchasing
}

/// When calling `refresh()`, `purchase()` or `restorePurchases()`, the callback can return an `IAPError` if the state is `failed`.
public struct IAPError: IAPErrorProtocol {
    /// The error code.
    /// - See also: `IAPErrorCode`.
    public var code: IAPErrorCode
    
    /// The error description.
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
