# 150-zero-temporaries-policy

- Number: 150
- Slug: zero-temporaries-policy

## Notes

- Created `Docs/POLITICA_CERO_TEMPORALES.md` and `scripts/cleanup_temporaries.sh`.
- Registered the closure rule in `AGENTS.md`: dry-run audit, exact-ID approval, reversible move to Trash, and no Trash emptying.
- Read-only audit: `build/logs` 2.0G, `build/cache` 18G, `build/tmp` 768K, `build/DerivedData` 8.1G, `build/ui-ux-release-gate` 30M.
- `.asc/artifacts` is 3.9G and protected because it contains release artifacts.
- `/tmp` has no current `MaskID-*` or `DerivedData-MaskID` candidates and no active build/archive/upload process was detected.
- Read-only audit found 23 non-protected AppleDouble sidecars (94,208 bytes); 57,854 additional sidecars are contained within `build/` and are covered by the five generated roots.
- Cleanup mutation is pending approval of the exact candidate IDs listed by `scripts/cleanup_temporaries.sh --dry-run`.
