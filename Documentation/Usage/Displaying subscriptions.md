# Displaying subscriptions
For subscription products, you also have some data about subscription periods and introductory offers.

 - `func hasIntroductoryPriceEligible() -> Bool` - The product has an introductory price the user is eligible to.
 - `localizedSubscriptionPeriod: String?` - The period of the subscription.
 - `localizedIntroductoryPrice: String?` -  The cost of the introductory offer if available in the local currency.
 - `localizedIntroductoryPeriod: String?` - The subscription period of the introductory offer.
 - `localizedIntroductoryDuration: String?` - The duration of the introductory offer.

**Example**

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
