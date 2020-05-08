<p align="center">
  <img src="InAppPurchaseLib.png" width="640" title="InAppPurchaseLib">
</p>

InAppPurchaseLib is an easy-to-use library for In-App Purchases, using Fovea.Billing for receipts validation.

- [Features](#features)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Usage](#usage)
  - [Initialization](#initialization)
  - [Purchase a product](#purchase-a-product)
    - [Create an order](#create-an-order)
    - [Processing purchases](#processing-purchases)
      - [Simple case](#simple-case)
      - [Advanced usage](#advanced-usage)
  - [Restore purchases](#restore-purchases)
  - [Purchased products](#purchased-products)
  - [Products list](#products-list)
  - [Display products information](#display-products-information)
  - [Localization](#localization)
  - [Notifications](#notifications)
  - [Purchases information](#purchases-information)
- [Xcode Demo Project](#xcode-demo-project)
- [License](#license)


## Features

* [x] Purchase a product 
* [x] Restore purchased products
* [x] Verify transactions with the App Store on Fovea.Billing server
* [x] Handle and notify payment transaction states
* [x] Retreive products information from the App Store
* [x] Support all product types (consumable, non-consumable, auto-renewable subscription, non-renewing subscription)
* [x] Status of purchases available when offline

## Getting Started

### Requirements
* Configure your App and Xcode to support In-App Purchases.
  * [In-App Purchase Overview](https://developer.apple.com/in-app-purchase)
  * [StoreKit Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)
* Create and configure your [Fovea.Billing](https://billing.fovea.cc) project account:
  * Set your bundle ID
  * The iOS Shared Secret (or shared key) is to be retrieved from [AppStoreConnect](https://appstoreconnect.apple.com/)
  * The iOS Subscription Status URL (only if you want subscriptions)

See our [blog post](https://iridescent.dev/posts/swift/in-app-purchases-ios) (in French) for more information.

### Installation
* [Download](https://github.com/iridescent-dev/iap-swift-lib/archive/master.zip) and extract.
* Drag the `InAppPurchaseLib` folder to your project tree in XCode. When asked, set options as follows:
  * Select *Copy items if needed*.
  * Select *Create groups*.
  * Make sure your project is selected in *add to target*.

## Usage

### Initialization

The library must be initialized as soon as possible in order to process pending transactions. A good way is to call the `start()` method when the application did finish launching.

`InAppPurchase.shared.start()` accepts the following arguments:
* `iapProducts` - An array of **IAPProduct** (REQUIRED)
* `validatorUrlString` - The validator url retrieved from Fovea.Billing (REQUIRED)
* `applicationUsername` - The user name, if your app implements user login (optional)

Each **IAPProduct** contains the following fields:
* `identifier` - The product unique identifier 
* `type` - The product type (`.consumable`, `.nonConsumable`, `.subscription` or `.autoRenewableSubscription`)

**Example**

Add the following lines to your `AppDelegate.swift` file:

``` swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  InAppPurchase.shared.start(
    iapProducts: [
      IAPProduct(identifier: "monthly_plan", type: .autoRenewableSubscription),
      IAPProduct(identifier: "yearly_plan", type: .autoRenewableSubscription)
    ],
    validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=iapdemo&apiKey=12345678-1234-1234-1234-12345678")
  return true
}
```

You should also call the `stop` method when the application will terminate, for proper cleanup.
``` swift
func applicationWillTerminate(_ application: UIApplication) {
  InAppPurchase.shared.stop()
}
```

### Purchase a product
#### Create an order

``` swift
InAppPurchase.shared.purchase(
    product: product, // XXX - Would be simpler to just send the product ID
    callback: { self.loaderView.hide() }
)
```
The `callback` method is called when the purchase has been processed.

**Important**: This callback is not meant to unlock the feature. **purchase processed ≠ purchase successful**

From this callback, you can for example unlock the UI by hiding your loading indicator.

#### Processing purchases

When a purchase is approved, money isn't yet to reach your bank account. You have to acknowledge delivery of the (virtual) item to finalize the transaction.

To achieve this, register an observer for `iapProductPurchased` notifications:
``` swift
NotificationCenter.default.addObserver(self, selector: #selector(productPurchased(_:)), name: .iapProductPurchased, object: nil)
```

Then define your handler:
``` swift
@objc func productPurchased(_ notification: Notification){
  // Get the product from the notification object.
  let product = notification.object as? SKProduct

  if product != nil {
    // Unlock product content here...

    // Finish the product transactions.
    InAppPurchase.shared.finishTransactions(for: product!.productIdentifier)
  }
}
```

##### Simple case

The library stores the last known state of your purchases as [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults). As such, their status is always available to your app, even offline. The `hasActivePurchase()` method allows you to check the status: `InAppPurchase.shared.hasActivePurchase(for: productId)`. In the simplest cases, this is all you need. You can then skip `// Unlock product content here...`.

##### Advanced usage

In more advanced use cases, you have a server component. Users are logged in and you'll like to unlock the content for this user on your server. The safest approach is to setup a [Webhook on Fovea](https://billing.fovea.cc/documentation/webhook/). You'll receive notifications from Fovea that transaction have been processed and/or subscriptions updated.

The information sent from Fovea has been verified from Apple's server, which makes it way more trustable than information sent from your app itself.

To take advantage of this, you have to inform the library of your application username. It can be provided as a parameter of the `start` method (`applicationUsername`) and updated later by changing the following property:
``` swift
InAppPurchase.shared.applicationUsername = applicationUsername
```

In this case, you might want to delay calls to `start()` to when your user's session is ready.

### Restore purchases
Except if you only sell consumable products, Apple requires that you provide a "Restore Purchases" button to your users. In general, from your application settings.

This is the method to call from this button.
``` swift
InAppPurchase.shared.restorePurchases(callback: {
    self.loaderView.hide()
})
```
The `callback` method is called once the operation is complete. You can unlock the UI, by hiding your loader for example.

### Purchased products
As mentioned earlier, the library provides access to the state of your purchases.

Use `hasActivePurchase(for: productId)` to checks if the the user currently own (or is subscribed to) a given product.
``` swift
InAppPurchase.shared.hasActivePurchase(for: productId)
```

### Products list
In order to present to the users your list of purchasable in-app products, you have to load the metadata from the AppStore. This is done for you at startup (so they're immediately available when needed). It is also a good idea to refresh the prices when you show your products view (in case they changed since app startup).

``` swift
class ProductsViewController: UIViewController {
  private var products: [SKProduct] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Load products list.
    self.products = InAppPurchase.shared.getProducts()
    
    // Update products list after retreiving information from the App Store.
    NotificationCenter.default.addObserver(self, selector: #selector(productsRefreshed), name: .iapProductsLoaded, object: nil)
  }
  
  @objc func productsRefreshed() {
    self.products = InAppPurchase.shared.getProducts()
    // Refresh view.
    self.reloadData()
  }
  ...
}
```

### Display products information
All available products are listed in the `InAppPurchase.shared.getProducts()` array of [SKProduct](https://developer.apple.com/documentation/storekit/skproduct).

Those are the most important attributes.

 - `productIdentifier: String` - The string that identifies the product to the Apple App Store.
 - `localizedTitle: String` - The name of the product.
 - `localizedDescription: String` - A description of the product.

The library also extends SKProduct with utility methods.

 - `func getLocalizedCurrentPrice() -> String?` - Current cost of the product, with reduction if available, in the local currency.

For subscription products:

 - `func isSubscription() -> Bool` - The product is a subscription
 - `func isAutoRenewableSubscription() -> Bool` - The product is an auto-renewable subscription.
 - `func hasIntroductoryPriceAvailable() -> Bool` - The product has an introductory price the user is eligible to.
 - `func getLocalizedCurrentPeriod() -> String?` - The current period of the subscription.
 - `func getLocalizedInitialPrice() -> String?` -  The initial cost of the subscription in the local currency.
 - `func getLocalizedInitialPeriod() -> String?` - The initial period of the subscription.
 - `func getLocalizedIntroductoryPricePeriod() -> String?`

**Example**

``` swift
var titleLabel = UILabel()
var priceLabel = UILabel()

// Show product name in Label.
titleLabel.text = product.localizedTitle

// Get localized and formatted price text.
// Example:
// - consumable, non-consumable => 3,99 €
// - auto-renewable subscription, non-renewing subscription => 3,99 € / month
// - auto-renewable subscription with introductory price => 0,99€ / month for 3 months (then 3,99 € / month)
var priceText = ""
if (product.isSubscription()) {
  priceText = "[price] / [period]"
  let period = product.getLocalizedCurrentPeriod()
  priceText = priceText.replacingOccurrences(of: "[period]", with: "\(period ?? "")")
  
  if product.hasIntroductoryPriceAvailable() {
    priceText = "\(priceText) for [promo_period] (then [initial_price] / [initial_period])"
    
    let promoPeriod = product.getLocalizedIntroductoryPricePeriod()
    let initialPrice = product.getLocalizedInitialPrice()
    let initialPeriod = product.getLocalizedInitialPeriod()
    priceText = priceText.replacingOccurrences(of: "[promo_period]", with: "\(promoPeriod ?? "")")
    priceText = priceText.replacingOccurrences(of: "[initial_price]", with: "\(initialPrice ?? "")")
    priceText = priceText.replacingOccurrences(of: "[initial_period]", with: "\(initialPeriod ?? "")")
  }
} else {
  priceText = "[price]"
}
let price = product.getLocalizedCurrentPrice()
priceText = priceText.replacingOccurrences(of: "[price]", with: "\(price ?? "")")

// Show product price in Label.
priceLabel.text = priceText
```

### Localization
The period is in English by default. You can add the following keys in your localization file.
```
// Localizable.strings
"day" = "day";
"days" = "days";
"week" = "week";
"weeks" = "weeks";
"month" = "month";
"months" = "months";
"year" = "year";
"years" = "years";
```

### Notifications
This is the list of notifications published to the by the library to the default NotificationCenter, for different events.

| name                             | description                                                  | notification.object   |
| -------------------------------- | ------------------------------------------------------------ | ----------------------- |
| `iapProductsLoaded`              | Products are loaded from the App Store.                      |                         |
| `iapTransactionFailed`           | The transaction failed.                                      | `SKPaymentTransaction`  |
| `iapTransactionDeferred`         | The transaction is deferred.                                 | `SKPaymentTransaction`  |
| `iapProductPurchased`            | The product is purchased.                                    | `SKProduct`             |
| `iapRefreshReceiptFailed`        | Failed to refresh the App Store receipt.                     | `Error`                 |
| `iapReceiptValidationFailed`     | Failed to validate the App Store receipt with Fovea.Billing. | may contain the `Error` |
| `iapReceiptValidationSuccessful` | The App Store receipt is validated.                          |                         |

For an example of using notifications, check [iapProductPurchased](#processing-purchases).

### Purchases information
For convenience, the library provides some utility functions to check for your past purchases data (date, expiry date) and agregate information (has active subscription, ...).

`hasAlreadyPurchased()` is a handy method that checks if the user has already purchased at least one product.
``` swift
InAppPurchase.shared.hasAlreadyPurchased()
```

`hasActiveSubscription()` checks if the user has an active subscription.
``` swift
InAppPurchase.shared.hasActiveSubscription()
```

`getPurchaseDate(productId)` returns the latest purchased date for a given product (or nil)
``` swift
InAppPurchase.shared.getPurchaseDate(for: productId)
```

`getExpiryDate(productId)` returns the expiry date for an active subcription. It returns nil if the subscription is expired. 
``` swift
InAppPurchase.shared.getExpiryDate(for: productId)
```


## Xcode Demo Project
Do not hesitate to check the demo project available on here: [iap-swift-demo](https://github.com/iridescent-dev/iap-swift-demo).


## License
InAppPurchaseLib is open-sourced library licensed under the MIT License. See [LICENSE](LICENSE) for details.
