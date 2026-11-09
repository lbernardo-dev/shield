# Metadatos de App Store — español (España)

Borrador propuesto para la versión 1.1.7. Los metadatos version-scoped (descripción, keywords, texto promocional y novedades) se sincronizaron y leyeron de vuelta en ASC. Nombre y subtítulo de este archivo no se cambiaron: el `app-info` compartido de la ficha pública se dejó intacto. El proyecto y la ficha pública acreditan inglés (EE. UU.) y español (España); no hay evidencia de otros idiomas de ficha.

| Campo | Borrador | Límite |
|---|---|---:|
| Nombre | MaskID: Protege Datos Privados | 30 caracteres |
| Subtítulo | Oculta Datos al Compartir | 30 caracteres |
| Palabras clave | `dni,pasaporte,documentos,redactar,privacidad,identidad,iban,firma,escaner,pdf,contratos,boveda` | 100 bytes UTF-8 |
| Texto promocional | Tapa solo lo necesario, revisa cada página y comprueba en el dispositivo la copia protegida antes de compartirla. | 170 caracteres |
| Descripción | Ver `version/1.1.7/es-ES.json` | 4.000 caracteres |
| Novedades | Ver `version/1.1.7/es-ES.json` | 4.000 caracteres |
| Política de privacidad | https://lbernardo-dev.github.io/apps/es/casos/shield/privacidad/ | URL |
| Soporte | https://lbernardo-dev.github.io/apps/es/casos/shield/soporte/ | URL |
| Marketing | https://lbernardo-dev.github.io/apps/es/casos/shield/ | URL |

Conteos automáticos de `scripts/validate_release_metadata.py`:

| Campo | Caracteres | Bytes UTF-8 | Límite | Resultado |
|---|---:|---:|---:|---|
| Nombre | 30 | 30 | 30 | PASS |
| Subtítulo | 25 | 25 | 30 | PASS |
| Palabras clave | 94 | 94 | 100 | PASS |
| Texto promocional | 113 | 114 | 170 | PASS |
| Descripción | 2.247 | 2.288 | 4.000 | PASS |
| Novedades | 532 | 542 | 4.000 | PASS |

El texto explica los 15 días de acceso interno, la migración 30+30 días de usuarios Free previos y el requisito de plan de pago tras el acceso temporal. No lo llama prueba de App Store y remite a Apple para el precio y la renovación vigentes. La aprobación jurídica sigue pendiente.
