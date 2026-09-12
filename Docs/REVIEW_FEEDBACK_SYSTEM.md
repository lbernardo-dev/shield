# MaskID Review & Feedback System

## Architecture

MaskID now uses one event-driven coordinator, `ReviewFeedbackCoordinator`, for two independent outputs:

```text
business/lifecycle events
          |
          v
ReviewFeedbackCoordinator
       /                 \
Review opportunity       Private feedback opportunity
       |                         |
SwiftUI requestReview       contextual native sheet
       |                         |
Apple controls display     existing support email transport
```

The coordinator owns lightweight `UserDefaults` state. It does not store documents, OCR, image data, names, account identifiers, or free-form feedback text. `FeatureKey`, `EngagementEvent`, `EngagementState`, `ReviewEligibilityPolicy`, `SubscriptionLifecyclePolicy`, `FeedbackEnvelope`, and `FeedbackTransport` form the reusable portfolio boundary.

The StoreKit boundary is deliberately a SwiftUI view: `ReviewFeedbackBridge` reads `@Environment(\.requestReview)` and is the only production call site for `RequestReviewAction`. Services create opportunities; views only report semantic events or a natural pause.

## Existing system audit

- The app uses RevenueCat for Pro entitlement and product purchase state. RevenueCat remains authoritative for `isPro`; no second entitlement manager was introduced.
- StoreKit 2 is used for subscription status snapshots and `AppStore.showManageSubscriptions(in:)`. The app does not add a second `Transaction.updates` listener because RevenueCat already owns purchase transaction observation.
- The previous `AppReviewManager` used a score and called `AppStore.requestReview(in:)` from a UIKit scene lookup. It had no feedback engine, no session/day thresholds, no pending opportunity queue, no version gate, and no subscription lifecycle comparison.
- Support already exists through `romerodev.app+maskid@gmail.com` and localized help-center pages. The new mail transport reuses that destination; no new backend was invented.
- Firebase Analytics is opt-in. Review/feedback events are sent through the existing privacy-safe `AppState.trackEvent` allow-list. Feedback text is never sent to analytics.
- The real App Store ID is centralized as `AppStoreConfiguration.appID = 6790398619`.

## MaskID value model

MaskID protects sensitive documents locally and delivers value when the user receives a safe, verified export. The most important distinction is between an import or button tap and a completed result:

- Core action: a document has been imported and is available for editing.
- Meaningful result: a secure PDF or image export completed successfully and the result screen is visible.
- Premium result: a Pro user successfully exported a document using a premium masking style.
- Friction: the same import or export operation fails repeatedly, a key flow is abandoned, or support is requested.

The review system therefore does not ask after onboarding, a purchase button, a save tap, a paywall, an error, or a sensitive warning.

## Review policy

MaskID configuration is intentionally conservative:

| Rule | Initial value |
| --- | ---: |
| Free meaningful results | 3 |
| Free sessions | 3 |
| Free active days | 2 |
| Minimum age after first meaningful use | 72 hours |
| Premium successful results | 1 |
| Deferral after purchase | 24 hours |
| Local automatic cooldown | 120 days |
| Automatic attempts per app version | 1 |
| Negative-signal suppression | 10 days |

An eligible success creates `PendingReviewOpportunity`. It is not a review request. The opportunity is consumed only after `markNaturalPause()` confirms that a result is visible and the UI is idle. Apple may still decide not to show the system sheet, so the app never records `userHasReviewed` or a fake submitted-review event. It records only attempt metadata.

Free users are eligible; Pro users are not preferred because they paid. Pro eligibility requires real Pro value, not the purchase itself.

## Feedback policy

Feedback is independent from App Store review and never uses a positive-rating question or an internal star filter. Automatic triggers are:

- confirmed `willAutoRenew: true → false` without billing evidence;
- a return after 30 days of inactivity for a previously engaged user;
- the same import/export operation failing twice in the current episode;
- a semantically abandoned key flow.

Billing retry, grace period, payment failure, and ambiguous StoreKit state are recorded as a support/friction signal and are not presented as “Why did you cancel?”.

Automatic feedback is queued and shown at a later natural pause. `Not now` applies the 30-day global cooldown. A subscription cancellation opportunity always clears a pending review opportunity, so two prompts cannot be shown consecutively.

The feedback sheet uses contextual categories, an optional comment, native controls, Dynamic Type, VoiceOver traits, keyboard-friendly text input, Dark Mode, and Reduce Motion-compatible UI. After a successful submission it shows a localized thank-you screen with a visible 10-second countdown, then closes automatically; the user can also close it immediately. It opens the existing private support channel and never asks for a review.

## Subscription lifecycle

RevenueCat owns entitlements and purchase delivery. `SubscriptionLifecycleObserver` reads verified `Product.SubscriptionInfo.Status` values for `shield_pro_group`, stores a minimal snapshot, and compares it on launch/foreground and after the StoreKit management sheet closes.

The observer distinguishes:

- auto-renew disabled: private cancellation feedback candidate;
- auto-renew enabled: reactivation signal only;
- renewal: engagement signal only, never a review by itself;
- billing retry/grace/payment error: support/friction state, not voluntary cancellation;
- expiration: feedback only when the reason is sufficiently consistent with voluntary churn.

No cancellation flow is blocked or delayed.

## Privacy rules

`FeedbackEnvelope` contains only category, optional user-authored comment, trigger, app/build/OS/locale, entitlement tier, and a coarse feature key. It never attaches:

- document names, document contents, images, OCR, extracted fields, MRZ, or export files;
- people, children, contacts, location, health information, financial values, or account identifiers;
- analytics copies of free-form text.

The UI explicitly tells users not to include document or personal information in the optional comment.

## Analytics

The existing consent-gated analytics path may receive:

`review_opportunity_created`, `review_opportunity_eligible`, `review_request_attempted`, `feedback_opportunity_created`, `feedback_dismissed`, `feedback_submitted`, and `returned_after_inactivity`.

Allowed parameters are limited to `trigger`, `user_tier`, `feature_key`, `category`, and existing safe app metadata. There is no `star_rating` or `review_submitted` event because the app cannot observe the App Store outcome.

## Localization and support

Feedback copy, categories, and the thank-you countdown are in `SettingsInfo.xcstrings` for English and Spanish. Manual Settings actions remain separate:

- `Send feedback` opens the localized category-and-comment form.
- `Rate the app` opens Apple’s `action=write-review` product-page link. Automatic natural-pause opportunities continue to use the central SwiftUI `RequestReviewAction`; Apple does not display that action in TestFlight builds.

## Testing

`ShieldTests/AppReviewManagerTests.swift` covers free and premium thresholds, purchase deferral, cooldown/version awareness, hard presentation gates, cancellation versus billing classification, contextual categories, privacy-safe payload content, and keeping the submitted context alive for the thank-you screen. Tests do not depend on the real StoreKit sheet.

The UI tests verify that the Settings feedback action exposes localized categories and a free-text field, and that the Settings rate action opens an external review page or presents the unavailable fallback. The automatic App Store sheet itself is intentionally not automated.

## Configuration and future transport

The current app has no feedback backend, so `MailFeedbackTransport` is the production implementation. A future HTTPS or Supabase transport can conform to `FeedbackTransport` without changing event policy or the UI. It must preserve the same data-minimization contract.
