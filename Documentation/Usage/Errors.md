# Errors

When calling `refresh()`, `purchase()` or `restorePurchases()`, the callback can return an `IAPError` if the state is `failed`.
Here is the list of `IAPErrorCode` you can receive:

* Errors returned by `refresh()`, `purchase()` or `restorePurchases()`
  - `libraryNotInitialized` - You must call the `initialize` fuction before using the library.
  - `bundleIdentifierInvalid` - The Bundle Identifier is invalid.
  - `validatorUrlInvalid` - The Validator URL String is invalid.
  - `refreshReceiptFailed` - Failed to refresh the App Store receipt.
  - `validateReceiptFailed` - Failed to validate the App Store receipt with Fovea.
  - `readReceiptFailed` - Failed to read the receipt validation.

* Errors returned by `refresh()`
  - `refreshProductsFailed` - Failed to refresh products from the App Store.

* Errors returned by `purchase()`
  - `productNotFound` - The product was not found on the App Store and cannot be purchased.
  - `cannotMakePurchase` - The user is not allowed to authorize payments.
  - `alreadyPurchasing` - A purchase is already in progress.
