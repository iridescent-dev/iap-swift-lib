# Displaying products

- [Basic Information](#basic-information)
- [Additional information for Auto-Renewable Subscriptions](#additional-information-for-auto-renewable-subscriptions)

<a id="basic-information"></a> 
## Basic Information
Let's start with the simplest case: you have a single product.

You can retrieve all information about this product using the function `InAppPurchase.getProductBy()`. 

``` swift
InAppPurchase.getProductBy(identifier: String) -> SKProduct?
```

This returns an [SKProduct](https://developer.apple.com/documentation/storekit/skproduct) extended with [helpful methods](Extensions/SKProduct.html).
Those are the most important:
 - `productIdentifier: String` - The string that identifies the product to the Apple AppStore.
 - `localizedTitle: String` - The name of the product, in the language of the device, as retrieved from the AppStore.
 - `localizedDescription: String` - A description of the product, in the language of the device, as retrieved from the AppStore.
 - `localizedPrice: String` - The cost of the product in the local currency (_read-only property added by this library, available for OSX >= 10.13.2 and iOS >= 11.2_).

### **Example**

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

This example assumes `titleLabel` is a UILabel, etc.

Make sure to call this function when the view appears on screen, for instance by calling it from [`viewWillAppear`](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621510-viewwillappear).

``` swift
override func viewWillAppear(_ animated: Bool) {
  self.refreshView()
}
```

<a id="additional-information-for-auto-renewable-subscriptions"></a> 
## Additional information for Auto-Renewable Subscriptions
For subscription products, you also have some data about subscription periods and introductory offers. (_read-only property added by this library, available for OSX >= 10.13.2 and iOS >= 11.2_)

 - `func hasIntroductoryPriceEligible() -> Bool` - The product has an introductory price the user is eligible to.
 - `localizedSubscriptionPeriod: String?` - The period of the subscription.
 - `localizedIntroductoryPrice: String?` - The cost of the introductory offer if available in the local currency.
 - `localizedIntroductoryPeriod: String?` - The subscription period of the introductory offer.
 - `localizedIntroductoryDuration: String?` - The duration of the introductory offer.

### **Example**

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
