# Initialization
Before everything else the library must be initialized. This has to happen as soon as possible. A good way is to call the `InAppPurchase.initialize()` method when the application did finish launching. In the background, this will load your products and refresh the status of purchases and subscriptions.

`InAppPurchase.initialize()` requires the following arguments:
* `iapProducts` - An array of `IAPProduct`
* `validatorUrlString` - The validator url retrieved from [Fovea](https://billing.fovea.cc/?ref=iap-swift-lib)

Each `IAPProduct` contains the following fields:
* `productIdentifier` - The product unique identifier 
* `productType` - The `IAPProductType` (*consumable*, *nonConsumable*, *nonRenewingSubscription* or *autoRenewableSubscription*)

*Example:*

A good place is generally in your application delegate's `didFinishLaunchingWithOptions` function, like below:

``` swift
import InAppPurchaseLib

class AppDelegate: UIResponder, UIApplicationDelegate, IAPPurchaseDelegate {
  ...
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    InAppPurchase.initialize(
      iapProducts: [
        IAPProduct(productIdentifier: "monthly_plan", productType: .autoRenewableSubscription),
        IAPProduct(productIdentifier: "yearly_plan",  productType: .autoRenewableSubscription),
        IAPProduct(productIdentifier: "disable_ads",  productType: .nonConsumable)
      ],
      validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=demo&apiKey=12345678")
  }

  func productPurchased(productIdentifier: String) {
    // ... process purchase (we'll see that later)
  }
}
```

You should also call the `stop` method when the application will terminate, for proper cleanup.
``` swift
  func applicationWillTerminate(_ application: UIApplication) {
    InAppPurchase.stop()
  }
```

For more advanced use cases, in particular when you have implemented user login, you'll have to make some adjustments. We'll learn more about this in the [Server integration](server-integration.html) section.

*Tip:* If initialization was successful, you should see a new receipt validation event in [Fovea's Dashboard](https://billing-dashboard.fovea.cc/events).
