# Restoring purchases
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
