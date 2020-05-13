//
//  IAPTransactionObserver.swift
//  InAppPurchaseLib
//
//  Created by Veronique on 30/04/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation
import StoreKit

internal typealias CallbackBlock = () -> Void

class IAPTransactionObserver: NSObject, SKPaymentTransactionObserver {
    
    /* MARK: - Shared instance Adopting the Singleton pattern */
    // - Instance of the class initialized as a static property.
    @objc static let shared = IAPTransactionObserver()
    // - Keep the initializer private so no more instances of the class can be created anywhere in the app.
    private override init() {}
    
    
    /* MARK: - Properties */
    private var callbackBlock: CallbackBlock?
    private var pendingTransactions: Dictionary<String, Array<SKPaymentTransaction>> = [:]
    private var transactionStates: Dictionary<String, SKPaymentTransactionState> = [:]
    private var started: Bool = false
    
    
    /* MARK: - Main methods */
    // Attach an observer to the payment queue.
    @objc func start(){
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
    func purchase(product: SKProduct, quantity: Int, applicationUsername: String?, callback: @escaping CallbackBlock) throws {
        guard canMakePayments() else {
            throw IAPError.cannotMakePurchase
        }
        guard SKPaymentQueue.default().transactions.last?.transactionState != .purchasing else {
            throw IAPError.alreadyPurchasing
        }
        
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        payment.applicationUsername = applicationUsername
        
        self.callbackBlock = callback
        SKPaymentQueue.default().add(payment)
    }
    
    // Restore purchased products.
    func restorePurchases(applicationUsername: String?, callback: @escaping CallbackBlock){
        self.callbackBlock = callback
        SKPaymentQueue.default().restoreCompletedTransactions(withApplicationUsername: applicationUsername)
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
            // Save the transaction state for the product
            transactionStates[transaction.payment.productIdentifier] = transaction.transactionState
            
            switch (transaction.transactionState) {
            case .purchased:
                // Add the transaction to the dictionnary of pending transactions.
                if pendingTransactions[transaction.payment.productIdentifier] == nil {
                    pendingTransactions[transaction.payment.productIdentifier] = []
                }
                pendingTransactions[transaction.payment.productIdentifier]?.append(transaction)
                
                // The content will be unlocked after validation of the receipt.
                InAppPurchase.refreshReceipt()
                
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                
                // Validate the restored purchases.
                InAppPurchase.refreshReceipt()
                
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                
                print("[transaction error] \(transaction.error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .iapTransactionFailed, object: transaction)
                }
                
            case .deferred:
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .iapTransactionDeferred, object: transaction)
                }
                
            case .purchasing:
                break
                
            default:
                break
            }
            
            if transaction.transactionState != .purchasing {
                self.callbackBlock?()
                self.callbackBlock = nil
            }
        }
    }
    
    // All restorable transactions have been processed by the payment queue.
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        // If the user has no transactions to restore,
        // the payment queue will not have received any transactions
        // and the callback method has not been called.
        self.callbackBlock?()
        self.callbackBlock = nil
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iapRestoreCompleted, object: nil)
        }
    }
}
