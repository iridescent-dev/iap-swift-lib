# Purchasing
The purchase process is generally a little bit more involving than most people would expect. Why is it not just: purchase &rarr; on success unlock the feature?

Several reasons:
- In-app purchases can be initiated outside the app
- In-app purchases can be deferred, pending parental approval
- Apple wants to be sure you delivered the product before charging the user

That is why the process looks like so:
- being ready to handle purchase events from app startup
- finalizing transactions when product delivery is complete
- sending purchase request, for which successful doesn't always mean complete

### Initiating a purchase
To initiate a purchase, use the `InAppPurchase.purchase()` function. It takes the `productIdentifier` and a `callback` function, called when the purchase has been processed.

**Important**: Do not process the purchase here, we'll handle that later!

From this callback, you can for example unlock the UI by hiding your loading indicator and display a message to the user.

*Example:*

``` swift
self.loaderView.show()
InAppPurchase.purchase(
  productIdentifier: "my_product_id",
  callback: { _ in
    self.loaderView.hide()
})
```

This simple example locks the UI with a loader when the purchase is in progress. We'll see later how the purchase has to be processed by your applicaiton.

The callback also gives more information about the outcome of the purchase, you might want to use it to update your UI as well. Note that some events are useful for analytics. So here's a more complete example.

``` swift
self.loaderView.show()
InAppPurchase.purchase(
  productIdentifier: "my_product_id",
  callback: { result in
    self.loaderView.hide()

    switch result.state {
    case .purchased:
      // Product successfully purchased
      // Reminder: Do not process the purchase here, only update your UI.
      //           that's why we do not send data to analytics.
      openThankYouScreen()
    case .failed:
      // Purchase failed
      // - Human formated reason can be found in result.localizedDescription
      // - More details in either result.skError or result.iapError
      showError(result.localizedDescription)
    case .deferred:
      // The purchase is deferred, waiting for the parent's approval
      openWaitingParentApprovalScreen()
    case .cancelled:
      // The user canceled the request, generally only useful for analytics.
  }
})
```

If the purchase fails, result will contain either `.skError`, a [`SKError`](https://developer.apple.com/documentation/storekit/skerror/code) from StoreKit, or `.iapError`, an [`IAPError`](errors.html).

*Tip:* After a successful purchase, you should see a new transaction in [Fovea's dashboard](https://billing-dashboard.fovea.cc/transactions).
