<p align="center">
  <img src="https://github.com/iridescent-dev/iap-swift-lib/blob/master/InAppPurchaseLib.png" width="640" title="InAppPurchaseLib">
</p>

InAppPurchaseLib is an easy-to-use library for In-App Purchases, using Fovea.Billing for receipts validation.

- [Features](#features)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Usage](#usage)
  - [Initialization](#initialization)
  - [Displaying products](#displaying-products)
  - [Displaying subscriptions](#displaying-subscriptions)
  - [Refreshing](#refreshing)
  - [Purchasing](#purchasing)
    - [Making a purchase](#making-a-purchase)
    - [Processing purchases](#processing-purchases)
  - [Restoring purchases](#restoring-purchases)
  - [Purchased products](#purchased-products)
  - [Purchases information](#purchases-information)
  - [Errors](#errors)
- [Server integration](#server-integration)
- [Xcode Demo Project](#xcode-demo-project)
- [References](#references)
- [Troubleshooting](#troubleshooting)
- [License](#license)


## Features

* ✅ Purchase a product 
* ✅ Restore purchased products
* ✅ Verify transactions with the App Store on Fovea.Billing server
* ✅ Handle and notify payment transaction states
* ✅ Retreive products information from the App Store
* ✅ Support all product types (consumable, non-consumable, auto-renewable subscription, non-renewing subscription)
* ✅ Status of purchases available when offline
* ✅ Server integration with a Webhook

## Getting Started
If you haven't already, I highly recommend your read the *Overview* and *Preparing* section of Apple's [In-App Purchase official documentation](https://developer.apple.com/in-app-purchase)

### Requirements
* Configure your App and Xcode to support In-App Purchases.
  * [AppStore Connect Setup](https://help.apple.com/app-store-connect/#/devb57be10e7)
* Create and configure your [Fovea.Billing](https://billing.fovea.cc) project account:
  * Set your bundle ID
  * The iOS Shared Secret (or shared key) is to be retrieved from [AppStoreConnect](https://appstoreconnect.apple.com/)
  * The iOS Subscription Status URL (only if you want subscriptions)

### Installation

<p align="center">
  <img src="https://github.com/iridescent-dev/iap-swift-lib/blob/master/ScreenshotInstallation.png" title="Installation">
</p>

* Select your project in Xcode
* Go to the section *Swift Package*
* Click on *(+) Add Package Dependency*
* Copy the Git URL: *https://github.com/iridescent-dev/iap-swift-lib.git*
* Click on *Next* > *Next*
* Make sure your project is selected in *Add to target*
* Click on *Finish*

*Note:* You have to `import InAppPurchaseLib` wherever you use the library.


## Usage

The process of implementing in-app purchases involves several steps:
1. Displaying the list of purchasable products
2. Initiating a purchase
3. Delivering and finalizing a purchase
4. Checking the current ownership of non-consumables and subscriptions
5. Implementing the Restore Purchases button

### Initialization

Before everything else the library must be initialized. This has to happen as soon as possible. A good way is to call the `InAppPurchase.initialize()` method when the application did finish launching. In the background, this will load your products and refresh the status of purchases and subscriptions.

`InAppPurchase.initialize()` accepts the following arguments:
* `iapProducts` - An array of **IAPProduct** (REQUIRED)
* `iapPurchaseDelegate` - A class instance that adopts the **IAPPurchaseDelegate** protocol (REQUIRED) - see [Processing purchases](#processing-purchases)
* `validatorUrlString` - The validator url retrieved from [Fovea](https://billing.fovea.cc) (REQUIRED)
* `applicationUsername` - The user name, if your app implements user login (optional)

Each **IAPProduct** contains the following fields:
* `productIdentifier` - The product unique identifier 
* `productType` - The **IAPProductType** (`consumable`, `nonConsumable`, `nonRenewingSubscription` or `autoRenewableSubscription`)

*Example:*

``` swift
InAppPurchase.initialize(
  iapProducts: [
    IAPProduct(productIdentifier: "monthly_plan", productType: .autoRenewableSubscription),
    IAPProduct(productIdentifier: "yearly_plan",  productType: .autoRenewableSubscription),
    IAPProduct(productIdentifier: "disable_ads",  productType: .nonConsumable)
  ],
  iapPurchaseDelegate: PurchaseDelegate(),
  validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=demo&apiKey=12345678")
```

A good place is generally in your application delegate's `didFinishLaunchingWithOptions` function, like below:

``` swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  // ... initialize here
}
```

You should also call the `stop` method when the application will terminate, for proper cleanup.
``` swift
func applicationWillTerminate(_ application: UIApplication) {
  InAppPurchase.stop()
}
```

For more advanced use cases, in particular when you have implemented user login, see the [Server integration](#server-integration) section.

*Tip:* If initialization was successful, you should see a new receipt validation event in [Fovea's Dashboard](https://billing-dashboard.fovea.cc/events).

### Displaying products
Let's start with the simplest case: you have a single product.

You can retrieve all information about this product using the function `InAppPurchase.getProductBy(identifier: "my_product_id")`. This returns an [SKProduct](https://developer.apple.com/documentation/storekit/skproduct) extended with helpful methods.

Those are the most important:
 - `productIdentifier: String` - The string that identifies the product to the Apple AppStore.
 - `localizedTitle: String` - The name of the product, in the language of the device, as retrieved from the AppStore.
 - `localizedDescription: String` - A description of the product, in the language of the device, as retrieved from the AppStore.
 - `localizedPrice: String` - The cost of the product in the local currency (_read-only property added by this library_).

*Example*:

You can add a function similar to this to your view.

``` swift
@objc func refreshView() {
  guard let product: SKProduct = InAppPurchase.getProductBy(identifier: "my_product_id") else {
    self.titleLabel.text = "Product unavailable"
    return
  }
  self.titleLabel.text = product.localizedTitle
  self.descriptionLabel.text = product.localizedDescription
  self.priceLabel.text = product.localizedPrice
}
```

This example assumes `self.titleLabel` is a UILabel, etc.

Make sure to call this function when the view appears on screen, for instance by calling it from [`viewWillAppear`](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621510-viewwillappear).

``` swift
override func viewWillAppear(_ animated: Bool) {
  self.refreshView()
}
```

### Displaying subscriptions

For subscription products, you also have some data about subscription periods and introductory offers.

 - `func hasIntroductoryPriceEligible() -> Bool` - The product has an introductory price the user is eligible to.
 - `localizedSubscriptionPeriod: String?` - The period of the subscription.
 - `localizedIntroductoryPrice: String?` -  The cost of the introductory offer if available in the local currency.
 - `localizedIntroductoryPeriod: String?` - The subscription period of the introductory offer.
 - `localizedIntroductoryDuration: String?` - The duration of the introductory offer.

**Example**

``` swift
@objc func refreshView() {
  guard let product: SKProduct = InAppPurchase.getProductBy(identifier: "my_product_id") else {
    self.titleLabel.text = "Product unavailable"
    return
  }
  self.titleLabel.text = product.localizedTitle
  self.descriptionLabel.text = product.localizedDescription

  // Format price text. Example: "0,99€ / month for 3 months (then 3,99 € / month)"
  var priceText = "\(product.localizedPrice) / \(product.localizedSubscriptionPeriod!)"
  if product.hasIntroductoryPriceEligible() {
      if product.introductoryPrice!.numberOfPeriods == 1 {
          priceText = "\(product.localizedIntroductoryPrice!) for \(product.localizedIntroductoryDuration!)" +
          " (then \(priceText))"
      } else {
          priceText = "\(product.localizedIntroductoryPrice!) / \(product.localizedIntroductoryPeriod!)" +
          " for \(product.localizedIntroductoryDuration!) (then \(priceText))"
      }
  }
  self.priceLabel.text = priceText
}
```

*Note:* You have to `import StoreKit` wherever you use `SKProduct`.

### Refreshing
Data might change or not be yet available when your "product" view is presented. In order to properly handle those cases, you should refresh your view after refreshing in-app products metadata. You want to be sure you're displaying up-to-date information.

To achieve this, call `InAppPurchase.refresh()` when your view is presented.

``` swift
override func viewWillAppear(_ animated: Bool) {
  self.refreshView()
  InAppPurchase.refresh(callback: { _ in
      self.refreshView()
  })
}
```

### Purchasing
The purchase process is generally a little bit more involving that people would expect. Why is it not just: purchase &rarr; on success unlock the feature?

Several reasons:
- In-app purchases can be initiated outside the app
- In-app purchases can be deferred, pending parental approval
- Apple wants to be sure you delivered the product before charging the user

That is why the process looks like so:
- being ready to handle purchase events from app startup
- finalizing transactions when product delivery is complete
- sending purchase request, for which successful doesn't mean complete

#### Making a purchase
To make a purchase, use the `InAppPurchase.purchase()` function. It takes the `productIdentifier` and a `callback` function, called when the purchase has been processed.

**Important**: Do not process the purchase here, this is the role of your PurchaseDelegate.

From this callback, you can for example unlock the UI by hiding your loading indicator and display the adapted message to the user.

*Example:*
``` swift
self.loaderView.show()
InAppPurchase.purchase(
    productIdentifier: productIdentifier,
    callback: { result in
        self.loaderView.hide()
        switch result.state {
        case .purchased:
            print("Product purchased successful.")
            // Do not process the purchase here
            
        case .failed:
            if result.skError != nil {
                print("Purchase failed: \(result.skError!.localizedDescription).")
                
            } else if result.iapError != nil {
                print("Purchase failed: \(result.iapError!.localizedDescription).")
            }
            
        case .cancelled:
            print("The user canceled the payment request.")
            
        case .deferred:
            print("The purchase was deferred.")
        }
})
```

If the purchase fails, you must have a [`SKError`](https://developer.apple.com/documentation/storekit/skerror/code) or an [`IAPError`](#errors).


#### Processing purchases
When a purchase is approved, money isn't yet to reach your bank account. You have to acknowledge delivery of the (virtual) item to finalize the transaction.

To achieve this, you have to instanciate an instance of class that adopts the **IAPPurchaseDelegate** protocol. This instance  will be provided by calling `InAppPurchase.initialize()`.

Keep in mind that purchase notifications might occur even if you never called the `InAppPurchase.purchase()` function: purchases can be made from another device or the AppStore, they can be approved by parents when the app isn't running, purchase flows can be interupted, etc.

*Example:*

Define the class that adopts the **IAPPurchaseDelegate** protocol:
``` swift
import Foundation
import InAppPurchaseLib

class PurchaseDelegate: IAPPurchaseDelegate {
    required init(){}

    func productPurchased(productIdentifier: String) {
        // Unlock product related content.
        unlockContent(for: productIdentifier)
        
        // Finish the purchase transaction.
        InAppPurchase.finishTransactions(for: productIdentifier)
    }
}
```

In simple cases, you can rely of the library to provide you with information about past purchases and no specific action is needed to unlock the product, just call `InAppPurchase.finishTransactions()`.

The last known state of the user's purchases is stored as [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults). As such, their status is always available to your app, even when offline. The `InAppPurchase.hasActivePurchase(for: productIdentifier)` method lets you to retrieve the ownership status of a product or subscription.

For more advanced use cases, implement your own unlocking logic and call `InAppPurchase.finishTransactions()` afterward.

*Note:* `iapProductPurchased` is emitted when a purchase has been confirmed by Fovea's receipt validator. If you have a server, he probably already has been notified of this purchase using the webhook.

*Tip:* After a successful purchase, you should now see a new transaction in [Fovea's dashboard](https://billing-dashboard.fovea.cc/transactions).

### Restoring purchases
Except if you only sell consumable products, Apple requires that you provide a "Restore Purchases" button to your users. In general, it is found in your application settings.

Call this method when this button is pressed.

``` swift
@IBAction func restorePurchases(_ sender: Any) {
  self.loaderView.show()
  InAppPurchase.restorePurchases(callback: { result in
      self.loaderView.hide()
      switch result.state {
      case .succeeded:
          if result.addedPurchases > 0 {
              print("Restore purchases successful.")
          } else {
              print("No purchase to restore.")
          }
      case .failed:
          print("Restore purchases failed.")
      }
  })
}
```

The `callback` method is called once the operation is complete. You can use it to unlock the UI, by hiding your loader for example, and display the adapted message to the user.

### Purchased products
As mentioned earlier, the library provides access to the state of the users purchases.

Use `InAppPurchase.hasActivePurchase(for: productIdentifier)` to checks if the user currently own (or is subscribed to) a given product (nonConsumable or autoRenewableSubscription).

If you only have auto-renewable subscriptions from the same group, you can use `InAppPurchase.hasActiveSubscription()` to check if the user has an active subscription, regardless of the product identifier.


### Purchases information
For convenience, the library provides some utility functions to check for your past purchases data (date, expiry date) and agregate information (has active subscription, ...).

- `func hasAlreadyPurchased() -> Bool` is a handy method that checks if the user has already purchased at least one product.
  ``` swift
  InAppPurchase.hasAlreadyPurchased()
  ```

- `func hasActivePurchase(for productIdentifier: String) -> Bool` checks if the user currently own (or is subscribed to) a given product (nonConsumable or autoRenewableSubscription).
``` swift
InAppPurchase.hasActivePurchase(for: productIdentifier)
```

- `func hasActiveSubscription() -> Bool` checks if the user has an active subscription.
  ``` swift
  InAppPurchase.hasActiveSubscription()
  ```

- `func getPurchaseDate(for productIdentifier: String) -> Date?` returns the latest purchased date for a given product.
  ``` swift
  InAppPurchase.getPurchaseDate(for: productIdentifier)
  ```

- `func getExpiryDate(for productIdentifier: String) -> Date?` returns the expiry date for a subcription. May be past or future.
  ``` swift
  InAppPurchase.getExpiryDate(for: productIdentifier)
  ```

### Errors

When calling `refresh()`, `purchase()` or `restorePurchases()`, the callback can return an `IAPError` if the state is `failed`.
Here is the list of `IAPErrorCode` you can receive:

* Errors returned by `refresh()`, `purchase()` or `restorePurchases()`
  - `libraryNotInitialized` - You must call the `initialize` fuction before using the library.
  - `bundleIdentifierInvalid` - The Bundle Identifier is invalid.
  - `validatorUrlInvalid` - The Validator URL String is invalid.
  - `refreshReceiptFailed` - Failed to refresh the App Store receipt.
  - `validateReceiptFailed` - Failed to validate the App Store receipt with Fovea.
  - `readReceiptFailed` - Failed to read the receipt validation.

* Errors returned by `refresh()`
  - `refreshProductsFailed` - Failed to refresh products from the App Store.

* Errors returned by `purchase()`
  - `productNotFound` - The product was not found on the App Store and cannot be purchased.
  - `cannotMakePurchase` - The user is not allowed to authorize payments.
  - `alreadyPurchasing` - A purchase is already in progress.


## Server integration

In more advanced use cases, you have a server component. Users are logged in and you'll like to unlock the content for this user on your server. The safest approach is to setup a [Webhook on Fovea](https://billing.fovea.cc/documentation/webhook/). You'll receive notifications from Fovea that transaction have been processed and/or subscriptions updated.

The information sent from Fovea has been verified from Apple's server, which makes it way more trustable than information sent from your app itself.

To take advantage of this, you have to inform the library of your application username. This `applicationUsername` can be provided as a parameter of the `InAppPurchase.initialize` method and updated later by changing the associated property.

*Example:*
``` swift
InAppPurchase.initialize(
  iapProducts: [...],
  validatorUrlString: "..."),
  applicationUsername: UserSession.getUserId())

// later ...
InAppPurchase.applicationUsername = UserSession.getUserId()
```

Of course, in this case, you will want to delay calls to `InAppPurchase.initialize()` to when your user's session is ready.

## Xcode Demo Project
Do not hesitate to check the demo project available on here: [iap-swift-lib-demo](https://github.com/iridescent-dev/iap-swift-lib-demo).

## References
- TODO: API documentation - using https://github.com/swiftdocorg/swift-doc (?)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)

## Troubleshooting
Common issues are covered here: https://github.com/iridescent-dev/iap-swift-lib/wiki/Troubleshooting

## License
InAppPurchaseLib is open-sourced library licensed under the MIT License. See [LICENSE](LICENSE) for details.
