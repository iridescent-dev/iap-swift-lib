# Micro Example


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
    // Clean
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
