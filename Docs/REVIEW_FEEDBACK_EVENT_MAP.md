# MaskID Review & Feedback Event Map

| Event | Type | Feature | Review candidate | Feedback candidate | Notes |
| --- | --- | --- | --- | --- | --- |
| `appLaunched` | Lifecycle | — | No | No | Initializes the reusable state model. |
| `sessionStarted` | Lifecycle | — | No | Maybe | Detects a meaningful return only after the configured inactivity threshold and prior engagement. |
| `onboardingCompleted` | Lifecycle | — | No | No | Never prompts during onboarding. |
| `coreActionCompleted` | Core action | `documentImport` | No | No | Import is activity, not delivered protection value. |
| `meaningfulResultDelivered` | Success | `secureExport` | Yes, after free thresholds | No | Fired only after verified export success; followed by a result-screen pause. |
| `premiumResultDelivered` | Premium success | `premiumMaskStyle` | Yes, after premium gates | No | Requires real Pro usage; purchase alone is insufficient. |
| `milestoneReached` | Milestone | `secureExport` or product key | Maybe | No | Engine decides; no counters are scattered in views. |
| `purchaseCompleted` | Subscription | product ID | No | No | Track only; starts the post-purchase deferral. |
| `subscriptionActivated` | Subscription | RevenueCat entitlement | No | No | Entitlement activation is not value realization. |
| `subscriptionRenewed` | Subscription | product ID | No | No | Renewal alone never opens a review sheet. |
| `subscriptionAutoRenewDisabled` | Churn | — | No; pending review cleared | Yes | Only after a verified status transition with no billing evidence. |
| `subscriptionBillingIssue` | Friction | — | No | Support signal only | Never labeled as voluntary cancellation. |
| `subscriptionExpired` | Churn | — | No | Maybe | Requires a sufficiently voluntary expiration reason. |
| `subscriptionReactivated` | Subscription | — | No | No | Wait for a later Pro result. |
| `operationFailed` | Friction | `documentImport` / `secureExport` | Suppress | After 2 failures | Isolated errors do not prompt feedback. |
| `repeatedFailure` | Friction | feature key | No | Yes | Contextual private feedback at a later pause. |
| `flowAbandoned` | Friction | feature key | No | Yes | Does not block the user or interrupt the flow. |
| `returnedAfterInactivity` | Retention | — | No | Yes | Queued on return; shown only after the next natural pause. |
| `permissionDenied` | Friction | permission key | Suppress | No | Avoids asking for a review during a blocked experience. |
| Settings `Send feedback` | Manual | — | No | Category-and-comment form | Always available independently of automatic triggers. |
| Settings `Rate the app` | Manual | — | Apple product-page link | No | Opens the `action=write-review` product link; no positive-rating gate. |

## Natural pause points

The primary pause is the completed export result inside `ExportSheetView`. The export task finishes before the coordinator is notified, then `markNaturalPause()` arbitrates feedback before review. Paywalls, active errors, onboarding, subscription management, sensitive warnings, destructive operations, and in-progress navigation remain hard gates.
