# 177-support-coffee-prompt

- Number: 177
- Slug: support-coffee-prompt

## Notes

- Replaced the icon-only PayPal “P” action with a centered coffee-cup prompt showing “¿Me regalas un café?” and the 2,99 € PayPal support detail.
- The prompt opens the configured PayPal.Me URL with `2.99EUR` prefilled. PayPal may still allow the donor to edit the amount before confirmation.
- Removed the donation action from the Settings About/menu rows and kept the regular version/build/privacy footer separate from the coffee prompt.
- Updated English and Spanish strings and the Paywall surface to use the same prompt.
- Validation: `git diff --check` and `jq empty Shield/Localization/Strings/SettingsInfo.xcstrings` passed. The Debug build reached dependency compilation but failed on pre-existing AppleDouble sidecars in the generated SwiftPM cache (`nanopb/spm_headers/._pb.h`), before reporting any source error in this change.
