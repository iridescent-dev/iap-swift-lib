# Restoring purchases
Except if you only sell consumable products, Apple requires that you provide a "Restore Purchases" button to your users. In general, it is found in your application settings.

Call `InAppPurchase.restorePurchases()` when this button is pressed.

**Note**: This function is asynchronous and takes a `callback` function, called when the operation has been processed.
From this callback, you can for example unlock the UI by hiding your loading indicator and display a message to the user.

``` swift
self.loaderView.show()
InAppPurchase.restorePurchases(callback: { _ in
  self.loaderView.hide()
})

```

The callback also gives more information about the outcome of the restoration of purchases, you might want to use it to update your UI as well. So here's a more complete example.


``` swift
self.loaderView.show()
InAppPurchase.restorePurchases(
  callback: { result in
    self.loaderView.hide()

    switch result.state {
    case .succeeded:
      if result.addedPurchases > 0 {
        // At least one purchase has been restored.
        showResultScreen(withRestoredPurchases: true)
      } else {
        // No purchase to restore.
        showResultScreen(withRestoredPurchases: false)
      }
      
    case .failed:
      // Restore purchases failed.
      // - More details in result.iapError
      showError(result.iapError!.localizedDescription)
      
    case .skipped:
      // Refreshing when restoring purchases is never skipped.
      break
    }
  }
})
```

If the purchase fails, `result` will contain either `.skError`, a [`SKError`](https://developer.apple.com/documentation/storekit/skerror/code) from StoreKit, or `.iapError`, an `IAPError`.
