# 151-cloudkit-schema-v2

- Number: 151
- Slug: cloudkit-schema-v2

## Notes

- CloudKit Console was initially open on the unrelated container
  `iCloud.com.romerodev.expirely`; MaskID uses `iCloud.com.romerodev.shield`.
- The MaskID container had `ShieldDocument` and `Users` in both Development and
  Production, but no `ShieldDocumentV2`. The legacy type was left untouched.
- Created `ShieldDocumentV2` in Development with `docID` (`String`),
  `modifiedAt` (`Date/Time`) and `package` (`Asset`), then deployed the schema
  to Production through CloudKit Console.
- Production verification shows `ShieldDocumentV2` with all three fields and
  no pending schema changes. The code already targets this type in
  `Shield/Cloud/CloudSyncManager.swift`.
