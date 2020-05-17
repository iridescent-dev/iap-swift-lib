//
//  IAPReceiptService.swift
//
//
//  Created by Iridescent on 30/04/2020.
//

import Foundation
import StoreKit


class IAPReceiptService: NSObject, SKRequestDelegate {
    
    /* MARK: - Shared instance Adopting the Singleton pattern */
    // - Instance of the class initialized as a static property.
    internal static let shared = IAPReceiptService()
    // - Keep the initializer private so no more instances of the class can be created anywhere in the app.
    private override init() {}
    
    
    /* MARK: - Properties */
    private var refreshCallbackBlock: IAPRefreshCallback?
    private var purchaseCallbackBlock: IAPPurchaseCallback?
    private var purchaseProductIdentifier: String?
    
    
    /* MARK: - Main methods */
    // Refresh the App Store Receipt
    func refresh(callback: @escaping IAPRefreshCallback){
        self.refreshCallbackBlock = callback
        refreshReceipt()
    }
    // Refresh the App Store Receipt to validate a purchase.
    func refreshAfterPurchased(callback: @escaping IAPPurchaseCallback, purchasingProductIdentifier: String){
        self.purchaseCallbackBlock = callback
        self.purchaseProductIdentifier = purchasingProductIdentifier
        refreshReceipt()
    }
    
    // Checks if the user has already purchased at least one product.
    func hasAlreadyPurchased() -> Bool{
        return IAPStorageService.getBool(forKey: HAS_ALREADY_PURCHASED_KEY)
    }
    
    // Checks if the user currently own (or is subscribed to) a given product.
    func hasActivePurchase(for productIdentifier: String) -> Bool {
        let productType = InAppPurchase.iapProducts.first{ $0.productIdentifier == productIdentifier }?.productType
        switch productType {
        case .nonConsumable:
            let purchaseDate = getPurchaseDate(for: productIdentifier)
            return purchaseDate != nil
            
        case .autoRenewableSubscription:
            let nextExpiryDate = IAPStorageService.getDate(forKey: NEXT_EXPIRY_DATE_KEY, productIdentifier: productIdentifier)
            return nextExpiryDate != nil && nextExpiryDate! > Date()
            
        default:
            return false
        }
    }
    
    // Returns the latest purchased date for a given product.
    func getPurchaseDate(for productIdentifier: String) -> Date? {
        return IAPStorageService.getDate(forKey: PURCHASE_DATE_KEY, productIdentifier: productIdentifier)
    }
    
    // Returns the quantity purchased for a given product.
    func getPurchasedQuantity(for productIdentifier: String) -> Int? {
        return IAPStorageService.getInt(forKey: QUANTITY_KEY, productIdentifier: productIdentifier)
    }
    
    // Returns the expiry date for a subcription. May be past or future.
    func getExpiryDate(for productIdentifier: String) -> Date? {
        return IAPStorageService.getDate(forKey: EXPIRY_DATE_KEY, productIdentifier: productIdentifier)
    }
    
    // MARK: - SKReceipt Refresh Request Delegate
    func requestDidFinish(_ request: SKRequest) {
        DispatchQueue.main.async {
            if request is SKReceiptRefreshRequest {
                self.validateReceipt()
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if request is SKReceiptRefreshRequest {
                self.notifyFailed(iapErrorCode: .refreshReceiptFailed)
            }
            print("[receipt error] Failed to refresh the receipt: \(error.localizedDescription)")
        }
    }
    
    
    /* MARK: - Private methods. */
    private func refreshReceipt() {
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }
    
    // Validate App Store receipt using Fovea.Billing validator.
    private func validateReceipt(){
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
            refreshReceipt() // validateReceipt will be called again after receipt refreshing finishes.
            return
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            self.notifyFailed(iapErrorCode: .bundleIdentifierInvalid)
            return
        }
        
        guard InAppPurchase.validatorUrlString != nil, let url = URL(string: InAppPurchase.validatorUrlString!) else {
            self.notifyFailed(iapErrorCode: .validatorUrlInvalid)
            return
        }
        
        var platform: String? = nil
        var version: String? = nil
        var model: String? = nil
        #if canImport(UIKit)
        // iOS, tvOS, and watchOS – use UIDevice
        platform = UIDevice.current.systemName
        version = UIDevice.current.systemVersion
        model = UIDevice.current.model
        #elseif canImport(AppKit)
        platform = "macOS"
        #else
        platform = "other"
        #endif
        
        let receiptData = try? Data(contentsOf: appStoreReceiptURL).base64EncodedString()
        let requestData = [
            "id" : bundleIdentifier,
            "type" : "application",
            "device": [
                "plugin": "iridescent-iap-swift-lib/\(InAppPurchase.versionNumber)",
                "platform": platform,
                "version": version,
                "model": model
            ],
            "transaction" : [
                "type" : "ios-appstore",
                "id" : bundleIdentifier,
                "appStoreReceipt" : receiptData
            ],
            "additionalData" : [
                "applicationUsername" : InAppPurchase.applicationUsername ?? nil
            ]
            ] as [String : Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                guard data != nil,
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Dictionary<String, Any> else {
                        self.notifyFailed(iapErrorCode: .validateReceiptFailed)
                        print("[receipt error] Failed to validate the receipt: \(error?.localizedDescription ?? "")")
                        return
                }
                self.parseReceipt(json)
            }
        }.resume()
    }
    
    // Get user purchases informations from Fovea.Billing validator
    // (subscription expiration date, eligibility for introductory price, ...)
    private func parseReceipt(_ json : Dictionary<String, Any>) {
        guard let data = json["data"] as? [String: Any], let collection = data["collection"] as? [[String: Any]] else {
            self.notifyFailed(iapErrorCode: .readReceiptFailed)
            return
        }
        
        IAPProductService.shared.refreshIneligibleForIntroPriceProduct(identifiers: data["ineligible_for_intro_price"] as? [String] ?? [])
        
        IAPStorageService.setBool(!collection.isEmpty, forKey: HAS_ALREADY_PURCHASED_KEY)
        
        var addedPurchases: Int = 0
        var updatedPurchases: Int = 0
        for product in InAppPurchase.iapProducts {
            let productIdentifier = product.productIdentifier
            let purchase = collection.first{ $0["id"] as? String == productIdentifier }
            let oldPurchaseDate = IAPStorageService.getDate(forKey: PURCHASE_DATE_KEY, productIdentifier: productIdentifier)
            
            var purchaseDate: Date? = nil
            var quantity: Int? = nil
            var expiryDate: Date? = nil
            var nextExpiryDate: Date? = nil
            
            if purchase != nil {
                // Save the purchase date.
                let purchaseDateMs = purchase!["purchaseDate"] as? TimeInterval ?? 0
                if  purchaseDateMs != 0 {
                    purchaseDate = Date(timeIntervalSince1970: (purchaseDateMs / 1000.0))
                }
                
                // Save the quantity.
                quantity = purchase!["quantity"] as? Int ?? 1
                
                // Save the expiry date if the product is a non-expired subscription.
                let expiryDateMs = purchase!["expiryDate"] as? TimeInterval ?? 0
                let isExpired = purchase!["isExpired"] as? Bool ?? true
                if  expiryDateMs != 0 {
                    expiryDate = Date(timeIntervalSince1970: (expiryDateMs / 1000.0))
                    if !isExpired {
                        nextExpiryDate = expiryDate
                    }
                }
            }
            
            // Save receipt informations for the product.
            IAPStorageService.setDate(purchaseDate, forKey: PURCHASE_DATE_KEY, productIdentifier: productIdentifier)
            IAPStorageService.setDate(expiryDate, forKey: EXPIRY_DATE_KEY, productIdentifier: productIdentifier)
            IAPStorageService.setDate(nextExpiryDate, forKey: NEXT_EXPIRY_DATE_KEY, productIdentifier: productIdentifier)
            IAPStorageService.setInt(quantity, forKey: QUANTITY_KEY, productIdentifier: productIdentifier)
            
            // If the product has a pending transaction OR is newly purchased/restored and still active.
            if  (purchase != nil && IAPTransactionObserver.shared.hasPendingTransaction(for: productIdentifier))
                || (oldPurchaseDate != purchaseDate && hasActivePurchase(for: productIdentifier)) {
                
                if oldPurchaseDate == nil {
                    addedPurchases+=1
                } else {
                    updatedPurchases+=1
                }
                
                notifyIsPurchased(for: productIdentifier, state: .purchased)
                
                InAppPurchase.iapPurchaseDelegate?.productPurchased(productIdentifier: productIdentifier)
            }
        }
        
        // Notify the end of receipt validation.
        if purchaseProductIdentifier != nil {
            // Purchase product failed: Product is not present in the receipt.
            notifyIsPurchased(for: purchaseProductIdentifier!, state: .failed)
        } else {
            // Refresh successful.
            notifyIsRefreshed(state: .succeeded, addedPurchases: addedPurchases, updatedPurchases: addedPurchases)
        }
    }
    
    private func notifyFailed(iapErrorCode: IAPErrorCode) {
        if refreshCallbackBlock != nil {
            notifyIsRefreshed(state: .failed, iapError: IAPError(code: iapErrorCode))
        } else if purchaseCallbackBlock != nil && purchaseProductIdentifier != nil{
            notifyIsPurchased(for: purchaseProductIdentifier!, state: .failed, iapError: IAPError(code: iapErrorCode))
        }
    }
    
    private func notifyIsRefreshed(state: IAPRefreshResultState, iapError: IAPError? = nil, addedPurchases: Int = 0, updatedPurchases: Int = 0) {
        refreshCallbackBlock?(IAPRefreshResult(
            state: state,
            iapError: iapError,
            addedPurchases: addedPurchases,
            updatedPurchases: addedPurchases))
        refreshCallbackBlock = nil
    }
    
    private func notifyIsPurchased(for productIdentifier: String, state: IAPPurchaseResultState, iapError: IAPError? = nil) {
        if productIdentifier == purchaseProductIdentifier {
            // The product is currently purchasing.
            purchaseCallbackBlock?(IAPPurchaseResult(
                state: state,
                iapError: iapError))
            purchaseCallbackBlock = nil
            purchaseProductIdentifier = nil
        }
    }
}
