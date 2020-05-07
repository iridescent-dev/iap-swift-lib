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
    
    /* MARK: - Properties */
    private var callbackBlock: CallbackBlock?
    private var pendingTransactions: Dictionary<String, Array<SKPaymentTransaction>> = [:]
    
    
    /* MARK: - Main methods */
    // Attach an observer to the payment queue.
    @objc func start(){
        SKPaymentQueue.default().add(self)
    }
    
    // Remove the observer.
    func stop(){
        SKPaymentQueue.default().remove(self)
    }
    
    // Request a Payment from the App Store.
    func purchase(product: SKProduct, quantity: Int, applicationUsername: String?, callback: @escaping CallbackBlock){
        guard SKPaymentQueue.canMakePayments() else {
            return
        }
        guard SKPaymentQueue.default().transactions.last?.transactionState != .purchasing else {
            return
        }
        
        let payment = SKMutablePayment(product: product)
        payment.quantity = quantity
        payment.applicationUsername = applicationUsername
        
        self.callbackBlock = callback
        SKPaymentQueue.default().add(payment)
    }
    
    // Restore purchased products.
    func restorePurchases(callback: @escaping CallbackBlock){
        self.callbackBlock = callback
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // Finish all transactions for the product.
    func finishTransactions(for productId: String) {
        for transaction in pendingTransactions[productId] ?? [] {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        // Clean the pending transactions list for this product.
        pendingTransactions[productId] = []
    }
    
    
    /* MARK: - SKPayment Transaction Observer */
    // One or more transactions have been updated.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                // The content will be unlocked after validation of the receipt.
                InAppPurchase.shared.receiptService.validateReceipt()
                
                if InAppPurchase.shared.getType(for: transaction.payment.productIdentifier) != IAPProductType.consumable {
                    // For non-consumable and subscription transactions, we can finish
                    // the transaction now as they will always be present in the receipt.
                    SKPaymentQueue.default().finishTransaction(transaction)
                } else {
                    // Consumables must be processed before finishing the transaction.
                    // Add the transaction to the dictionnary of pending transactions.
                    if pendingTransactions[transaction.payment.productIdentifier] == nil {
                        pendingTransactions[transaction.payment.productIdentifier] = []
                    }
                    pendingTransactions[transaction.payment.productIdentifier]?.append(transaction)
                }
                break
                
            case .restored:
                // Validate the restored purchases.
                InAppPurchase.shared.receiptService.validateReceipt()
                SKPaymentQueue.default().finishTransaction(transaction)
                break
                
            case .failed:
                print("[transaction error] \(transaction.error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .iapTransactionFailed, object: transaction)
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                break
                
            case .deferred:
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .iapTransactionDeferred, object: transaction)
                }
                break
                
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
    }
}
