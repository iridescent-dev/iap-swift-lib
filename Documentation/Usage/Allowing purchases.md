# Allowing purchases
In your store screen, where you present your products titles and prices with a purchase button, there are some cases to handle that we skipped. Owned products and deferred purchases.

## Owned products
Non-consumables and active auto-renewing subscriptions cannot be purchased again. You should adjust your UI to reflect that state. Refer to `InAppPurchase.hasActivePurchase()` to the [example](#example) later in this section.

## Deferred purchases
Apple's **Ask to Buy** feature lets parents approve any purchases initiated by children, including in-app purchases.

With **Ask to Buy** enabled, when a child requests to make a purchase, the app is notified that the purchase is awaiting the parent’s approval in the purchase callback:

``` swift
InAppPurchase.purchase(
  productIdentifier: productIdentifier,
  callback: { result in
    if result.state == .deferred {
      // Pending parent approval
  }
})
```

In the _deferred_ case, the child has been notified by StoreKit that the parents have to approve the purchase. He might then close the app and come back later. You don't have much to do, but to display in your UI that there is a purchase waiting for parental approval in your views.

We will use the `hasDeferredTransaction` method:

``` swift
InAppPurchase.hasDeferredTransaction(for productIdentifier: String) -> Bool
```

<a id="example"></a> 
## Example
Here's an example that covers what has been discussed above. We will update our example `refreshView` function from before:

``` swift
@objc func refreshView() {
  guard let product: SKProduct = InAppPurchase.getProductBy(identifier: "my_product_id") else {
    titleLabel.text = "Product unavailable"
    return
  }
  titleLabel.text = product.localizedTitle
  // ...

  // "Ask to Buy" deferred purchase waiting for parent's approval
  if InAppPurchase.hasDeferredTransaction(for: "my_product_id") {
    statusLabel.text = "Waiting for Approval..."
    purchaseButton.isPointerInteractionEnabled = false
  }
  // "Owned" product
  else if InAppPurchase.hasActivePurchase(for: "my_product_id") {
    statusLabel.text = "OWNED"
    purchaseButton.isPointerInteractionEnabled = false
  }
  else {
    purchaseButton.isPointerInteractionEnabled = true
  }
}
```

When a product is owned or has a deferred purchase, we make sure the purchase button is grayed out. We also use a status label to display some details. Of course, you are free to design your UI as you see fit.
