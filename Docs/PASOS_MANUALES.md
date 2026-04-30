# Shield — Pasos manuales para compilar y publicar

## 1. Abrir el proyecto en Xcode

```
Abre Shield.xcodeproj (doble clic o desde Xcode → Open)
```

> Si Xcode pregunta "Trust and Open": acepta.

---

## 2. Configurar el Team (firma de código)

1. Click en el proyecto raíz en el Navigator → Target **Shield**
2. Tab **Signing & Capabilities**
3. En **Team**: selecciona tu Apple Developer account
4. El Bundle ID ya está configurado: `com.shield.redact`
   - Si ya existe en tu cuenta cambia a uno único, p.ej. `com.tuapellido.shield`

---

## 3. Añadir el ícono de app

El asset catalog está en `Shield/Resources/Assets.xcassets`.

**Opción A — Icono rápido (requerido para compilar en device):**
1. En Xcode → Assets.xcassets → AppIcon
2. Arrastra una imagen PNG de 1024×1024px al slot "App Icon"
3. Diseño sugerido: fondo negro `#0A0A0B`, escudo `⬡` en amarillo `#FFD60A`
   - Puedes generarlo en Figma, Canva, o con IA (Midjourney, DALL-E)

**Opción B — Herramienta automática:**
```
Instala: brew install makeicns  (o usa https://www.appicon.co)
Sube tu PNG 1024×1024 → descarga el set → arrastra a Xcode
```

---

## 4. Configurar StoreKit (In-App Purchases)

### 4a. Para TESTING en simulador (ya incluido)
El archivo `Shield/Resources/Shield.storekit` ya tiene los 3 productos configurados.

En Xcode:
1. **Product → Scheme → Edit Scheme**
2. Tab **Run** → **Options**
3. **StoreKit Configuration**: selecciona `Shield.storekit`
4. Ya puedes comprar en el simulador sin cuenta real

### 4b. Para producción real (App Store)
1. Ve a [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Tu app → **In-App Purchases** → Create
3. Crea exactamente estos 3 productos:

| Product ID | Tipo | Precio sugerido |
|---|---|---|
| `com.shield.redact.pro.monthly` | Auto-Renewable Subscription | 2,99 € |
| `com.shield.redact.pro.annual` | Auto-Renewable Subscription | 19,99 € |
| `com.shield.redact.pro.lifetime` | Non-Consumable | 9,99 € |

4. Subscription Group name: **"Shield Pro"**
5. Añade localización ES + EN para cada producto
6. Espera a que pasen a estado **"Ready to Submit"**

---

## 5. Añadir capability: In-App Purchase

1. Xcode → Target Shield → **Signing & Capabilities**
2. **+ Capability** → busca "In-App Purchase" → Add
3. Xcode añade automáticamente el entitlement

---

## 6. Añadir capability: Face ID (para la Bóveda)

1. Signing & Capabilities → **+ Capability** → "App Transport Security" no, busca directamente
2. Face ID no requiere capability propia — la clave `NSFaceIDUsageDescription` ya está en el build setting del proyecto ✅
3. En device real: la primera vez que el usuario toque "Bóveda" aparecerá el permiso

---

## 7. Compilar y probar en simulador

```
Cmd + R  (simulador iPhone 15 Pro recomendado, iOS 17+)
```

**Flujo de prueba:**
1. Onboarding → 3 pasos → Face ID (simulador lo acepta automáticamente)
2. Home → tap en "DNI · María García" → abre Editor
3. Editor → dibuja rectángulo sobre el doc → aparece redacción negra
4. Editor → botón "Auto" → aplica 4 redacciones automáticas
5. Editor → strip inferior → cambia estilo (Pixelado, Diagonal, etc.)
6. Editor → Exportar → PDF → confirma flow
7. Tab "Estilos" → galería de 9 estilos (primeros 2 libres, resto muestra paywall)
8. Tab "Bóveda" → muestra paywall (pro)
9. Tab "Ajustes" → banner pro → tap → PaywallView

**Para probar compra en simulador:**
- Asegúrate de haber configurado `Shield.storekit` en el scheme (paso 4a)
- Los precios serán los del `.storekit` file, no App Store Connect

---

## 8. Probar en dispositivo físico

1. Conecta iPhone (iOS 17+)
2. En Xcode → selecciona tu device en el selector
3. `Cmd + R`
4. Primera vez pedirá confiar en el developer en iPhone: Ajustes → General → VPN y gestión de dispositivos → Confiar

---

## 9. Preparar para App Store

### 9a. Crear el app en App Store Connect
1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → **+**
2. Platform: iOS | Name: **Shield — Redactar Documentos** | Bundle ID: `com.shield.redact`
3. Idiomas principales: Español + Inglés

### 9b. Metadatos necesarios
Rellena en App Store Connect:
- **Descripción corta (30 chars):** `Protege lo que compartes`
- **Descripción larga:** ver plantilla abajo
- **Keywords:** redactar, documentos, privacidad, ocultar, DNI, pasaporte, PDF
- **Categoría:** Productivity | Subcategoría: Utilities
- **Privacy Policy URL:** obligatorio — puedes generar en [app-privacy-policy.com](https://app-privacy-policy.com)

**Descripción sugerida:**
```
Shield oculta datos sensibles de tus documentos antes de compartirlos.
Redacta fotos, DNIs, pasaportes o contratos con un gesto.
Sin servidores. Sin nube. Todo en tu iPhone.

FUNCIONES:
• Importa PDFs, fotos o escanea con la cámara
• 9 estilos de redacción: negro, pixelado, blur, diagonal…
• Detección automática de campos sensibles (MRZ, número, fecha)
• Modos rápidos: Alquiler, Viaje, Empleo, Verificación
• Marca de agua personalizable
• Exporta como PDF o imagen en alta calidad
• Bóveda cifrada protegida con Face ID

SHIELD PRO:
• Documentos ilimitados
• Todos los estilos premium
• Bóveda cifrada AES-256
• Export PDF real
```

### 9c. Screenshots (OBLIGATORIO)
Necesitas screenshots para cada tamaño:
- **6.9" (iPhone 16 Pro Max):** 1320 × 2868 px — obligatorio
- **6.5" (iPhone 11 Pro Max):** 1242 × 2688 px
- **5.5" (iPhone 8 Plus):** 1242 × 2208 px

**Cómo capturar:**
1. En simulador iPhone 15 Pro → `Cmd + S` (screenshot)
2. O usa el skill `/asc-shots-pipeline` si quieres automatizarlo

**Pantallas a capturar (mínimo 3, recomendado 6):**
1. Home con documentos (dark mode)
2. Editor con redacciones aplicadas
3. Galería de estilos
4. Paywall / Shield Pro
5. Onboarding slide 1
6. Export sheet

---

## 10. Archive y subida

```
Xcode → Product → Archive
```

1. Selecciona el archive → **Distribute App**
2. **App Store Connect** → Upload
3. Espera a que pase la validación (5-10 min)
4. En App Store Connect → selecciona el build → Submit for Review

---

## 11. Qué NO está implementado (trabajo pendiente)

| Feature | Qué falta |
|---|---|
| **Cámara real** | Integrar `AVFoundation` + `VisionKit` para captura + detección de bordes real |
| **OCR real** | Usar `Vision.VNRecognizeTextRequest` sobre la imagen capturada |
| **Export PDF real** | `PDFKit` + `UIGraphicsPDFRenderer` para generar PDF con redacciones aplanadas |
| **Persistencia docs** | Guardar documentos en `FileManager` (JSON + imagen) — hoy reset al relanzar |
| **Imagen del doc** | El editor trabaja sobre SVG/Canvas mock, no sobre foto real del documento |
| **Compartir PDF** | `UIActivityViewController` para compartir el PDF exportado |
| **Ícono de app** | Diseñar y añadir PNG 1024×1024 (ver paso 3) |
| **Privacy Policy** | Generar y hospedar — obligatorio para App Store |
| **Onboarding biométrico real** | `LocalAuthentication` ya está en `VaultView`, falta en el flow inicial |
| **Notificaciones** | Recordatorio "tienes docs sin redactar" — opcional |

---

## 12. Dependencias externas — ninguna

El proyecto usa **solo frameworks de Apple**:
- `SwiftUI` — UI
- `StoreKit` — In-App Purchases
- `LocalAuthentication` — Face ID / Touch ID
- No hay CocoaPods, SPM packages, ni Carthage

No necesitas `pod install` ni `swift package resolve`.

---

## Resumen rápido

```
1. Abre Shield.xcodeproj en Xcode
2. Signing: añade tu Team
3. Añade ícono 1024×1024 en Assets.xcassets
4. Edit Scheme → StoreKit Config → Shield.storekit
5. Cmd+R → simulador iPhone 15 Pro
6. Para producción: crea productos IAP en App Store Connect
7. Archive → Upload → Submit
```
