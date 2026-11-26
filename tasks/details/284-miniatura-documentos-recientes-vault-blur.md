# 284. Miniatura de Documentos Recientes con Difuminado y Vault Overlay

## Contexto y Solicitud del Usuario
El usuario solicitó que en los documentos recientes (tarjeta del Home y listados como "Redacted" / Todos los documentos), en lugar de un icono genérico de maletín/categoría, se visualice una miniatura real del documento procesado. Además, si el documento está protegido por Vault, la miniatura debe aparecer difuminada (`blur`) con el icono de Vault encima.

## Diagnóstico
1. **Ruta fallida en `ThumbnailManager.swift`**: El generador de miniaturas intentaba leer los archivos desde `docs.appendingPathComponent("shield_images")` con `CGImageSourceCreateWithURL`. Sin embargo, `AppState` almacena los documentos cifrados mediante `SecureFileStore` en `library_images` o `vault_images`, lo que provocaba que `ThumbnailManager` siempre devolviera `nil` y `DocumentThumbnailView` cayera al `placeholderView` mostrando el icono de categoría (`briefcase.fill`).
2. **Ausencia de capas de redacción en la miniatura**: La miniatura original solo mostraba la imagen base, sin plasmar las máscaras y censuras aplicadas en la página 0 (`doc.redactions(for: 0)`).
3. **Ausencia de difuminado y badge de Vault unificados**: En la vista de fila `DocumentRow` y `HomeRecentDocumentCard`, no existía una integración que aplicara tanto el desenfoque del contenido procesado como el badge distintivo de la bóveda.

## Cambios Implementados
1. **`Shield/Export/ThumbnailManager.swift`**:
   - Se actualizó el paso 4 de generación de miniaturas para cargar la imagen descifrada a través de `AppState.loadImage(fileName: filename, isVaulted: false)`. Si no se encuentra, mantiene fallback con la ruta legacy del sandbox para compatibilidad con tests unitarios.
   - Las imágenes se redimensionan eficientemente con `downsample(image:maxPixelSize:)` y se almacenan en caché en memoria y en disco.
2. **`Shield/Views/Components/DocumentThumbnailView.swift`**:
   - Ahora renderiza tanto imágenes rasterizadas (`photoContent`) como plantillas vectoriales (`templateContent`), proyectando sobre ellas el trazado de las redacciones de la página (`doc.redactions(for: 0)`) mediante `Canvas` y `BlurRedactionOverlay`.
   - Incorpora la lógica de protección de Vault:
     - Si `doc.isVaulted && !isVaultUnlocked`, la miniatura recibe un desenfoque de radio 7 (`.blur(radius: 7)`).
     - Se superpone un velo de material esmerilado con fondo oscuro translúcido (`.ultraThinMaterial` + `Color.black.opacity(0.35)`).
     - En el centro, se muestra un badge circular con gradiente cyber-violeta (`#6366F1`) y el icono `lock.shield.fill` en blanco.
     - El borde de la tarjeta adopta un fino contorno violeta.
   - Si no está bloqueado por Vault, se muestra la miniatura nítida con sus censuras y un borde sutil.
3. **`Shield/Views/Home/HomeDashboardViews.swift` (`HomeRecentDocumentCard`)**:
   - La propiedad `thumbnail` se simplificó para usar directamente `DocumentThumbnailView` con dimensiones de 104x74, heredando automáticamente la miniatura real procesada y la protección Vault.
4. **`Shield/Views/Home/HomeView.swift` (`DocumentRow`)**:
   - `DocumentRow` ahora utiliza `DocumentThumbnailView(doc: doc, size: CGSize(width: 60, height: 44), isVaultUnlocked: vaultUnlocked)`, garantizando que en el Home, en "Redacted" (`AllDocumentsView`), y en las búsquedas se muestre la miniatura real con las redacciones y el difuminado Vault cuando aplique.
5. **`ShieldTests/EnhancementFeaturesTests.swift` & `SecurityPrivacyTests.swift`**:
   - Validada la suite de miniaturas y añadido test unitario de no-fuga de imágenes de bóveda en disco público.

## Verificación
- **Unit Tests**: Ejecutados en simulador iPhone 18 Pro; pasaron el 100% de los tests de `EnhancementFeaturesTests` y `SecurityPrivacyTests`.
- **Compilación de Dispositivo**: Compilado con éxito para arm64 / iPhone 15 Pro Max.
- **Despliegue Físico**: Instalado el bundle en `/private/var/containers/Bundle/Application/E73EB713-8DD4-4FFF-9BB4-F13700BC44A5/` y lanzado en primer plano con PID **31986**.
