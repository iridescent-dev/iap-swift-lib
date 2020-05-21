# Refreshing
Data might change or not be yet available when your "product" view is presented. In order to properly handle those cases, you should refresh your view after refreshing in-app products metadata. You want to be sure you're displaying up-to-date information.

To achieve this, call `InAppPurchase.refresh()` when your view is presented.

``` swift
override func viewWillAppear(_ animated: Bool) {
  self.refreshView()
  InAppPurchase.refresh(callback: { _ in
      self.refreshView()
  })
}
```
