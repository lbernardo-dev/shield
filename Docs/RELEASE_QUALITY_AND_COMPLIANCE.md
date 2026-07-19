# Shield — Release quality and compliance

## Non-negotiable release gates

- Strict Swift concurrency, compiler warnings as errors, unit tests and UI tests pass.
- Secure PDF verifier rejects extractable text, annotations, metadata and OCR residuals.
- No placeholder credentials, implicit OAuth, analytics SDK, tracking domain or plaintext telemetry.
- Privacy manifest validates and App Store privacy answers match actual behavior.
- Accessibility audit passes for descriptions, hit regions, clipping, traits and element detection; contrast is reviewed in light/dark and Increase Contrast.
- Import cancellation leaves no partial project; temporary exports are deleted on dismissal/background.

Run `AGENT_NAME=RELEASE scripts/release_gate.sh` from the repository root.

## Performance budgets

| Operation | Budget | Failure policy |
|---|---:|---|
| First interactive launch | 1.5 s on current baseline device | Block release if p95 regresses >20% |
| Import preview | 2 s first page / 250 ms subsequent page | Profile image decode and memory |
| OCR | 2.5 s per 12 MP page | Cancelable; never block main actor |
| Editor gesture response | <16 ms frame p95 | No synchronous decode during gesture |
| Secure PDF export | 1 s/page, max 50 pages | Progress + cancellation required |
| Peak decoded image memory | 256 MB pipeline cap | Reject with actionable error |

MetricKit diagnostics and local telemetry must contain only event identifiers, durations, counts, device-class buckets and app versions. Never titles, OCR text, filenames, URLs, document IDs, PIN state or image content.

## App Store / TestFlight checklist

1. Archive Release with distribution signing and run Organizer validation.
2. Test camera, document scanner, Photos limited access, Files providers, offline mode and denied permissions on physical devices.
3. Test VoiceOver, Voice Control, keyboard, Dynamic Type XXXL, Reduce Motion, Increase Contrast and iPad split view.
4. Verify subscription products, restore purchases, grace/error paths and that core secure export is never paywalled.
5. Export adversarial fixtures and independently inspect every page.
6. Confirm support URL, privacy policy, terms, data deletion wording and App Review notes.
7. Stage to internal TestFlight, monitor MetricKit/crash-free sessions for 72 hours, then phased release.
