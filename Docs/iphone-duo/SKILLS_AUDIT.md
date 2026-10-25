# Skills and source audit — iPhone Duo

Date: 2026-10-18. No external skill or dependency was installed.

## Sources selected

| Source | Version / provenance | Use and decision |
|---|---|---|
| Apple `swiftui-specialist` | Installed Codex skill at `/Users/romerodev/.codex/skills/swiftui-specialist`; Apple-authored guidance | Used for current SwiftUI composition, state and modifier guidance. Kept Apple platform documentation as the API authority. |
| SwiftUI Expert | Installed skill 5.2.0 at `/Users/romerodev/.codex/plugins/cache/openai-curated-remote/swiftui-expert/5.2.0`; references include `iphone-duo.md`, `layout-best-practices.md`, and `toolbar-patterns.md` | Used for Duo size-class, `ArrangementView`, reserved-region and testing guidance. It explicitly labels the Duo support guidance as beta; runtime claims therefore require the simulator matrix. |
| Device Interaction | Installed Codex skill at `/Users/romerodev/.codex/skills/device-interaction` | Reviewed for simulator evidence workflow. Its preferred device-interaction MCP surface was not exposed in this session; Xcode/simctl and Device Hub were used where possible. |
| Apple App Resizability skill | Xcode 27.1 CLI `xcrun agent skills export` | Attempted as requested. Export is blocked: the command reports that `Xcode.app` cannot be launched because it is corrupt and that no Xcode is running. `xcodebuild -version` and the Swift build work, so the failure is limited to the agent-skill export path. No copied or external replacement was installed. |
| XcodeBuildMCP | Availability checked in the provided tools | No XcodeBuildMCP surface was available. `xcodebuild`, `simctl`, and the Codex Device Hub were used instead. |

## Community catalogues considered

The [Swift Agent Skills catalogue](https://github.com/twostraws/Swift-Agent-Skills) is a curated directory, not a single reviewed skill; its README explicitly says inclusion is not an endorsement and asks users to inspect third-party authors and contents. The [SwiftUI Agent Skill repository](https://github.com/twostraws/SwiftUI-Agent-Skill) and [SwiftUI Expert repository](https://github.com/AvdLee/SwiftUI-Agent-Skill) are relevant alternatives, but this task already had a locally installed Duo-specific expert reference. The [Dimillian skills catalogue](https://github.com/Dimillian/Skills) and [swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills) were not installed or executed: the available skills plus Apple references cover the changes, and a third-party install would add supply-chain risk without a concrete technical need.

## Apple references used

- [Preparing your app for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/) — resizability, system chrome, size classes, and avoiding screen-model assumptions.
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo) — display, posture, and interaction guidance.
- [Prepare your app for iPhone Duo (Tech Talk 111461)](https://developer.apple.com/videos/play/tech-talks/111461/) — current SDK capabilities and validation approach.
- [App Store screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) — device-size assets and the announced iPhone Duo screenshot requirement.

## Security and limitations

No skill installation script ran and no project content was sent to a third-party service. External community popularity was not used as a proxy for safety or correctness. Since Apple marks the iPhone Duo guidance and iOS 27.1 APIs as beta-era capabilities, the build result alone does not establish behavior for every pose; the simulator validation status is tracked in `TEST_MATRIX.md`.
