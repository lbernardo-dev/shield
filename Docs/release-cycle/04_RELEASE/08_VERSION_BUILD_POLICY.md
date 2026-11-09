# Política de versión y build

## Candidato actual

- Versión pública indicada por el propietario: **1.1.7**.
- Fecha de build: 2026-11-08, Europe/Madrid.
- Combinación confirmada por `scripts/next_release_build_number.py --version 1.1.7`: `1172026110801`; ASC consultado, sin coincidencias existentes, `writesPerformed:false`.
- Secuencia diaria: `01` para la combinación de versión 1.1.7 y fecha indicada. Los archivos de 1.2.0 generados durante esta auditoría tienen otra versión y no colisionan con la numeración consultada.

## Fórmula obligatoria

Versión sin puntos 1.1.7 → 117  
Fecha Europe/Madrid → 20261108  
Consecutivo diario → 01  
CFBundleVersion → 1172026110801

`CFBundleShortVersionString` y `MARKETING_VERSION` son 1.1.7. App, Share Extension y Widget Extension deben coincidir en Xcode, archive e IPA.

## Cambio de instrucción y artefactos previos

Al inicio de Fase 04 se preparó localmente 1.2.0, builds `1202026110801` y `1202026110802`. El propietario indicó después que la versión correcta es 1.1.7 y especificó `1172026110801`. Los artifacts locales 1.2.0 se preservan como candidatos reemplazados; no se cargaron ni publicaron. El archive y el IPA de entrega se regeneran con la versión/build actuales.

## Compatibilidad pendiente

La consulta de ASC de solo lectura no muestra colisión de `1.1.7 / 1172026110801`. El script no escribe en el proyecto ni en ASC. La documentación vigente de Apple describe `CFBundleVersion` como uno a tres enteros separados por puntos y permite solo dígitos y puntos; no publica en esa página una longitud máxima por componente. El valor solicitado es un solo componente de 13 dígitos, por lo que su aceptación de distribución en ASC no está demostrada y queda como bloqueo de release hasta procesar un build. No se cambia el formato indicado por el propietario ni se sube sin autorización. Referencia: [CFBundleVersion — Apple Developer](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleversion).
