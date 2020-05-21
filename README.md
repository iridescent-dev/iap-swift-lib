<p align="center">
  <img src="img/InAppPurchaseLib.png" width="640" title="InAppPurchaseLib">
</p>

> An easy-to-use Swift library for In-App Purchases, using Fovea.Billing for receipts validation.


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

## Installation
* Select your project in Xcode
* Go to the section *Swift Package*
* Click on *(+) Add Package Dependency*
* Copy the Git URL: *https://github.com/iridescent-dev/iap-swift-lib.git*
* Click on *Next* > *Next*
* Make sure your project is selected in *Add to target*
* Click on *Finish*

*Note:* You have to `import InAppPurchaseLib` wherever you use the library.

## Micro Example

```swift
/** AppDelegate.swift */
import UIKit
import InAppPurchaseLib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Initialize the library
    InAppPurchase.initialize(
      iapProducts: [
        IAPProduct(productIdentifier: "my_product", productType: .nonConsumable)
      ],
      validatorUrlString: "https://validator.fovea.cc/v1/validate?appName=demo&apiKey=12345678"
    )
    return true
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // clean
    InAppPurchase.stop()
  }
}
```

```swift
/** ViewController.swift */
import UIKit
import StoreKit
import InAppPurchaseLib

class ViewController: UIViewController {
  private var loaderView = LoaderView()
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var productTitleLabel: UILabel!
  @IBOutlet weak var productDescriptionLabel: UILabel!
  @IBOutlet weak var purchaseButton: UIButton!
  @IBOutlet weak var restorePurchasesButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Add action for purchases and restore butons.
    purchaseButton.addTarget(self, action: #selector(self.purchase), for: .touchUpInside)
    restorePurchasesButton.addTarget(self, action: #selector(self.restorePurchases), for: .touchUpInside)
  }

  override func viewWillAppear(_ animated: Bool) {
    self.refreshView()
    InAppPurchase.refresh(callback: { _ in
      self.refreshView()
    })
  }

  func refreshView() {
    guard let product: SKProduct = InAppPurchase.getProductBy(identifier: "my_product") else {
      self.productTitleLabel.text = "Product unavailable"
      return
    }
    // Display product information.
    productTitleLabel.text = product.localizedTitle
    productDescriptionLabel.text = product.localizedDescription
    purchaseButton.setTitle(product.localizedPrice, for: .normal)
        
    // Disable the button if the product has already been purchased.
    if InAppPurchase.hasActivePurchase(for: "my_product") {
      statusLabel.text = "OWNED"
      purchaseButton.isPointerInteractionEnabled = false
    }
  }

  @IBAction func purchase(_ sender: Any) {
    self.loaderView.show()
    InAppPurchase.purchase(
      productIdentifier: "my_product",
      callback: { result in
        self.loaderView.hide()
      })
  }

  @IBAction func restorePurchases(_ sender: Any) {
    self.loaderView.show()
    InAppPurchase.restorePurchases(callback: { result in
      self.loaderView.hide()
    })
  }
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
Generate the documentation, using [Jazzy](https://github.com/realm/jazzy) by running the following command:
```
jazzy
```

# Troubleshooting
Common issues are covered here: https://github.com/iridescent-dev/iap-swift-lib/wiki/Troubleshooting


# License
InAppPurchaseLib is open-sourced library licensed under the MIT License. See [LICENSE](LICENSE) for details.
