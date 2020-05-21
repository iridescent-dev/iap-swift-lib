# Handling purchases
Finally, the magic happened: a user purchased one of your products! Let's see how we handle the different types of products.

- [Non-Consumables](#non-consumables)
- [Auto-Renewable Subscriptions](#auto-renewable-subscriptions)
- [Consumables](#consumables)
- [Non-Renewing Subscriptions](#non-renewing-subscriptions)

<a id="non-consumables"></a> 
## Non-Consumables
Wherever your app needs to know if a non-consumable product has been purchased, use `InAppPurchase.hasActivePurchase(for: 
productIdentifier)`. This will return true if the user currently owns the product.

**Note:** The last known state for the user's purchases is stored as [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults). As such, their status is always available to your app, even when offline.

If you have a server that needs to know about the purchase. You should rely on Fovea's webhook instead of doing anything in here. We will see that later in the [Server integration](server-integration.html) section.

<a id="auto-renewable-subscriptions"></a> 
## Auto-Renewable Subscriptions
As with non-consumables, you will use `InAppPurchase.hasActivePurchase(for: productIdentifier)` to check if the user is an active subscriber to a given product.

You might also like to call refresh regularly, for example when entering your main view. When appropriate, the library will refresh the receipt to detect subscription renewals or expiry.

As we've seend in the [Refreshing](refreshing.html) section:

``` swift
override func viewWillAppear(_ animated: Bool) {
  self.refreshView()
  InAppPurchase.refresh(callback: { _ in
      self.refreshView()
  })
}
```

**Note:** Don't be reluctant to call `refresh()` often. Internally, the library ensures heavy operation are only performed if necessary: for example when a subscription just expired. So in 99% of cases this call will result in no-operations.

<a id="consumables"></a>
## Consumables
If the purchased products in a **consumable**, your app is responsible for delivering the purchase then acknowlege that you've done so. Delivering generally consists in increasing a counter for some sort of virtual currency. 

Your app can be notified of a purchase at any time. So the library asks you to provide an **IAPPurchaseDelegate** from initialization.

In `InAppPurchase.initialize()`, we can pass an **IAPPurchaseDelegate** instance. This object implements the **productPurchased(productIdentifier:)** function, which is called whenever a purchase is approved.

Here's a example implementation:

``` swift
class AppDelegate: UIResponder, UIApplicationDelegate, IAPPurchaseDelegate {
  ...
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    InAppPurchase.initialize(
      iapProducts: [...],
      iapPurchaseDelegate: self, // ADDED: iapPurchaseDelegate
      validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=demo&apiKey=12345678")
  }

  // IAPPurchaseDelegate implementation
  func productPurchased(productIdentifier: String) {
    // TODO
  }
}
```

It's also important to know that when a purchase is approved, money isn't yet to reach your bank account. You have to acknowledge delivery of the (virtual) item to finalize the transaction. That is why we have to call `InAppPurchase.finishTransactions(for: productIdentifier)` as soon as we delivered the product.

**Example**

Let's define a class that adopts the **IAPPurchaseDelegate** protocol, it can very well be your application delegate.

``` swift
func productPurchased(productIdentifier: String) {
  switch productIdenfier {
  case "10_silver":
    addSilver(10)
  case "100_silver":
    addSilver(100)
  }
  InAppPurchase.finishTransactions(for: productIdentifier)
  Analytics.trackEvent("purchase succeeded", productIdentifier)
}
```

Here, we implement our own unlocking logic and call `InAppPurchase.finishTransactions()` afterward (assuming `addSilver` is synchronous).

*Note:* `productPurchased` is called when a purchase has been confirmed by Fovea's receipt validator. If you have a server, he probably already has been notified of this purchase using the webhook.

**Reminder**: Keep in mind that purchase notifications might occur even if you never called the `InAppPurchase.purchase()` function: purchases can be made from another device or the AppStore, they can be approved by parents when the app isn't running, purchase flows can be interupted, etc. The pattern above ensures your app is always ready to handle purchase events.

<a id="non-renewing-subscriptions"></a>
## Non-Renewing Subscriptions
For non-renewing subscriptions, delivering consists in increasing the amount of time a user can access a given feature. Apple doesn't manage the length and expiry of non-renewing subscriptions: you have to do this yourself, as for consumables.

Basically, everything is identical to consumables.
