# Xcode disk cleanup audit

Created: 2026-08-26T17:05:46.955884+00:00

No cleanup has been performed. Candidate sizes are not additive on APFS.

| ID | Category | Risk | Recoverable | Candidate | Action |
|---|---|---:|---:|---|---|
| `runtime-stale:E867ABCB-D951-4040-8DDC-AA24D355CB7B` | Stale simulator runtime | destructive | 8.23 GiB | iphonesimulator 18.6 (22G86) | simctl-runtime-delete |
| `runtime:3DF9FA21-60E6-4714-972F-4005444C6A6A` | Simulator runtime | preserve | 7.91 GiB | iphonesimulator 26.5 (23F77) | report-only |
| `managed-component:AppleDeveloperDocumentation` | Xcode-managed component | preserve | 5.80 GiB | AppleDeveloperDocumentation | report-only |
| `runtime:4DE84E81-965C-45DB-833B-5FD4712E15E9` | Simulator runtime | preserve | 3.66 GiB | watchsimulator 26.5 (23T570) | report-only |
| `xcode-app:Xcode.app` | Installed Xcode | preserve | 3.50 GiB | Xcode.app | report-only |
| `device-support:watchOS:26.6 (23U67) universal` | DeviceSupport | preserve | 2.92 GiB | watchOS 26.6 (23U67) universal | report-only |
| `managed-component:MetalToolchain` | Xcode-managed component | preserve | 0.65 GiB | MetalToolchain | report-only |
| `archive:2026-08-21:personalcare 21-08-2026, 09.59.37.xcarchive` | Archive | preserve | 0.54 GiB | personalcare 2.2.0 (220202608214) | report-only |
| `device-support:iOS:iPhone16,2 26.6 (23G71)` | DeviceSupport | preserve | 0.49 GiB | iOS iPhone16,2 26.6 (23G71) | report-only |
| `logs:coresimulator-logs` | Diagnostic logs | regenerable | 0.00 GiB | CoreSimulator logs | trash-path |
| `device-support:watchOS:Watch6,18 26.6 (23U67)` | DeviceSupport | destructive | 0.00 GiB | watchOS Watch6,18 26.6 (23U67) | trash-path |

Actionable candidate size: **8.23 GiB**
Preserve/review size: **25.47 GiB**

Review each item’s evidence and regeneration cost before approving exact IDs.
