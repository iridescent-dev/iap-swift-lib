# Refreshing
Data might change or not be yet available when your "product" view is presented. In order to properly handle those cases, you should refresh your view after refreshing in-app products metadata. You want to be sure you're displaying up-to-date information.

To achieve this, call `InAppPurchase.refresh()` when your view is presented.

**Important**: Don't be reluctant to call `InAppPurchase.refresh()` often. Internally, the library ensures heavy operation are only performed if necessary. So in 99% of cases this call will result in no-operations.

**Note**: This function is asynchronous and takes a `callback` function, called when the operation has been processed.
From this callback, you can for example refresh your view by caling `self.refreshView()`. This function must be able to be called several times, so refresh the content but do not add elements to your view.

``` swift
override func viewWillAppear(_ animated: Bool) {
  self.refreshView()
  InAppPurchase.refresh(callback: { result in
    switch result.state {
    case .succeeded:
      self.refreshView()
      
    case .failed, .skipped:
      // Do nothing.
      break
  })
}
```
