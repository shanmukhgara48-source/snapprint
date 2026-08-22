# SnapPrint Production Smoke Test

Run this only against the production API, production Firebase project, production database, and live Razorpay keys.

## Customer Flow

1. Install the production Android AAB or iOS App Store/TestFlight archive on a real device.
2. Launch the app and confirm the splash/startup path reaches the login screen without Firebase initialization errors.
3. Sign in with Firebase phone authentication using a real phone number.
4. Complete OTP verification and confirm the user lands on Home.
5. Open Home and verify banners, categories, products, delivery settings, and app settings load from production.
6. Open Categories and select at least one category.
7. Open Products and verify active products only are visible.
8. Search for an existing product and a nonsense query; verify expected results and empty state.
9. Open Product Details and verify images, size pricing, stock state, and customization path.
10. Add a customized product to Cart.
11. Change quantity and verify totals update.
12. Apply a valid coupon, an invalid coupon, and an expired coupon.
13. Select each active delivery option and verify delivery charges.
14. Start Checkout with a valid address.
15. Open Razorpay and complete one live low-value payment.
16. Verify backend payment verification succeeds and no failed payment attempt is recorded for the successful payment.
17. Verify the order is created exactly once.
18. Open Order History and verify the order appears.
19. Open Order Tracking and verify the confirmed tracking event appears.
20. Open Profile, update profile/address data, logout, and log back in.
21. Confirm FCM notification permission and receive at least one order/status notification.

## Admin To Customer Realtime

1. Login to the production admin web app.
2. Create a category and verify it appears on a connected customer device without app restart.
3. Update that category and verify the customer device updates.
4. Create a banner and verify it appears on the customer Home screen.
5. Update that banner and verify propagation.
6. Create a product and verify it appears in browse/search.
7. Edit the product name, price, image, stock, and category; verify customer screens update.
8. Disable the product and verify it is no longer orderable.
9. Enable the product and verify it returns.
10. Delete the product or confirm it is safely deactivated when order history exists.
11. Create a coupon and verify the customer can apply it.
12. Update the coupon and verify changed discount/limits.
13. Change inventory and verify stock-sensitive ordering behavior.
14. Change order status and verify customer order tracking updates.
15. Change delivery settings and verify checkout totals update.
16. Change app settings and verify customer-visible settings update.

## Failure And Edge Cases

1. Disconnect the customer device network during browse, cart, checkout, payment return, and order creation; verify recovery states.
2. Disconnect and reconnect the admin web app; verify WebSocket reconnect and cache invalidation.
3. Background and resume the customer app during payment and after order confirmation.
4. Expire or revoke the customer Firebase token and verify protected API calls fail safely until reauth.
5. Expire the admin JWT and verify admin APIs/WebSocket reject it and require login.
6. Retry the same successful Razorpay payment callback twice; verify the existing order is returned and no duplicate order is created.
7. Simulate payment failure and cancellation; verify no confirmed order is created.
8. Delete or disable a product while it is in a customer cart; verify checkout fails with a clear unavailable-product state.
9. Reduce stock below cart quantity before checkout; verify checkout fails without charging or creating an order.
10. Verify production logs do not contain secrets, private keys, card data, OTPs, or full auth tokens.
