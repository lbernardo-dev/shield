# Synthetic face-detection corpus

This fixture contains three entirely generated fictional portraits plus transformed, document-context, and negative-control cases. It contains no customer, employee, or other real-person images.

- `manifest.json` stores the hand-estimated face boxes for the three source portraits, then propagates those boxes mathematically for deterministic scale, rotation, mirroring, card placement, and multi-face compositions.
- Boxes use normalized top-left origin coordinates. Face extents on the three generated source portraits are approximate human annotations, not professional ground truth.
- Evaluation matches a prediction to a label at IoU >= 0.30. Unmatched predictions count as false positives, unmatched labels as false negatives.
- The set intentionally includes tiny/low-resolution faces, JPEG compression, glasses, partial occlusion, printed portraits, geometric distractors, and a text-like page.
- It is an engineering regression fixture only. Results must not be represented as accuracy on real documents or across populations.
- The portraits are test resources only; they are not included in the app target.
