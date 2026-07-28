# 60-ui-visual-simulator-walkthrough

- Number: 60
- Slug: ui-visual-simulator-walkthrough

## Notes

## Manual simulator pass

- Inspected the Home workspace visually on iPhone 17 Pro Max.
- Opened Capture from the primary action, toggled the framing guide, switched the document type to Passport, and dismissed back to Home.
- Direct walkthrough paused after the front Simulator window changed to an unrelated app/device during interaction; no actions were performed in that app.

## Home hero redesign

- The title and supporting text now use the complete card width; the plan state no longer competes with them.
- Reduced three overlapping privacy messages to one concise local-processing badge.
- Reworked the Free plan panel into capacity status with remaining document count and a semantic meter: green below half capacity, amber from half capacity, red at the limit.
- Forced scan and import labels to remain on one line with a bounded scale fallback.

## Validation

- Built a simulator preview and visually inspected the redesigned Home card.
- Home accessibility regression and primary tab/capture navigation regression passed.
