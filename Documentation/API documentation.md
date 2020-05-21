# Classes and Protocols

The most important class is `InAppPurchase`. All the functions you need are defined in this class.

If you have *consumable* and/or *non-renewing subscription* products in your application, you must have a class that adopts the `IAPPurchaseDelegate` protocol.

# Products
* Input: the library requires an array of `IAPProduct` when it is initialized.

* Output: the library will returns [SKProduct](https://developer.apple.com/documentation/storekit/skproduct) extended with helpful methods. See the [`SKProduct` extension](Extensions/SKProduct.html).
  
# Callbacks
`refresh()`, `purchase()` and `restorePurchases()` are asynchronous functions. You must provide a callback that will allow you to perform actions depending on the result.

* For `refresh()` and `restorePurchases()` functions, the result will be `IAPRefreshResult`.

* For `purchase()` function, the result will be `IAPPurchaseResult`.

# Errors
When calling `refresh()`, `purchase()` or `restorePurchases()`, the callback can return an `IAPError` if the state is `failed`. Look at `IAPErrorCode` to see the list of error codes you can receive.
