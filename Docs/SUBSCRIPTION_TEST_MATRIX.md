# MaskID Subscription Test Matrix

**Execution status (8 October 2026):** Build and Event Annual validator/schedule tests passed on the required iPhone 18 Pro. The Event paywall was manually inspected on iPhone 18 Pro and iPad Pro 13-inch (M5) in portrait; the iPad was also inspected in landscape. The full UI suite stalled while Xcode finalized its result log and was interrupted; it is not marked passed. Sandbox purchase, renewal, restore, and Apple review are pending.

## Automated in-repository coverage

| Case | Automated check | Expected result |
|---|---|---|
| Event annual price 14.99 vs Standard 29.99 | `acceptsStorefrontPrice` | Accept and compute actual 50% rounded discount |
| Wrong product ID | `rejectsConfigurationMismatch` | Reject Event pricing |
| Wrong period or period count | Same validator test | Reject Event pricing |
| Different group or group level | Same validator test | Reject Event pricing |
| Event introductory offer present | Same validator test | Reject Event pricing |
| Price outside configured target ±5 percentage points | Same validator test | Reject Event pricing |
| Campaign active and all configuration valid | `failsSafeToStandardPaywall` | Select Event experience for Free user |
| Existing active Premium user | Same resolver test | Do not show acquisition Event experience |
| Invalid/missing price | Same resolver test | Standard fallback |
| Halloween before/start/during/end | `halloweenCampaignWindow` | Device-local schedule changes at its boundaries |

## Purchase and lifecycle matrix

| Scenario | Setup / action | Expected result | Status |
|---|---|---|---|
| Monthly purchase | Sandbox, Free user, `default` Offering | RevenueCat Package purchase grants active `MaskID Pro`; localized monthly price | Manual Sandbox pending |
| Standard Annual purchase | Standard paywall, eligible and ineligible trial accounts | Same entitlement; trial text only for eligible selected package | Manual Sandbox pending |
| Event Annual purchase | Campaign active, RC `event` Offering live, matching StoreKit prices | Buy the shared generic Event product; same entitlement and same Premium access | Manual Sandbox pending |
| Event renewal | Renew Event Annual in accelerated Sandbox | Entitlement stays active; product ID remains the shared Event product | Manual Sandbox pending |
| Renewal after event end | End campaign while Event subscriber active | User remains Pro; renewal is not converted/cancelled by app | Manual Sandbox pending |
| Grandfathered renewal | At campaign end, scheduled Event price return to Standard with Apple’s preserve-current-price option | New buyers see Standard price; existing campaign buyers renew at their preserved price while eligible under Apple’s rules | ASC schedule verified 175/175; Sandbox pending |
| Standard paywall | Schedule inactive or configuration absent | Monthly + Standard Annual + Lifetime; no campaign discount | Manual UI pending |
| Event paywall | Active schedule + event package and exact validated StoreKit metadata | Monthly + Event Annual + Lifetime; real localized comparison and discount | Display visually verified on iPhone 18 Pro and iPad Pro 13-inch; no purchase performed |
| Event starts while app open | Open a paywall before start; keep app foreground across boundary | Scheduled event publication reloads packages and updates paywall | Manual UI pending |
| Event ends while app open | Keep event paywall open past end | Event Annual disappears and Standard Annual returns | Manual UI pending |
| RevenueCat unavailable | Disable network with/without cached Offering and CustomerInfo | Cached standard packages may display; Event/checkout stay disabled until Free status resolves; otherwise retry/unavailable state; never unlock by Boolean | Manual offline pending |
| StoreKit unavailable | Simulate product lookup failure | Standard Offering; no Event discount | Manual Sandbox pending |
| Wrong Event price | Set fixture price outside validator band | Standard paywall; fallback telemetry reason | Unit covered; UI verification pending |
| Missing Event product | Remove product from fixture/RC Offering | Standard paywall | Unit/path verification pending |
| Restore Standard | Buy Annual, reinstall/reset app data, tap Restore | CustomerInfo restores same entitlement and tier | Manual Sandbox pending |
| Restore Event | Buy Event Annual, reinstall/reset app data, tap Restore | Event entitlement restores even after campaign | Manual Sandbox pending |
| Reinstall | Reinstall using same Apple ID | RevenueCat/restore path recovers access; old UserDefaults Boolean grants nothing | Manual device pending |
| New device | Install on second device, restore same Apple ID | Same valid purchase is recognized; verify RC anonymous-ID transfer behavior | Manual device pending |
| Offer-code redemption in app | Configure ASC code; redeem through Settings native sheet | Only verified transaction is synced; CustomerInfo refresh grants valid entitlement | ASC/TestFlight pending |
| Offer code redeemed externally | Redeem from App Store then return/open app; if needed tap Settings Restore | Transaction is reconciled and valid entitlement applied | Manual production/TestFlight pending |
| Cancellation / auto-renew off | Cancel from Apple subscription management while paid term remains | Pro remains until expiration; `willRenew == false` and state is auto-renew off | Manual Sandbox pending |
| Expiration | Advance Sandbox past expiration | Entitlement inactive; app removes Pro after CustomerInfo refresh | Manual Sandbox pending |
| Billing retry | Cause sandbox billing issue | Follow RevenueCat active entitlement; do not claim a grace period without status | Manual Sandbox pending |
| Grace period | Enable/test ASC billing grace period if configured | Pro only while RC entitlement remains active; verify actual renewal state | ASC/Sandbox pending |
| Refund/revoke | Revoke/refund sandbox transaction | RC entitlement becomes inactive; app removes Pro after update | Manual Sandbox pending |
| Apple ID/account switch | Switch Store account, restore each state | Confirm no accidental entitlement transfer/loss; record RC Restore Behavior | Manual device pending |
| Apple Manage Subscriptions path | Open group controls outside the app before, during and after the event | Product stays at Standard price outside the event; confirm Event price only during the scheduled window and same entitlement after crossgrade | Manual device/Sandbox pending |
| Family Sharing | Share Annual/Lifetime with test family group; restore on member device | Same entitlement is active when Apple/RC says Family Shared | Manual family account required |

## Price schedule and configuration matrix

| Scenario | Expected behavior | Status |
|---|---|---|
| Before campaign | Event product is at standard-equivalent ASC price; app schedule selects Standard Offering | ASC + Sandbox pending |
| Campaign starts, Store price has not changed yet | App refuses Event paywall because StoreKit price check fails; Standard fallback | Unit validator + manual clock/UI pending |
| Campaign active, Event price valid | StoreKit display prices and computed actual discount are visible | Manual storefront/Sandbox pending |
| Campaign ends | App schedule selects Standard and the verified ASC price rise takes effect for new buyers, preserving existing subscriber prices | ASC schedule verified 175/175; unit schedule + manual UI pending |
| Price differs by storefront | Use each storefront’s StoreKit display price and computed discount; no hardcoded currency/value | Manual storefront testing pending |
| App schedule / ASC schedule mismatch | Standard fallback; coordinate StoreKit price and app event dates before marketing | Manual ASC pending |
| Later campaign | Reuse the shared Event product; schedule Standard → Event price → Standard and preserve the event cohort on the ending increase | Apple permits one pending future change per storefront/plan; schedule and verify transitions before the paywall window | ASC/Sandbox behavior must be verified |

## Execution constraints and records

- Follow the repository’s simulator matrix: first discover and use **iPhone 18 Pro** by explicit UDID/runtime; do not take over/reset an occupied device. Then iPhone Duo if available, a representative iPad, and Apple Watch only if a watch target exists.
- Test StoreKit configuration locally and App Store Sandbox separately. A local `.storekit` transaction does not verify ASC or RevenueCat configuration.
- For each manual test record app build, device/runtime, storefront, Sandbox account, RC App User ID (redacted), product ID, price displayed, entitlement status and result. Do not record passwords or redemption codes.
- Offer-code Sandbox behavior can differ from production; verify through a controlled TestFlight/production code procedure before launch.
- No test is considered complete based only on a green compile or a UI screenshot.

## Device and automated execution (8 October 2026)

| Destination | Runtime / identifier | Build and checks | Result |
|---|---|---|---|
| iPhone 18 Pro | iOS 27.0 · `1454EA8D-A019-4B07-B57C-1433E0F21BE0` | MaskID `1.1.2 (1122026100201)`; build/install/launch; Event paywall manually inspected (simulator storefront USA: $12.99 vs $24.99, actual 48%) | Pass for build and visual paywall; 5/5 subscription experience tests pass |
| iPad Pro 13-inch (M5) | iPadOS 27.0 · `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1` | Same build installed/launched; portrait and landscape paywall layout inspected | Pass for those layouts; multitasking not exercised |
| iPhone Duo | Not present in available simulator list | — | Unavailable; no substitute used |
| Apple Watch Series 12 (46 mm) | watchOS 27.0 simulator visible; paired with iPhone 18 Pro in Device Hub | MaskID has no Watch app target/scheme | No watch component to install or validate |

Evidence:

- App Review screenshot: [`event-annual-review-iphone-18-pro.png`](../audit/event-annual-review-iphone-18-pro.png).
- iPad portrait: [`event-annual-paywall-ipad-pro-13-m5.png`](../audit/event-annual-paywall-ipad-pro-13-m5.png).
- iPad landscape: [`event-annual-paywall-ipad-pro-13-m5-landscape.png`](../audit/event-annual-paywall-ipad-pro-13-m5-landscape.png).
- Focused Swift Testing result: [`subscription-experience-test-summary.json`](../audit/subscription-experience-test-summary.json) (`5 passed, 0 failed`).

The full `xcodebuild test` run remained in Xcode's “waiting for test log to finish recording / blocking finish to clean up test session” state for over 14 minutes. Only the `xcodebuild` process started for this run was terminated; the simulator was not restarted or erased. Its `.xcresult` is incomplete, so the full UI suite has no pass/fail result. A later read-only `simctl` help request found CoreSimulatorService disconnected; no attempt was made to restart or seize the simulators. Sandbox logs reported no signed-in StoreKit account; no purchase transaction was made.
