//
//  IAPTransactionObserver.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation
import StoreKit


class IAPTransactionObserver: NSObject, SKPaymentTransactionObserver {
    
    /* MARK: - Shared instance Adopting the Singleton pattern */
    // - Instance of the class initialized as a static property.
    internal static let shared = IAPTransactionObserver()
    // - Keep the initializer private so no more instances of the class can be created anywhere in the app.
    private override init() {}
    
    
    /* MARK: - Properties */
    private var started: Bool = false
    
    private var callbackBlock: IAPPurchaseCallback?
    private var purchasingProductIdentifier: String?
    
    private var pendingTransactions: Dictionary<String, Array<SKPaymentTransaction>> = [:]
    private var transactionStates: Dictionary<String, SKPaymentTransactionState> = [:]
    
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
        // Make sure the observer is attached to the payment queue.
        start()
        
        return SKPaymentQueue.canMakePayments()
    }
    
    // Request a Payment from the App Store.
    func purchase(product: SKProduct, quantity: Int, applicationUsername: String?, callback: @escaping IAPPurchaseCallback) {
        guard canMakePayments() else {
            callback(IAPPurchaseResult(state: .failed, iapError: IAPError(code: .cannotMakePurchase)))
            return
        }
        guard SKPaymentQueue.default().transactions.last?.transactionState != .purchasing else {
            callback(IAPPurchaseResult(state: .failed, iapError: IAPError(code: .alreadyPurchasing)))
            return
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
                    IAPReceiptService.shared.refreshAfterPurchased(callback: callbackBlock!, purchasingProductIdentifier: productIdentifier)
                    callbackBlock = nil
                    purchasingProductIdentifier = nil
                } else {
                    IAPReceiptService.shared.refresh(callback: {_ in})
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
    private func notifyIsPurchased(for productIdentifier: String, state: IAPPurchaseResultState, iapError: IAPError? = nil, skError: SKError? = nil) {
        DispatchQueue.main.async {
            if (productIdentifier == self.purchasingProductIdentifier) {
                self.callbackBlock?(IAPPurchaseResult(state: state, iapError: iapError, skError: skError))
                self.callbackBlock = nil
                self.purchasingProductIdentifier = nil
            }
        }
    }
}
