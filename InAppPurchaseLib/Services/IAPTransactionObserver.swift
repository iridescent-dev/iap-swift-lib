//
//  IAPTransactionObserver.swift
//  InAppPurchaseLib
//
//  Created by Veronique on 30/04/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation
import StoreKit

class IAPTransactionObserver: NSObject, SKPaymentTransactionObserver {
    
    /* MARK: - Shared instance Adopting the Singleton pattern */
    // - Instance of the class initialized as a static property.
    static let shared = IAPTransactionObserver()
    // - Keep the initializer private so no more instances of the class can be created anywhere in the app.
    private override init() {}
    
    
    /* MARK: - Properties */
    private var receiptService: IAPReceiptService?
    private var started: Bool = false
    
    private var callbackBlock: IAPPurchaseCallback?
    private var purchasingProductIdentifier: String?
    
    private var pendingTransactions: Dictionary<String, Array<SKPaymentTransaction>> = [:]
    private var transactionStates: Dictionary<String, SKPaymentTransactionState> = [:]
    
    
    /* MARK: - Main methods */
    // Attach an observer to the payment queue.
    @objc func start(receiptService: IAPReceiptService){
        self.receiptService = receiptService
        if !started {
            SKPaymentQueue.default().add(self)
            started = true
        }
    }
    
    // Remove the observer.
    func stop(){
        SKPaymentQueue.default().remove(self)
    }
    
    // Checks if the user is allowed to authorize payments.
    func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    // Request a Payment from the App Store.
    func purchase(product: SKProduct, quantity: Int, applicationUsername: String?, callback: @escaping IAPPurchaseCallback) throws {
        guard canMakePayments() else {
            throw IAPPurchaseError(code: .cannotMakePurchase)
        }
        guard SKPaymentQueue.default().transactions.last?.transactionState != .purchasing else {
            throw IAPPurchaseError(code: .alreadyPurchasing)
        }
        
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        payment.applicationUsername = applicationUsername
        
        self.callbackBlock = callback
        self.purchasingProductIdentifier = product.productIdentifier
        
        SKPaymentQueue.default().add(payment)
    }
    
    // Checks if the product has a pending transaction.
    func hasPendingTransaction(for productIdentifier: String) -> Bool {
        return pendingTransactions[productIdentifier] != nil && !pendingTransactions[productIdentifier]!.isEmpty
    }
    
    // Finish all transactions for the product.
    func finishTransactions(for productIdentifier: String) {
        for transaction in pendingTransactions[productIdentifier] ?? [] {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        // Clean the pending transactions list for this product.
        pendingTransactions[productIdentifier] = []
    }
    
    // Returns the last transaction state for a given product.
    func getTransactionState(for productIdentifier: String) -> SKPaymentTransactionState? {
        return transactionStates[productIdentifier]
    }
    
    
    /* MARK: - SKPayment Transaction Observer */
    // One or more transactions have been updated.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productIdentifier = transaction.payment.productIdentifier
            
            // Save the transaction state for the product
            transactionStates[productIdentifier] = transaction.transactionState
            
            switch (transaction.transactionState) {
            case .purchased:
                // Add the transaction to the dictionnary of pending transactions.
                if pendingTransactions[productIdentifier] == nil {
                    pendingTransactions[productIdentifier] = []
                }
                pendingTransactions[productIdentifier]?.append(transaction)
                
                // The content will be unlocked after validation of the receipt.
                if (productIdentifier == purchasingProductIdentifier && callbackBlock != nil) {
                    receiptService?.refreshAfterPurchased(callback: callbackBlock!, purchasingProductIdentifier: productIdentifier)
                    callbackBlock = nil
                    purchasingProductIdentifier = nil
                } else {
                    receiptService?.refresh(callback: {_ in})
                }
                
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                print("[transaction error] \(transaction.error?.localizedDescription ?? "")")
                
                // For a list of error constants,
                // see https://developer.apple.com/documentation/storekit/skerror/code
                let skError = (transaction.error as? SKError)!
                switch skError.code {
                case .paymentCancelled:
                    notifyIsPurchased(for: productIdentifier, state: .cancelled)
                default:
                    notifyIsPurchased(for: productIdentifier, state: .failed, skError: skError)
                }
                
            case .deferred:
                notifyIsPurchased(for: productIdentifier, state: .deferred)
                
            case .purchasing:
                break
            default:
                break
            }
        }
    }
    
    /* MARK: - Private method. */
    private func notifyIsPurchased(for productIdentifier: String, state: IAPPurchaseResultState, skError: SKError? = nil) {
        if (productIdentifier == purchasingProductIdentifier) {
            callbackBlock?(IAPPurchaseResult(state: state, errorLocalizedDescription: skError?.localizedDescription, skErrorCode: skError?.code))
            callbackBlock = nil
            purchasingProductIdentifier = nil
        }
    }
}
