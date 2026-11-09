# App Store metadata — English (US)

Proposed draft for version 1.1.7. Version-scoped metadata (description, keywords, promotional text, and What's New) was synced to and read back from App Store Connect. Name and subtitle in this file were not changed because the shared public app-info localization was left intact. The app has English (US) and Spanish (Spain) store localizations; no other store language is evidenced in the project or live listing.

| Field | Draft | Limit |
|---|---|---:|
| Name | MaskID: Protects files and IDs | 30 characters |
| Subtitle | Hide Details Before Sharing | 30 characters |
| Keywords | `redaction,documents,privacy,passport,identity,bank,iban,signature,scanner,pdf,contract,mask,secure` | 100 UTF-8 bytes |
| Promotional text | Cover only what you choose, review every page, and check the protected copy on your device before sharing. | 170 characters |
| Description | See `version/1.1.7/en-US.json` | 4,000 characters |
| What's New | See `version/1.1.7/en-US.json` | 4,000 characters |
| Privacy policy | https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/ | URL |
| Support | https://lbernardo-dev.github.io/apps/en/case-studies/shield/support/ | URL |
| Marketing | https://lbernardo-dev.github.io/apps/en/case-studies/shield/ | URL |

Automated counts from `scripts/validate_release_metadata.py`:

| Field | Characters | UTF-8 bytes | Limit | Result |
|---|---:|---:|---:|---|
| Name | 30 | 30 | 30 | PASS |
| Subtitle | 27 | 27 | 30 | PASS |
| Keywords | 98 | 98 | 100 | PASS |
| Promotional text | 106 | 106 | 170 | PASS |
| Description | 2,022 | 2,038 | 4,000 | PASS |
| What's New | 495 | 495 | 4,000 | PASS |

Copy states the 15-day internal access period, the grandfathered 30+30-day migration, and the paid plan requirement after temporary access. It avoids an App Store trial claim and directs buyers to Apple's current price and renewal disclosure. Legal approval remains pending.
