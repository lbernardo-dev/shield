# MaskID — estrategia de mercado, marca y ASO

Fecha: 19 de julio de 2026

## Posicionamiento

MaskID protege la identidad de una persona antes de que comparta un documento. Permite localizar, revisar y enmascarar datos sensibles en DNI, NIE, pasaportes, permisos de conducir, extractos, contratos, fotografías y PDF, y genera una copia rasterizada cuya zona protegida se comprueba antes de compartir.

La categoría propia de la marca es **protección de identidad documental**, no “editor PDF” ni “escáner” genérico. El trabajo principal del usuario es: «Necesito demostrar algo con este documento sin entregar toda mi identidad».

## Mercado y señales de demanda

El mercado se divide en cuatro grupos:

1. Editores PDF generalistas como Adobe Acrobat, Foxit y PDF Expert. Tienen amplitud funcional y marca, pero la redacción segura suele estar dentro de planes profesionales y no es el centro del recorrido móvil.
2. Herramientas rápidas de marcado como Whiteout. Convierten bien la intención “tachar/blur”, pero pueden percibirse como edición visual y no como protección verificable.
3. Apps privacy-first especializadas como StripPii, ID‑Shield, CoverID y PrivyMask. Compiten directamente en privacidad local, OCR, documentos de identidad y eliminación de metadatos.
4. Alternativas gratuitas o manuales: Marcación de iOS, capturas recortadas, rectángulos superpuestos o servicios web. Son accesibles, pero el usuario teme dejar texto OCR, metadatos o información fuera de la zona cubierta.

Las señales cualitativas recientes convergen en cinco necesidades:

- Evitar subir DNI, contratos o documentos médicos a servidores externos.
- Encontrar datos dispersos sin confiar ciegamente en la automatización.
- Saber que el rectángulo no es meramente cosmético.
- Compartir solo lo necesario para alquiler, empleo, viaje o verificación.
- Eliminar texto OCR, GPS, EXIF y otros datos que no se ven a simple vista.

Fuentes de contraste: [StripPii](https://apps.apple.com/us/app/strippii/id6759972387), [Whiteout](https://apps.apple.com/us/app/whiteout-redact-blur-photos/id1642452158), [ID‑Shield](https://apps.apple.com/us/app/id-shield-keep-ids-secure/id6760896003), [RedactID](https://redactid.io/) y conversaciones recientes sobre [revisión de documentos y capas OCR](https://www.reddit.com/r/ProductivityApps/comments/1rc0u7j/anyone_using_tools_to_redact_documents_faster/).

## Segmentos prioritarios

### Personas que comparten una identificación

Alquileres, hoteles, viajes, compraventa, recuperación de cuentas o procesos KYC. Su disparador es una petición inmediata de DNI o pasaporte. Buscan “ocultar datos DNI”, “redact ID”, “hide passport details” o “protect identity document”.

### Profesionales y autónomos

Comparten contratos, informes, nóminas, facturas y archivos de clientes. Priorizan PDF multipágina, lotes, OCR, firma, dirección, datos bancarios y una salida comprobable.

### Usuarios preocupados por privacidad

Rechazan cuentas, anuncios, tracking y cargas a la nube. Responden a “on device”, “offline”, “no account”, “private OCR” y “metadata removal”.

## Diferenciación defendible

- Procesamiento y OCR en el dispositivo.
- Revisión humana explícita en lugar de prometer detección infalible.
- Exportación rasterizada y verificación de texto residual en zonas ocultas.
- Eliminación de metadatos EXIF/GPS en exportaciones compatibles.
- Recorrido completo: importar o escanear, detectar, enmascarar, comprobar y compartir.
- Biblioteca cifrada, Vault y flujos multipágina/lote.

## Arquitectura ASO

Apple indexa nombre, subtítulo y keywords. La estrategia evita repetir palabras exactas entre esos campos y reserva la descripción para conversión semántica y casos de uso.

### English (U.S.)

- Name: `MaskID: Redact PDF & Photos` — 27/30
- Subtitle: `Protect identity & documents` — 28/30
- Keywords: `privacy,scanner,OCR,passport,license,IBAN,metadata,blackout,censor,offline,secure,PII,personal,data` — 99/100
- Intención principal: redact PDF/photos, protect identity/documents.
- Intenciones combinatorias: private document scanner, offline OCR, passport redactor, censor personal data, secure metadata, PII blackout.

### Español (España)

- Nombre: `MaskID: Oculta DNI y datos` — 26/30
- Subtítulo: `Protege identidad y documentos` — 30/30
- Keywords: `privacidad,PDF,fotos,escáner,OCR,IBAN,pasaporte,firma,dirección,metadatos,tachar,censurar,seguro,ID` — 99/100
- Intención principal: ocultar DNI/datos, proteger identidad/documentos.
- Intenciones combinatorias: censurar PDF, ocultar dirección, tachar firma, escáner privado, proteger pasaporte, eliminar metadatos.

No se rellenan caracteres con términos irrelevantes: un carácter vacío es preferible a degradar relevancia, legibilidad o cumplimiento.

## Conversión visual

El icono utiliza un rostro humano neutral y una franja central de píxeles. Comunica identidad, protección y enmascaramiento sin recurrir a los símbolos saturados de candado o escudo.

Paleta:

- Midnight Navy `#071426`: privacidad, control y confianza.
- Electric Cyan `#20C7D9`: acción, detección local y elemento pixelado.
- Cool Blue `#4E7BFF`: profundidad tecnológica secundaria.
- Off-white: humanidad y contraste.

El orden de capturas sigue el recorrido de decisión:

1. Protege tu identidad.
2. Escanea o importa.
3. Oculta solo lo sensible.
4. Detecta datos con OCR.
5. Exporta una copia verificada.
6. Elige el estilo de máscara.
7. Guarda documentos privados.
8. Procesa lotes.
9. Explica MaskID Pro.
10. Refuerza privacidad y control.

## Hipótesis posteriores al lanzamiento

Medir por locale impresiones, product-page views, conversión y retención de búsqueda. Priorizar tres pruebas secuenciales, sin solaparlas:

1. Mensaje principal: `Protect your identity` frente a `Redact before sharing`.
2. Caso de uso en primera captura: documento de identidad frente a PDF profesional.
3. Subtítulo español: identidad/documentos frente a pasaporte/privacidad, según términos reales de adquisición.

No cambiar keywords durante al menos un ciclo suficiente para observar tendencia. Las decisiones posteriores deben basarse en Search Ads/Search Match, App Analytics y consultas de soporte, no en estimaciones de volumen no verificables.

## Límites de comunicación

No prometer detección del 100 %, anonimato absoluto ni irreversibilidad universal. Utilizar “copia verificada” únicamente cuando el verificador haya finalizado correctamente y recordar al usuario que revise todas las páginas antes de compartir.
