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


# Basic Usage
This Swift Package is very quick to install and very easy to use. Let's see the basic usage and go to the [documentation](https://iridescent-dev.github.io/iap-swift-lib/Getting%20Started.html) for more information.

* Initialize the library
``` swift
InAppPurchase.initialize(
    iapProducts: [ IAPProduct(productIdentifier: "my_product", productType: .nonConsumable) ],
    validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=demo&apiKey=12345678"
)
```

* Stop library when the application will terminate
``` swift
InAppPurchase.stop()
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
self.loaderView.show()
InAppPurchase.purchase(
    productIdentifier: "my_product",
    callback: { result in
        self.loaderView.hide()
})
```

* Unlock purchased content
``` swift
if InAppPurchase.hasActivePurchase(for: "my_product") {
    // display content related to the product
}
```

* Restore purchases
``` swift
self.loaderView.show()
InAppPurchase.restorePurchases(
    callback: { result in
        self.loaderView.hide()
})
```

# Documentation
- [Getting Started](https://iridescent-dev.github.io/iap-swift-lib/Getting%20Started.html)
- [Usage](https://iridescent-dev.github.io/iap-swift-lib/Usage.html)
- [API Documentation](https://iridescent-dev.github.io/iap-swift-lib/API%20documentation.html)

**See also**:
- [In-App Purchase Official Documentation](https://developer.apple.com/in-app-purchase)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)

# Xcode Demo Project
Do not hesitate to check the demo project available on here: [iap-swift-lib-demo](https://github.com/iridescent-dev/iap-swift-lib-demo).

# Coding
Generate the documentation, using [Jazzy](https://github.com/realm/jazzy), just by running  `jazzy` from the root of the project.

# Troubleshooting
Common issues are covered here: https://github.com/iridescent-dev/iap-swift-lib/wiki/Troubleshooting

# License
InAppPurchaseLib is open-sourced library licensed under the MIT License. See [LICENSE](LICENSE) for details.
