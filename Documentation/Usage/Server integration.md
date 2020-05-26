# Server integration
In more advanced use cases, you have a server component. Users are logged in and you'll like to unlock the content for this user on your server. The safest approach is to setup a [Webhook on Fovea](https://billing.fovea.cc/documentation/webhook/?ref=iap-swift-lib). You'll receive notifications from Fovea that transaction have been processed and/or subscriptions updated.

The information sent from Fovea has been verified from Apple's server, which makes it way more trustable than information sent from your app itself.

To take advantage of this, you have to inform the library of your application username. This `applicationUsername` can be provided as a parameter of the `InAppPurchase.initialize()` method or updated later by changing the associated property.

### **Example**

``` swift
InAppPurchase.initialize(
  iapProducts: [...],
  validatorUrlString: "...",
  applicationUsername: UserSession.getUserId()
)

// later ...
InAppPurchase.applicationUsername = UserSession.getUserId()
```

If a user account is mandatory in your app, you will want to delay calls to `InAppPurchase.initialize()` to when your user's session is ready.

Do not hesitate to [contact Fovea](mailto:support@fovea.cc) for help.
