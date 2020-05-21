# Analytics
Tracking the purchase flow is a common things in apps. Especially as it's core to your revenue model.

We can track 5 events, which step in the purchase pipeline a user reached.
1. `purchase initiated`
2. `purchase cancelled`
3. `purchase failed`
4. `purchase deferred`
5. `purchase succeeded`

Here's a quick example showing how to implement this correctly.

``` swift
func makePurchase() {
  Analytics.trackEvent("purchase initiated")
  InAppPurchase.purchase(
    productIdentifier: "my_product_id",
    callback: { result in
      switch result.state {
      case .purchased:
        // Reminder: We are not processing the purchase here, only updating your UI.
        //           That's why we do not send an event to analytics.
      case .failed:
        Analytics.trackEvent("purchase failed")
      case .deferred:
        Analytics.trackEvent("purchase deferred")
      case .cancelled:
        Analytics.trackEvent("purchase cancelled")
    }
  })
}

// IAPPurchaseDelegate implementation
func productPurchased(productIdentifier: String) {
  Analytics.trackEvent("purchase succeeded")
  InAppPurchase.finishTransactions(for: productIdentifier)
}
```

The important part to remember is that a purchase can occur outside your app (or be approved when the app is not running), that's why tracking `purchase succeeded` has to be part of the `productPurchased` delegate function.
 
Refer to the [Consumables](handling-purchases.html#consumables) section to learn more about the `productPurchased` function.
