<p align="center">
  <img src="InAppPurchaseLib.png" width="640" title="InAppPurchaseLib">
</p>

InAppPurchaseLib is an easy-to-use library for In-App Purchases, using Fovea.Billing for receipts validation.

- [Features](#features)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Initialization](#initialization)
- [Usage](#usage)
  - [Purchase a product](#purchase-a-product)
    - [Init purchase transaction](#init-purchase-transaction)
    - [Unlock purchased product and finish transactions](#unlock-purchased-product-and-finish-transactions)
  - [Restore purchased products](#restore-purchased-products)
  - [Identify the purchased content](#identify-the-purchased-content)
  - [Get and refresh the products list](#get-and-refresh-the-products-list)
  - [Display product informations](#display-product-informations)
  - [Localization](#localization)
  - [Notifications](#notifications)
- [Xcode Demo Project](#xcode-demo-project)
- [License](#license)


## Features

* [x] Purchase a product 
* [x] Restore purchased products
* [x] Verify transactions with the App Store on Fovea.Billing server
* [x] Handle and notify payment transaction states
* [x] Retreive products informations from the App Store
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

### Initialization

The library must be initialized as soon as possible in order to process pending transactions.
The best way is to call the `start` method when the application did finish launching.
You should also call the `stop` method when the application will terminate, for proper cleanup.

* Add the following lines to your `AppDelegate.swift` file:

``` swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {   
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Start In App Purchase services
    InAppPurchase.shared.start(
      iapProducts: [
        IAPProduct(identifier: "com.iridescent.iapdemo.monthly_plan", type: .autoRenewableSubscription),
        IAPProduct(identifier: "com.iridescent.iapdemo.yearly_plan", type: .autoRenewableSubscription)
      ],
      validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=iapdemo&apiKey=12345678-1234-1234-1234-12345678")
    return true
  }
    
  func applicationWillTerminate(_ application: UIApplication) {
    InAppPurchase.shared.stop()
  }
}
```

## Usage

### Purchase a product
#### Init purchase transaction
``` swift
InAppPurchase.shared.purchase(
    product: product,
    callback: { self.loaderView.hide() }
)
```
The `callback` method is called once the transaction is complete. You must unlock the UI, by hiding your loader for example.

#### Unlock purchased product and finish transactions
First, you need to register an observer for `iapProductPurchased` notifications:
``` swift
NotificationCenter.default.addObserver(self, selector: #selector(productPurchased(_:)), name: .iapProductPurchased, object: nil)
```

Then you have to define the function you want to call when a notification is observed:
``` swift
@objc func productPurchased(_ notification: Notification){
  // Get the product from the notification object.
  let product = notification.object as? SKProduct

  if product != nil {
    // Unlock product related content.
    ...

    // Finish the product transactions.
    InAppPurchase.shared.finishTransactions(for: product!.productIdentifier)
  }
}
```


### Restore purchased products
``` swift
InAppPurchase.shared.restorePurchases(callback: {
    self.loaderView.hide()
})
```
The `callback` method is called once the transaction is complete. You must unlock the UI, by hiding your loader for example.


### Identify the purchased content
``` swift
// Checks if the user has already purchased at least one product.
InAppPurchase.shared.hasAlreadyPurchased()

// Checks if the product is currently purchased or subscribed.
InAppPurchase.shared.hasActivePurchase(for productId)

// Checks if the user has an active subscription.
InAppPurchase.shared.hasActiveSubscription()

// Returns the purchased date for the product or nil.
InAppPurchase.shared.getPurchaseDate(for productId)

// Returns the expiry date for the product or nil.
// The expiry date is only available if the subscription is not expired.
InAppPurchase.shared.getExpiryDate(for productId)
```


### Get and refresh the products list
``` swift
import UIKit
import StoreKit

class ProductsTableViewController: UITableViewController {
  private var products: [SKProduct] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Load products list.
    self.products = InAppPurchase.shared.getProducts()
    
    // Update products list after retreiving information from the App Store.
    NotificationCenter.default.addObserver(self, selector: #selector(refreshProducts), name: .iapProductsLoaded, object: nil)
  }
  
  @objc func refreshProducts() {
    // Get products retreive from the App Store.
    self.products = InAppPurchase.shared.getProducts()
    // Refresh view.
    tableView.reloadData()
  }
  ...
}
```

### Display product informations
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
The period is in English by default, but you can add the following keys in your localization file.
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
| name                           | description                                                  | notification.object   |
| ------------------------------ | ------------------------------------------------------------ | ----------------------- |
| iapProductsLoaded              | Products are loaded from the App Store.                      |                         |
| iapTransactionFailed           | The transaction failed.                                      | `SKPaymentTransaction`  |
| iapTransactionDeferred         | The transaction is deferred.                                 | `SKPaymentTransaction`  |
| iapProductPurchased            | The product is purchased.                                    | `SKProduct`             |
| iapRefreshReceiptFailed        | Failed to refresh the App Store receipt.                     | `Error`                 |
| iapReceiptValidationFailed     | Failed to validate the App Store receipt with Fovea.Billing. | may contain the `Error` |
| iapReceiptValidationSuccessful | The App Store receipt is validated.                          |                         |

See an example of using notifications: [iapProductPurchased](#unlock-purchased-product-and-finish-transactions).

### Application Username

You can provide the `applicationUsername` as a parameter of the `start` method, or later with the following line:
``` swift
InAppPurchase.shared.applicationUsername = applicationUsername
```

https://developer.apple.com/documentation/storekit/skmutablepayment/1506088-applicationusername?language=objc


## Xcode Demo Project
Do not hesitate to consult the demo project available on GitHub: [iap-swift-demo](https://github.com/iridescent-dev/iap-swift-demo).


## License
InAppPurchaseLib is open-sourced library licensed under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0). See [LICENSE](LICENSE) for details.
