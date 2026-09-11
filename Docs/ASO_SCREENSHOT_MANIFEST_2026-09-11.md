# MaskID — manifiesto de screenshots ASO

**Generación:** 11 de septiembre de 2026  
**Fuente de copy:** `.asc/aso-screenshot-plan.json`  
**Captura UI:** `scripts/capture_raw_10_scenes.sh` sobre iPhone Air, dark mode, fixtures sintéticos, `ASO_CAPTURE_DELAY=6`  
**Composición:** `scripts/compose_aso_screenshots.py`  
**Salida iPhone:** 20 PNG — 10 `es-ES` + 10 `en-US`, todos `1320×2868`.  
**Salida iPad ASO:** 20 PNG — 10 `es-ES` + 10 `en-US`, todos `2064×2752`, compuestos desde capturas reales iPad.

La captura se considera válida únicamente si la escena pertenece a MaskID, no muestra estados de error y el copy coincide con `Docs/CLAIMS_MATRIX.md`. Los archivos `._*` de resource fork no forman parte del set y se excluyen de la validación.

## Set aprobado para revisión local

| Orden | Asset | Locale | SHA-256 |
|---:|---|---|---|
| 1 | `01-identity-dni.png` | en-US | `126ed9284f19f1b6201709fb619a233bd06aade389302ad4ba1531aa2a62c385` |
| 2 | `02-passport-international.png` | en-US | `7175786677b8f6b3b37faf3003c707e2cb52b7a8f3be5ce06169dcfcb5f48b99` |
| 3 | `03-smart-scanner.png` | en-US | `c4e42ed2626919630ed074af289ecf8400cdd6341cfed9733b9afacaa2edabb1` |
| 4 | `04-ai-ocr-detection.png` | en-US | `5e99819432503677d83047b0f8d2296a1ce401f1a146513cb2fbb09951f900ea` |
| 5 | `05-antifraud-watermark.png` | en-US | `e20cfd31d7e6ea1684487199a15c0b8fdae9fd546299a5595e42aeeb795db09c` |
| 6 | `06-vault-security.png` | en-US | `328977837764023d56ccc9f9f9c84ae40e52c2fbf31130ffe95c5b44618642a4` |
| 7 | `07-library-dashboard.png` | en-US | `a30db9f07365dc0a9d79b66900e3f6a2b66423b625558c52e658433125d05bde` |
| 8 | `08-batch-processing.png` | en-US | `ce1c33916ebe0315fcc1a4eafde976e6617c4c2246f4d29d8441726ca62ce248` |
| 9 | `09-mask-styles.png` | en-US | `42271b098292e89577e16f992558c6c074b0edb46be351cd28058b7ee878774c` |
| 10 | `10-irreversible-export.png` | en-US | `9ff9ef5f4fcdf49d617f8c9b32abfa68fea844d1fe7d762f5f388ee77559991a` |
| 1 | `01-identity-dni.png` | es-ES | `a03fc967b74e41381fb2cb6d83c28dc28b55ab51067188c2862b1a9e3ad8c5c4` |
| 2 | `02-passport-international.png` | es-ES | `dc25354823e534d3541d5382ba628fba1d312d5c594794e52d5e838b9b91a137` |
| 3 | `03-smart-scanner.png` | es-ES | `b8960a1154a497b15070ac383160d7e21e3536f5d19b20de3e88068852510471` |
| 4 | `04-ai-ocr-detection.png` | es-ES | `7be2d15e864cff39b5ac313d696998c2b88bbc5f320f495f54dfdf5de8e45cdd` |
| 5 | `05-antifraud-watermark.png` | es-ES | `31cf1807c230e57d7f0baebf9aea7edb8e5b23435c96a488a4542e0c3f9bc30c` |
| 6 | `06-vault-security.png` | es-ES | `fe3349e6b4f7a86b1d961cf3e874ec96551775333f5f70691937e695abccc5cb` |
| 7 | `07-library-dashboard.png` | es-ES | `4b2517e171d9a81cb866a0bec37c1073420e9f222d0d3a0a923c597f881101b6` |
| 8 | `08-batch-processing.png` | es-ES | `bb64de12b985d71e0a0bedd731d14ba6cb2e21d2d1b6d8caea2a397f57b13957` |
| 9 | `09-mask-styles.png` | es-ES | `032e0fc5c9af15cc028e1d895ae4bc02de9f868705cc5eee1bf4f3c4994ce9e3` |
| 10 | `10-irreversible-export.png` | es-ES | `4265a5cf0a18da212405a83b56559e66e14150e78e30a4e3e96d169607a376a4` |

## Revisión visual

- Contact sheet ES: `.asc/screenshots/aso/review/contact-es-ES.png`
- Contact sheet EN: `.asc/screenshots/aso/review/contact-en-US.png`
- Las 20 escenas muestran MaskID en foreground.
- La escena OCR muestra campos sembrados y estado “Procesado en el dispositivo”, sin “No image available”.
- Bóveda, biblioteca y exportación usan claims compatibles con implementación y política.
- Set cargado y reemplazado en ASC para la versión 1.0.9: 10 assets `COMPLETE` por locale; no se ha iniciado una nueva submission.

## Set iPad ASO aplicado

| Locale | Asset | Fuente real | Dimensiones | SHA-256 | Estado ASC |
|---|---|---|---:|---|---|
| en-US | `01-identity-protection.png` | `maskid-ipad/en-US/01-identity-dni.png` | `2064×2752` | `23dad1178a3bdfe09fba5af84671753fe4beac5933dd338c6503930348611a25` | `COMPLETE` |
| en-US | `02-passport-travel.png` | `maskid-ipad/en-US/02-passport-international.png` | `2064×2752` | `9b2b731d06fc6e512237ca9faf06a7f8cbcfd277ff56144f61f846a6f253fc22` | `COMPLETE` |
| en-US | `03-smart-scanner.png` | `maskid-ipad/en-US/03-smart-scanner.png` | `2064×2752` | `cc99db7ff9f5f653650c9383ac7d9fbebd297ee7073253999e305ac602b6922e` | `COMPLETE` |
| en-US | `04-ai-detection.png` | `maskid-ipad/en-US/04-ai-ocr-detection.png` | `2064×2752` | `4b0163c619c0296df45d853699fd053ee12209aabc5c8e70a5fc79d65e8e73cc` | `COMPLETE` |
| en-US | `05-anti-fraud-watermark.png` | `maskid-ipad/en-US/05-antifraud-watermark.png` | `2064×2752` | `259a2c137abe1a9971ff9bb622f02288a2274835c48006d646e672c130e1d98e` | `COMPLETE` |
| en-US | `06-vault-security.png` | `maskid-ipad/en-US/06-vault-security.png` | `2064×2752` | `f982a97f9b4c48c366debf69a40aea29b04f61b4cc8476d83c9de5bbfc17db9e` | `COMPLETE` |
| en-US | `07-document-hub.png` | `maskid-ipad/en-US/07-library-dashboard.png` | `2064×2752` | `a9664ea30c779d8d27f9f5c7ede0c37ea6e98e7a3988dc7eede7a69d1d9090e6` | `COMPLETE` |
| en-US | `08-batch-protection.png` | `maskid-ipad/en-US/08-batch-processing.png` | `2064×2752` | `7bc7dcfa45fdd9e25f2eac845b4be55c329848675e31a1f1a184f1efaba7fe14` | `COMPLETE` |
| en-US | `09-mask-styles.png` | `maskid-ipad/en-US/09-mask-styles.png` | `2064×2752` | `d5bb181e080c52382b6fe8a7d83fa9f90cd86e8872f6640325f981d3e748a7ae` | `COMPLETE` |
| en-US | `10-verified-export.png` | `maskid-ipad/en-US/10-irreversible-export.png` | `2064×2752` | `27c6db0e656b2b694a037ffdab18211d50fe689dcec2106b1245c824c2913fa4` | `COMPLETE` |
| es-ES | `01-proteccion-identidad.png` | `maskid-ipad/es-ES/01-identity-dni.png` | `2064×2752` | `908fce4f831fa6bda07f099bc88614cc1d1da848c8707e76cddcb53c8102919f` | `COMPLETE` |
| es-ES | `02-pasaportes-viaje.png` | `maskid-ipad/es-ES/02-passport-international.png` | `2064×2752` | `39749ad89bed7ad769310583df6baa768916b8b3585ceb123f06a4dd2f482f43` | `COMPLETE` |
| es-ES | `03-escaner-inteligente.png` | `maskid-ipad/es-ES/03-smart-scanner.png` | `2064×2752` | `7c62a7c6b337352de1533fa86ed805b02e6191a86456c9c0798cf0db7d8ec362` | `COMPLETE` |
| es-ES | `04-deteccion-ia.png` | `maskid-ipad/es-ES/04-ai-ocr-detection.png` | `2064×2752` | `56f0ad9f4a17b249a65c401a6b8b35c3249d98302891068af5cae1087c4e14cc` | `COMPLETE` |
| es-ES | `05-seguridad-antifraude.png` | `maskid-ipad/es-ES/05-antifraud-watermark.png` | `2064×2752` | `a87ee65ceebb63640f79207a23beaaa876592c8f8f7b825b0ab4aac41e73d09c` | `COMPLETE` |
| es-ES | `06-boveda-segura.png` | `maskid-ipad/es-ES/06-vault-security.png` | `2064×2752` | `617b7562171854100fe36ae55c7e76ce52c702a8ca8c7b71c909920b2046a228` | `COMPLETE` |
| es-ES | `07-biblioteca-documentos.png` | `maskid-ipad/es-ES/07-library-dashboard.png` | `2064×2752` | `e05c7303809ca600071a4ef624df5cbd313e8d322c00ced65b251e313fd24862` | `COMPLETE` |
| es-ES | `08-proteccion-lotes.png` | `maskid-ipad/es-ES/08-batch-processing.png` | `2064×2752` | `156c6e6d3fa04c0166803eb1c7c0ef443a24e9ee03702f4cb272732618f88067` | `COMPLETE` |
| es-ES | `09-estilos-mascara.png` | `maskid-ipad/es-ES/09-mask-styles.png` | `2064×2752` | `726495f93e061255f0a814ab0ec11475f392c1dcc87cdfa43691521beeb533f0` | `COMPLETE` |
| es-ES | `10-exportacion-verificada.png` | `maskid-ipad/es-ES/10-irreversible-export.png` | `2064×2752` | `d6d732263237b0d26c15850dbeddc8ee4fdb477dee7164a90bb6022ea2177905` | `COMPLETE` |

Las creatividades locales están en `.asc/screenshots/aso/final-ipad/`. Los veinte assets sustituyeron a los dos screenshots crudos `home.png`/`editor.png` de cada locale en la versión 1.0.9.

### Resubida y comprobación remota final

Tras la revisión final, el set iPad se reemplazó explícitamente y se volvió a consultar en App Store Connect. El estado remoto final es exactamente 10/10 `COMPLETE` en cada locale: `en-US` y `es-ES`, con 20 creatividades ASO procesadas y sin assets crudos en esos sets.
