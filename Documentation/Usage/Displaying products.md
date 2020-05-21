# Displaying products
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
