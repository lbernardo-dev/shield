# MaskID Subscription Financial Model

**Currency:** EUR, Spain storefront. Public and fixture list prices are VAT-inclusive consumer prices. Estimates below are gross scenario comparisons, not forecasts.

## Current catalog economics

| Plan | Price | Effective rate | Rationale |
|---|---:|---:|---|
| Monthly | €2.99/month | €35.88 per 12 months | Lower commitment for sporadic users |
| Standard Annual | €29.99/year | €2.50/month equivalent; 16.4% below 12 monthly payments | Primary renewal plan and current Best Value |
| Lifetime | €49.99 once | 1.67 annual payments to recover gross price | Preserve as an existing permanent-access choice; no renewal value after purchase |
| Shared Annual Event | €14.99/year in Spain through Halloween 2026; €29.99 from 1 Nov for new buyers | 50.02% event discount in Spain | One reusable SKU; ASC return to Standard is scheduled and verified for 175 storefronts with current-price preservation |

Current prices are from the Spain App Store listing and repository fixture. Do not assume they apply in other storefronts. Use StoreKit localized prices in the app.

## Gross annual revenue scenarios

| Active annual subscribers | Standard Annual at €29.99 | Event Annual at €14.99 | Gross difference |
|---:|---:|---:|---:|
| 100 | €2,999 | €1,499 | −€1,500 |
| 500 | €14,995 | €7,495 | −€7,500 |
| 1,000 | €29,990 | €14,990 | −€15,000 |

At the listed Spain prices, the Event cohort needs just over **2.00×** the paid subscriber volume to equal one year of Standard Annual gross billings, assuming equal refund, renewal, tax, fee and collection behavior. This is not a conversion forecast. It ignores event acquisition cost, future retention, churn, refund rates, upgrade/crossgrade behavior and the fact that a discounted renewal may persist.

## Spain proceeds illustration

Assuming 21% VAT is included in the displayed Spanish price:

| Price | Gross | Ex-VAT estimate | Proceeds at 15% commission on ex-VAT | Proceeds at 30% commission on ex-VAT |
|---|---:|---:|---:|---:|
| Standard Annual | €29.99 | €24.79 | €21.07 | €17.35 |
| Event Annual | €14.99 | €12.39 | €10.53 | €8.67 |

These are simplified estimates. Actual proceeds depend on Apple’s territory tax treatment, program eligibility, commission schedule, refunds, currency rounding and contractual terms. Apple’s Small Business Program provides a reduced rate for eligible developers; standard subscription commission is reduced after a subscriber accumulates one year of paid service. The table models a 15% reduced-rate case and a 30% first-year non-program case. Confirm current eligibility and territory-specific terms in App Store Connect before using these figures for forecasts. See [Apple’s current Developer Program terms](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/) and [subscription proceeds guidance](https://developer.apple.com/app-store/subscriptions/).

## Market positioning

Observed annual prices: Redacto €22.99; Adobe Scan tiers €22.99–€74.99; PDF Scanner tiers €29.99–€44.99; PDF Expert iOS tiers €44.99–€52.99 and a €84.99 Mac+iOS bundle. Selected sample low €22.99, median approximately €39.99, high €84.99 bundle. These are not equivalent products or subscription durations/offers. MaskID’s €29.99 is below that sample median, but about 30.4% above Redacto’s €22.99 annual listing.

**Recommendation:** keep €2.99 monthly, €29.99 annual and €49.99 lifetime until cohort evidence supports a change. Reuse one Event SKU, schedule its campaign price and return to Standard in ASC, and use Apple’s preserve-current-price option on end-of-event increases. Calendar windows automatically change paywall availability; they do not update ASC pricing. Include lifetime in event paywalls only if cannibalization analysis supports it; current implementation preserves the existing Lifetime package for catalog continuity.

Apple does not allow preserving a higher renewal price when a later price decrease takes effect: all active subscribers on the reusable Event product renew at the lower price. Thus a future campaign discount may also reduce renewals for any then-active Event subscriber paying more; the single-product strategy cannot promise independent renewal-price cohorts for every campaign. See Apple’s [current pricing rules](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/).

The EU Commission’s current VAT table lists Spain’s standard rate as 21%; the proceeds table uses that as a simplified illustration, not as proof of Apple’s tax treatment on each transaction. [EU VAT rate table](https://europa.eu/youreurope/business/finance-and-tax/vat/vat-rules-rates/indexamp_en.htm).

## Metrics to evaluate after launch

Track by campaign and storefront: paywall impressions, selected plan, checkout start, purchase success/cancel/error, trial eligibility/conversion, paid conversion, renewal, cancellation, billing issue, refund/revoke, restore, Event vs Standard conversion, 30/90/365-day retained revenue, gross proceeds, refunds, and cohort price point. Do not log document contents or offer codes.

Minimum decision rule: compare Event against a concurrent/seasonally adjusted standard cohort and use net proceeds per paywall impression plus 12-month retained revenue. A twofold purchase uplift is only a first-year gross break-even approximation.
