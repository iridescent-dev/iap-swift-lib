<p align="center">
  <img src="img/InAppPurchaseLib.png" width="640" title="InAppPurchaseLib">
</p>

_An easy-to-use Swift library for In-App Purchases, using Fovea.Billing for receipts validation._


# Features

* ✅ Purchase a product 
* ✅ Restore purchased products
* ✅ Verify transactions with the App Store on Fovea.Billing server
* ✅ Handle and notify payment transaction states
* ✅ Retreive products information from the App Store
* ✅ Support all product types (consumable, non-consumable, auto-renewable subscription, non-renewing subscription)
* ✅ Status of purchases available when offline
* ✅ Server integration with a Webhook

# Getting Started
If you haven't already, I highly recommend your read the *Overview* and *Preparing* section of Apple's [In-App Purchase official documentation](https://developer.apple.com/in-app-purchase).

## Requirements
* Configure your App and Xcode to support In-App Purchases.
  * [AppStore Connect Setup](https://help.apple.com/app-store-connect/#/devb57be10e7)
* Create and configure your [Fovea.Billing](https://billing.fovea.cc/?ref=iap-swift-lib) project account:
  * Set your bundle ID
  * The iOS Shared Secret (or shared key) is to be retrieved from [AppStoreConnect](https://appstoreconnect.apple.com/)
  * The iOS Subscription Status URL (only if you want subscriptions)

## Installation
* Select your project in Xcode
* Go to the section *Swift Package*
* Click on *(+) Add Package Dependency*
* Copy the Git URL: *https://github.com/iridescent-dev/iap-swift-lib.git*
* Click on *Next*
* In *Rules* select *Version: Up to Next Major ...*
* Click on *Next*
* Make sure your project is selected in *Add to target*
* Click on *Finish*

*Note:* You have to `import InAppPurchaseLib` wherever you use the library.

## Basic Usage

* Initialize the library
``` swift
InAppPurchase.initialize(
  iapProducts: [ IAPProduct(productIdentifier: "my_product", productType: .nonConsumable) ],
  validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=demo&apiKey=12345678"
)
```

* Stop library when the application will terminate
``` swift
func applicationWillTerminate(_ application: UIApplication) {
  InAppPurchase.stop()
}
```

* Display product information
``` swift
guard let product: SKProduct = InAppPurchase.getProductBy(identifier: "my_product") else { return }
productTitleLabel.text = product.localizedTitle
productDescriptionLabel.text = product.localizedDescription
productPriceLabel.text = product.localizedPrice
```

* Initialize a purchase
``` swift
@IBAction func purchase(_ sender: Any) {
  self.loaderView.show()
  InAppPurchase.purchase(
    productIdentifier: "my_product",
    callback: { result in
      self.loaderView.hide()
    })
}
```

* Unlock purchased content
``` swift
if InAppPurchase.hasActivePurchase(for: "my_product") {
  // display content related to the product
}
```

* Restore purchases
``` swift
@IBAction func restorePurchases(_ sender: Any) {
  self.loaderView.show()
  InAppPurchase.restorePurchases(callback: { result in
    self.loaderView.hide()
  })
}
```

# Documentation
- [Getting Started](https://iridescent-dev.github.io/iap-swift-lib/Getting%20Started.html)
- [Usage](https://iridescent-dev.github.io/iap-swift-lib/Usage.html)
- [API documentation](https://iridescent-dev.github.io/iap-swift-lib/API%20documentation.html)

See also:
- [In-App Purchase official documentation](https://developer.apple.com/in-app-purchase)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)

# Xcode Demo Project
Do not hesitate to check the demo project available on here: [iap-swift-lib-demo](https://github.com/iridescent-dev/iap-swift-lib-demo).

# Coding
Generate the documentation, using [Jazzy](https://github.com/realm/jazzy), just by running  `jazzy` from the root of the project.

# Troubleshooting
Common issues are covered here: https://github.com/iridescent-dev/iap-swift-lib/wiki/Troubleshooting

# License
InAppPurchaseLib is open-sourced library licensed under the MIT License. See [LICENSE](LICENSE) for details.
