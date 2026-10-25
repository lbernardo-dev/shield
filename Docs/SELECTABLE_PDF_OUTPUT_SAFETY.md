# Selectable PDF output: security decision

Date: 2026-10-21

## Decision

**No-go for selectable text in protected exports at this time.** Keep protected PDF output flattened and raster based. Preserve source page size and render quality from the retained source PDF, but do not copy its text objects, annotations, forms, layers, or metadata into the protected file.

PDFKit supports PDF search and text selection, but that capability does not remove underlying text covered by a drawn mask. Drawing opaque rectangles over source text can therefore create a visually convincing file whose sensitive text remains searchable or copyable. The current exporter avoids that class of leak by rendering each page and compositing opaque masks before writing the output. The verifier also treats any extractable text in a protected PDF as a verification failure (`extractable_text_found`).

## Evidence in this app

- `Shield/Views/Editor/ExportServices.swift` rasterizes each source page, composites secure redactions, then writes the flattened page to a new PDF.
- `Shield/Export/ExportVerifier.swift` checks page count, extractable text, annotations, sensitive metadata, and OCR residuals. An extractable text layer is currently a hard failure.
- The source PDF is retained separately for future editing and high-resolution export rendering; the protected PDF is generated from page pixels and does not copy its original content objects.

## Evaluation scope and limits

The repository contains synthetic verifier coverage for extractable text, raster OCR residuals in redaction areas, annotations, metadata, rotation, multilingual pages, low-resolution pages, and 50-page output. These fixtures test the flattened exporter and its current verifier; they do **not** establish that a selectable reconstruction can safely retain every allowed text object. Execution is deferred to the final simulator validation cycle for the current implementation.

The selectable approach considered here would have to reconstruct permitted text and objects from sanitized OCR/geometry rather than reuse source content streams. The app currently has no independent tokenizer, reading-order model, glyph-level redaction engine, or adversarial verifier for ligatures, hidden layers, form values, attachments, incremental history, and OCR/text alignment. No fidelity, file-size, or performance benchmark of the production OCR/reconstruction pipeline has been run. A string search that fails to find a secret would not prove the PDF object graph is clean.

The existing no-go is therefore a safety decision based on the current architecture and verifier boundary, not a claim that selectable output is impossible. The flat PDF and image formats remain the only output paths offered by protection profiles.

## Synthetic performance and fidelity comparison — 2026-10-24

A reproducible, offline prototype benchmark is available at `scripts/benchmark_selectable_pdf.swift`. It creates 12 synthetic selectable pages with mixed page sizes, multilingual/ligature-prone text, vector tables, a stamp, a signature and barcode-like marks. One account-number line is masked. The raster candidate renders at 2× and JPEG-encodes each page; the selectable candidate recreates the known safe fixture text and exact mask geometry as fresh PDF text. No user documents are used.

| Candidate | PDF size | Generation time | Mean absolute RGB error vs. masked source | Text search |
|---|---:|---:|---:|---|
| Flattened raster | 776,182 B | 0.0824 s | 10.04 / 255 | No extractable text; synthetic secret absent |
| Selectable reconstruction prototype | 32,398 B | 0.00739 s | 1.09 / 255 | Safe phrase selectable; synthetic secret absent |
| Selectable source fixture | 40,127 B | 0.0115 s | — | Synthetic secret present, as expected |

These figures are a lower-bound demonstration, not a production comparison. The reconstruction receives ideal text and exact geometry from the fixture generator, reuses the same CoreText drawing parameters as the source, and omits most scan-specific visual content; the raster path pays a second render and JPEG encode. The result therefore cannot be generalized to Vision recognition, arbitrary PDFs or actual customer documents. It confirms that a fully rebuilt, whitelisted text layer can be compact and selectable in a controlled case, while leaving OCR alignment, ligatures and object-graph cleanup unproven. The safety decision remains **no-go** until adversarial fixtures, independent OCR, format-object checks and real fidelity benchmarks validate the full pipeline.

Run on macOS from the repository root:

```sh
xcrun swiftc -module-cache-path build/SelectablePDFBenchmarkModuleCache \
  -o build/benchmark-selectable-pdf scripts/benchmark_selectable_pdf.swift
build/benchmark-selectable-pdf build/selectable-pdf-benchmark
```

## Threat cases to keep in scope

1. Copy and paste or PDF text search recovers text beneath a visible mask.
2. Annotations, form values, accessibility text, alternate text, or hidden layers retain the original value.
3. Incremental PDF saves leave old content streams reachable in the file.
4. A mask is offset by crop, rotation, page-box, or coordinate-transform differences.
5. OCR-based searchable text recreates content inside or next to a redacted region.
6. Metadata or embedded files identify the person or expose the source document.

## Requirements before reconsidering a go decision

- Construct selectable output from sanitized visible content rather than layering text over the original PDF.
- Omit a whole OCR line or token whenever its bounds intersect a redaction, including a conservative margin.
- Preserve the exact source page dimensions and rotation while mapping redaction and text coordinates.
- Remove annotations, forms, optional-content layers, attachments, document metadata, and incremental history.
- Verify zero extractable sensitive strings by searching and copying every page, and run independent OCR over every output page.
- Exercise crop, rotation, mixed page sizes, low-confidence OCR, multi-page files, and every redaction style.
- Keep the flattened output as the default and clearly label any future searchable format with its limits.

This is a product-safety decision, not a claim that searchable protected PDFs are impossible. Apple documents PDFKit text selection/search and page drawing separately; those APIs do not by themselves provide proof that covered source text was removed. See [PDFKit](https://developer.apple.com/documentation/pdfkit) and [PDFPage drawing](https://developer.apple.com/documentation/pdfkit/pdfpage/draw%28with%3A%29).
