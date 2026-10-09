# 207-generic-event-annual-product

- Number: 207
- Slug: generic-event-annual-product

## Notes

- Replaced the event-specific Halloween subscription ID with `com.romerodev.shield.pro.annual.event` as the single annual offer product for every active event.
- Removed per-campaign product ID configuration from the seasonal monetization model. Event/campaign IDs remain for scheduling and attribution; all events use RevenueCat Offering `event` and the same product/entitlement.
- Removed the manual campaign enable flag. The active schedule now switches the paywall automatically at start/end boundaries and refreshes an open paywall, on foreground, on midnight/significant clock changes, and on time-zone changes. New catalog events supply their date window and monetization metadata and automatically reuse the same product. No daily activation/deactivation is needed; adding a future event still requires a catalog change and app release. The active campaign’s configured discount target drives StoreKit price validation.
- Updated the local StoreKit fixture and ASC, RevenueCat, architecture, campaign, audit and test documentation. Documented Apple price decreases as product-level changes that can affect all active subscribers on the shared product.
- At the time task 207 was closed, the 8 October dashboard check was read-only and the Event product was absent from both catalogs. The external setup and remaining release blockers are tracked separately under task 209; its current record supersedes that earlier snapshot.
- The app’s active local Halloween window is Oct 1–Nov 1, 2026 in device-local time. The campaign uses Standard fallback until the ASC review metadata and RevenueCat mapping/Offering are complete and StoreKit confirms the live price.
