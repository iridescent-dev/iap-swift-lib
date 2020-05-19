# API Documentation

(Work In Progress)

For convenience, the library provides some utility functions to check for your past purchases data (date, expiry date) and agregate information (has active subscription, ...).

- `func hasActivePurchase(for productIdentifier: String) -> Bool` checks if the user currently own (or is subscribed to) a given product (nonConsumable or autoRenewableSubscription).
``` swift
InAppPurchase.hasActivePurchase(for: productIdentifier)
```
- `func getPurchaseDate(for productIdentifier: String) -> Date?` returns the latest purchased date for a given product.
  ``` swift
  InAppPurchase.getPurchaseDate(for: productIdentifier)
  ```

- `func getExpiryDate(for productIdentifier: String) -> Date?` returns the expiry date for a subcription. May be past or future.
  ``` swift
  InAppPurchase.getExpiryDate(for: productIdentifier)
  ```
