//
//  IAPProductService.swift
//
//
//  Created by Veronique on 30/04/2020.
//  Copyright © 2020 Iridescent. All rights reserved.
//

import Foundation
import StoreKit


class IAPProductService: NSObject, SKProductsRequestDelegate {
    
    /* MARK: - Shared instance Adopting the Singleton pattern */
    // - Instance of the class initialized as a static property.
    internal static let shared = IAPProductService()
    // - Keep the initializer private so no more instances of the class can be created anywhere in the app.
    private override init() {}
    
    
    /* MARK: - Properties */
    private var products : Array<SKProduct>?
    private var callbackBlock: IAPRefreshCallback?
    
    
    /* MARK: - Main methods */
    // Load Products from the App Store.
    func refresh(callback: @escaping IAPRefreshCallback){
        self.callbackBlock = callback
        let request = SKProductsRequest.init(productIdentifiers: Set(InAppPurchase.iapProducts.map { $0.productIdentifier }))
        request.delegate = self
        request.start()
    }
    
    // Returns all products retrieved from the App Store.
    func getProducts() -> Array<SKProduct> {
        return self.products ?? []
    }
    
    // Gets the product by its identifier from the list of products retrieved from the App Store.
    func getProductBy(identifier: String) -> SKProduct? {
        return self.products?.filter { $0.productIdentifier.contains(identifier) }.first
    }
    
    // Refresh the list of products ineligible for introductory price.
    func refreshIneligibleForIntroPriceProduct(identifiers: [String]){
        var ineligibleForIntroPriceProductIDs: Set<String> = []
        
        for productIdentifier in identifiers {
            // Checks if the product exists and if it has not already been added to the list.
            if !ineligibleForIntroPriceProductIDs.contains(productIdentifier),
                let product = getProductBy(identifier: productIdentifier) {
                
                // Add the product identifier.
                ineligibleForIntroPriceProductIDs.insert(product.productIdentifier)
                
                if #available(iOS 12.0, *) {
                    if #available(OSX 10.14, *) {
                        if product.subscriptionGroupIdentifier != nil {
                            // Only one introductory offer can be activated within a group of auto-renewable subscriptions.
                            // Add all the identifiers of the group's products.
                            let groupProductIDs = getProducts().filter {
                                $0.subscriptionGroupIdentifier == product.subscriptionGroupIdentifier
                                    && $0.productIdentifier != product.productIdentifier}
                                .map { $0.productIdentifier }
                            
                            ineligibleForIntroPriceProductIDs = ineligibleForIntroPriceProductIDs.union(groupProductIDs)
                        }
                    }
                }
            }
        }
        IAPStorageService.setStringArray(ineligibleForIntroPriceProductIDs.map{$0}, forKey: INELIGIBLE_FOR_INTRO_PRICE_PRODUCT_IDS_KEY)
    }
    
    
    /* MARK: - SKProducts Request Delegate */
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
            self.notifyIsRefreshed(state: .succeeded)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if request is SKProductsRequest {
                self.notifyIsRefreshed(state: .failed)
            }
            print("[product error] \(error.localizedDescription)")
        }
    }
    
    /* MARK: - Private methods. */
    private func notifyIsRefreshed(state: IAPRefreshResultState) {
        self.callbackBlock?(IAPRefreshResult(state: state))
        self.callbackBlock = nil
    }
}
