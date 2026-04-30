# Shield — Pasos manuales completos

> Documento actualizado: 30 de abril de 2026  
> Todo lo que requiere intervención humana (Xcode, portales externos, dominios).  
> Lo que Claude puede hacer por código ya está hecho. Este doc es solo para ti.

---

## ESTADO RÁPIDO

| # | Tarea | Tiempo est. | Bloqueante |
|---|-------|-------------|-----------|
| 1 | Añadir `PrivacyInfo.xcprivacy` al target | 1 min | **Sí — App Store** |
| 2 | Configurar firma de código (Team) | 2 min | Sí — compilar en device |
| 3 | Añadir capability **iCloud + CloudKit** | 3 min | Sí — sync iCloud |
| 4 | Añadir capability **In-App Purchase** | 1 min | Sí — monetización |
| 5 | Añadir URL scheme `shield` en Info.plist | 2 min | Sí — OAuth nube |
| 6 | Crear productos IAP en App Store Connect | 15 min | Sí — monetización |
| 7 | Activar Privacy Policy y Terms of Use | 30 min | **Sí — App Store** |
| 8 | Registrar Client IDs OAuth (Google/Dropbox/OneDrive) | 30 min | No* — opcional |
| 9 | Añadir ícono de app | 5 min | Sí — subir a Store |
| 10 | Crear app en App Store Connect | 10 min | Sí — publicar |
| 11 | Preparar screenshots | 30 min | Sí — publicar |
| 12 | Archive + Upload + Submit | 15 min | Sí — publicar |

\* El selector nativo de archivos iOS ya incluye Google Drive/Dropbox/OneDrive sin OAuth si las apps están instaladas.

---

## 1. Añadir `PrivacyInfo.xcprivacy` al target del build

**Por qué es obligatorio:** Apple rechaza builds desde iOS 17.4+ que usen "Required Reason APIs" (como `UserDefaults`) sin un privacy manifest declarado en el target.

**Pasos:**
1. Abre `Shield.xcodeproj` en Xcode.
2. En el Project Navigator (panel izquierdo), localiza:
   ```
   Shield/Resources/PrivacyInfo.xcprivacy
   ```
3. Haz click en el archivo para seleccionarlo.
4. En el panel derecho (File Inspector), sección **Target Membership**:
   - Marca la casilla junto a **Shield** (el target de la app, no el de tests).
5. Verifica: `Cmd+B` debe compilar sin warning de privacy manifest.

> Si no ves la sección "Target Membership", asegúrate de que estás en el File Inspector (icono de documento, primer tab del panel derecho).

---

## 2. Configurar firma de código (Signing)

**Pasos:**
1. En Xcode, click en el proyecto raíz (`Shield`) en el Navigator.
2. Selecciona el target **Shield**.
3. Tab **Signing & Capabilities**.
4. En **Team**: selecciona tu cuenta de Apple Developer.
   - Si no aparece: Xcode → Settings → Accounts → añade tu Apple ID.
5. Bundle ID: `com.shield.redact`
   - Si ya existe en tu cuenta otro proyecto con ese ID, cámbialo a `com.tuapellido.shield`.
6. Activar **"Automatically manage signing"** (recomendado).

---

## 3. Añadir capability: iCloud + CloudKit

**Por qué es necesario:** `CloudSyncManager` usa el container `iCloud.com.shield.redact`. Sin el entitlement activo, las llamadas a CloudKit fallan silenciosamente.

**Pasos en Xcode:**
1. Target **Shield** → **Signing & Capabilities**.
2. Click en **+ Capability**.
3. Busca y añade **iCloud**.
4. En la sección iCloud que aparece:
   - Marca **CloudKit** (no solo "iCloud Documents").
   - En **Containers**: click en **+** → añade `iCloud.com.shield.redact`.
   - Si prefieres un ID distinto: usa `iCloud.com.tuapellido.shield` y actualiza la línea en `CloudSyncManager.swift`:
     ```swift
     private let container = CKContainer(identifier: "iCloud.com.tuapellido.shield")
     ```
5. Xcode añade automáticamente `Shield.entitlements` con:
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array><string>iCloud.com.shield.redact</string></array>
   <key>com.apple.developer.icloud-services</key>
   <array><string>CloudKit</string></array>
   ```

**En App Store Connect** (necesario para producción):
1. Ve a [developer.apple.com/account](https://developer.apple.com/account) → Certificates, IDs & Profiles → Identifiers.
2. Selecciona el App ID `com.shield.redact`.
3. En **Capabilities**: activa **iCloud** → marca **Include CloudKit support**.
4. Save.

---

## 4. Añadir capability: In-App Purchase

**Pasos en Xcode:**
1. Target **Shield** → **Signing & Capabilities**.
2. Click **+ Capability** → busca **In-App Purchase** → Add.
3. Xcode añade el entitlement automáticamente. No hay configuración adicional.

---

## 5. Añadir URL scheme `shield` en Info.plist

**Por qué:** El flujo OAuth de Google Drive, Dropbox y OneDrive redirige a `shield://oauth/<provider>`. Sin el URL scheme registrado, iOS no abre la app después del login.

**Pasos en Xcode:**
1. En el Navigator, selecciona `Shield/Info.plist`.
2. Haz click derecho → **Open As → Source Code**.
3. Añade dentro de `<dict>` (al final, antes del `</dict>` cierre):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.shield.redact.oauth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>shield</string>
        </array>
    </dict>
</array>
```

4. Guarda (`Cmd+S`).
5. Verifica: en Xcode → Target → Info tab → URL Types, debe aparecer `shield`.

> También añade `NSFaceIDUsageDescription` si no existe ya:
> ```xml
> <key>NSFaceIDUsageDescription</key>
> <string>Shield usa Face ID para proteger tu bóveda de documentos.</string>
> ```

---

## 6. Crear productos IAP en App Store Connect

**URL:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Tu app → In-App Purchases

### 6a. Crear Subscription Group
1. Sección **Subscriptions** → **+ Create Subscription Group**.
2. Nombre del grupo: `Shield Pro`
3. Reference Name: `shield_pro_group`

### 6b. Crear los 3 productos

**Producto 1 — Mensual:**
| Campo | Valor |
|-------|-------|
| Type | Auto-Renewable Subscription |
| Reference Name | Shield Pro Monthly |
| Product ID | `com.shield.redact.pro.monthly` |
| Subscription Group | Shield Pro |
| Duration | 1 Month |
| Price | Tier 3 (~4,99 USD / 4,99 EUR) |
| Display Name (ES) | Shield Pro Mensual |
| Display Name (EN) | Shield Pro Monthly |
| Description (ES) | Acceso completo a todas las funciones de Shield Pro. |
| Description (EN) | Full access to all Shield Pro features. |

**Producto 2 — Anual:**
| Campo | Valor |
|-------|-------|
| Type | Auto-Renewable Subscription |
| Reference Name | Shield Pro Annual |
| Product ID | `com.shield.redact.pro.annual` |
| Subscription Group | Shield Pro |
| Duration | 1 Year |
| Price | Tier 23 (~34,99 USD / 34,99 EUR) |
| Display Name (ES) | Shield Pro Anual |
| Display Name (EN) | Shield Pro Annual |
| Description (ES) | La mejor oferta — acceso completo durante 1 año. |
| Description (EN) | Best value — full access for 1 year. |
| Introductory Offer | 7-day free trial (recomendado) |

**Producto 3 — Lifetime:**
| Campo | Valor |
|-------|-------|
| Type | Non-Consumable |
| Reference Name | Shield Pro Lifetime |
| Product ID | `com.shield.redact.pro.lifetime` |
| Price | Tier 16 (~79,99 USD / 79,99 EUR) |
| Display Name (ES) | Shield Pro — Pago único |
| Display Name (EN) | Shield Pro — Lifetime |
| Description (ES) | Acceso de por vida a Shield Pro. Un pago, para siempre. |
| Description (EN) | Lifetime access to Shield Pro. Pay once, own forever. |

### 6c. Configurar StoreKit local para testing

Para probar compras en el simulador sin cuenta real:
1. Xcode → **Product → Scheme → Edit Scheme**.
2. Tab **Run → Options**.
3. **StoreKit Configuration**: selecciona `Shield/Resources/Shield.storekit`.
4. Los precios y productos del `.storekit` file se usan en el simulador.

---

## 7. Activar Privacy Policy y Terms of Use

**Por qué es obligatorio:** App Store Review Guideline 5.1.1 exige URL de Privacy Policy funcional en el paywall y en App Store Connect. Sin ella, la app es rechazada automáticamente.

### 7a. Crear los documentos legales

**Opción rápida — Generadores gratuitos:**
- [app-privacy-policy.com](https://app-privacy-policy.com) — genera política en ES + EN
- [privacypolicies.com](https://www.privacypolicies.com) — incluye GDPR/CCPA
- [termly.io](https://termly.io) — Privacy Policy + Terms en minutos

**Puntos clave a declarar:**
- La app NO recopila datos personales.
- La app NO envía datos a servidores externos.
- Los documentos se procesan y almacenan localmente en el dispositivo.
- Los documentos cifrados pueden sincronizarse a iCloud (privado, solo para el usuario).
- Los conectores de nube (Google Drive, Dropbox, OneDrive) transfieren archivos al dispositivo para procesarlos localmente.
- Los In-App Purchases son gestionados por Apple.

### 7b. Publicar las URLs

Las URLs que espera la app son exactamente:
- `https://shieldapp.io/privacy`
- `https://shieldapp.io/terms`

**Opciones para hospedarlas:**

**Opción A — Dominio propio (recomendado):**
1. Compra `shieldapp.io` en Namecheap, GoDaddy, etc.
2. Crea dos páginas estáticas con el contenido de los docs.
3. Apunta el DNS a tu hosting (GitHub Pages, Netlify, Vercel — gratis).

**Opción B — GitHub Pages (gratuito, sin dominio):**
1. Crea un repositorio público en GitHub: `shield-legal`.
2. Añade `privacy.html` y `terms.html` con el contenido.
3. Activa GitHub Pages en la configuración del repositorio.
4. URL resultante: `https://tunombre.github.io/shield-legal/privacy.html`
5. Actualiza las URLs en `PaywallView.swift` líneas 14-15:
   ```swift
   private let privacyURL = URL(string: "https://tunombre.github.io/shield-legal/privacy.html")
   private let termsURL   = URL(string: "https://tunombre.github.io/shield-legal/terms.html")
   ```

**Opción C — Notion (más rápido, no recomendado a largo plazo):**
1. Crea dos páginas en Notion con el contenido.
2. Publícalas como páginas web (Share → Publish to web).
3. Usa las URLs de Notion en `PaywallView.swift`.

### 7c. Registrar en App Store Connect
1. App Store Connect → Tu app → App Information.
2. Campo **Privacy Policy URL**: pega la URL de tu política.
3. Save.

---

## 8. Registrar Client IDs OAuth (opcional pero recomendado)

> **Nota:** Sin OAuth los usuarios igualmente pueden importar desde Google Drive, Dropbox y OneDrive si tienen las apps instaladas — el selector nativo de iOS las incluye. El OAuth añade autenticación directa sin necesidad de la app instalada.

### 8a. Google Drive — Google Cloud Console

1. Ve a [console.cloud.google.com](https://console.cloud.google.com).
2. Crea un nuevo proyecto: `Shield App`.
3. APIs & Services → **Enable APIs** → busca y activa **Google Drive API**.
4. APIs & Services → **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**.
5. Application type: **iOS**.
6. Bundle ID: `com.shield.redact`.
7. Copia el **Client ID** generado (formato: `XXXXX.apps.googleusercontent.com`).
8. En la app, guárdalo con:
   ```swift
   UserDefaults.standard.set("TU_CLIENT_ID", forKey: "shield.oauth.google.clientID")
   ```
   O mejor: añádelo en un archivo `Config.plist` no versionado.

### 8b. Dropbox — Dropbox Developer Console

1. Ve a [www.dropbox.com/developers/apps](https://www.dropbox.com/developers/apps).
2. **Create app** → **Scoped access** → **Full Dropbox** (o App folder).
3. App name: `Shield`.
4. Settings → **Redirect URIs**: añade `shield://oauth/dropbox`.
5. Permissions tab: activa `files.content.read`.
6. Copia el **App key** (no el App secret — no se necesita en flujo implícito).
7. Guárdalo:
   ```swift
   UserDefaults.standard.set("TU_APP_KEY", forKey: "shield.oauth.dropbox.appKey")
   ```

### 8c. OneDrive — Azure Portal

1. Ve a [portal.azure.com](https://portal.azure.com) → **Azure Active Directory** → **App registrations**.
2. **New registration**:
   - Name: `Shield`
   - Supported account types: **Accounts in any organizational directory and personal Microsoft accounts**
   - Redirect URI: **Public client/native** → `shield://oauth/oneDrive`
3. API Permissions → Add a permission → **Microsoft Graph** → Delegated:
   - `Files.Read`
   - `offline_access`
4. Copia el **Application (client) ID**.
5. Guárdalo:
   ```swift
   UserDefaults.standard.set("TU_CLIENT_ID", forKey: "shield.oauth.onedrive.clientID")
   ```

---

## 9. Añadir ícono de app

**Requisito:** PNG 1024×1024 px, sin transparencia, sin esquinas redondeadas (iOS las aplica solo).

**Diseño sugerido:**
- Fondo: negro `#0A0A0B`
- Icono: escudo en amarillo `#FFD60A` con trazo fino blanco
- Herramientas: Figma, Canva, SF Symbols Pro, Midjourney

**Pasos en Xcode:**
1. Navigator → `Shield/Resources/Assets.xcassets` → `AppIcon`.
2. Arrastra el PNG 1024×1024 al slot **"App Icon"** (1024 pt, @1x, "All" platform).
3. Xcode genera todos los tamaños automáticamente (desde iOS 13 solo se necesita 1 imagen).

**Generadores automáticos gratuitos:**
- [appicon.co](https://www.appicon.co) — sube 1024×1024, descarga el `.xcassets`
- [makeappicon.com](https://makeappicon.com)

---

## 10. Crear la app en App Store Connect

1. Ve a [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+**.
2. Rellena:
   - **Platform:** iOS
   - **Name:** `Shield — Redact & Protect Docs`
   - **Primary Language:** Español
   - **Bundle ID:** `com.shield.redact` (debe aparecer tras registrar en Xcode con tu Team)
   - **SKU:** `shield-redact-2026`
3. Tras crear, ve a **App Information**:
   - **Subtitle:** `Protege lo que compartes`
   - **Privacy Policy URL:** (del paso 7)
   - **Category:** Productivity / Utilities
4. Ve a **Pricing and Availability**:
   - Price: Free (los ingresos vienen de los IAPs).
   - Territories: All.

### Metadatos de localización (ES)

**Nombre:** `Shield — Redactar Documentos`  
**Subtítulo:** `Protege lo que compartes`  
**Descripción:**
```
Shield oculta datos sensibles de tus documentos antes de compartirlos.
Redacta fotos, DNIs, pasaportes o contratos con un gesto.
Sin servidores. Sin nube. Todo en tu iPhone.

FUNCIONES GRATUITAS:
• Importa PDFs, fotos o escanea con la cámara
• Marco guía por tipo de documento (DNI, pasaporte, A4…)
• 2 estilos de redacción esenciales
• OCR local — detecta campos sensibles automáticamente
• Modos rápidos: Alquiler, Viaje, Empleo, Verificación
• Ajuste de imagen: brillo y contraste
• Exporta hasta 3 veces por semana

SHIELD PRO:
• Documentos y exportaciones ilimitadas
• 9 estilos: pixelado, blur, diagonal, etiqueta…
• Bóveda cifrada AES-256 con Face ID
• Ajuste completo: saturación, nitidez, recorte, volteo, rotación
• Marca de agua personalizable
• Sincronización iCloud entre dispositivos
• Importar desde Google Drive, Dropbox y OneDrive
• Sin marca de agua en las exportaciones
```

**Palabras clave:** `redactar,documentos,privacidad,ocultar,DNI,pasaporte,PDF,datos,proteger,tachar`

### Metadatos de localización (EN)

**Name:** `Shield — Redact & Protect Docs`  
**Subtitle:** `Protect what you share`  
**Description:**
```
Shield hides sensitive data from your documents before you share them.
Redact photos, IDs, passports or contracts with a gesture.
No servers. No cloud. Everything stays on your iPhone.

FREE FEATURES:
• Import PDFs, photos or scan with camera
• Document type guide frame (ID, passport, A4…)
• 2 essential redaction styles
• On-device OCR — auto-detects sensitive fields
• Quick modes: Rental, Travel, Job, Verification
• Image adjustments: brightness & contrast
• Export up to 3 times per week

SHIELD PRO:
• Unlimited documents and exports
• 9 styles: pixelate, blur, diagonal, label…
• AES-256 encrypted vault with Face ID
• Full adjustments: saturation, sharpness, crop, flip, rotate
• Custom watermark
• iCloud sync across devices
• Import from Google Drive, Dropbox and OneDrive
• No watermark on exports
```

**Keywords:** `redact,documents,privacy,hide,ID,passport,PDF,data,protect,black out`

---

## 11. Preparar screenshots

**Tamaños requeridos:**
| Dispositivo | Resolución |
|------------|-----------|
| 6.9" iPhone 16 Pro Max | 1320 × 2868 px (**obligatorio**) |
| 6.5" iPhone 11 Pro Max | 1242 × 2688 px |
| 5.5" iPhone 8 Plus | 1242 × 2208 px |

**Cómo capturar en simulador:**
1. Xcode → ejecutar en simulador **iPhone 16 Pro Max**.
2. Navega a cada pantalla.
3. `Cmd + S` en el simulador para guardar screenshot en el Escritorio.

**Pantallas recomendadas (en este orden):**
1. **Editor con redacciones aplicadas** — muestra el valor principal
2. **Home / Biblioteca** con documentos y badge Free
3. **Scanner con marco guía** (tipo DNI activo)
4. **Galería de estilos** (dark mode)
5. **Paywall / Shield Pro** 
6. **Ajustes de imagen** (toolbar abierto con sliders)

**Herramientas de diseño de screenshots:**
- [AppLaunchpad](https://theapplaunchpad.com) — plantillas iOS gratis
- [Screenshots.pro](https://screenshots.pro)
- Figma con plantillas de iPhone

---

## 12. Archive, Upload y Submit

### 12a. Compilar en Release

1. En Xcode, selector de destino (izquierda arriba): cambia de simulador a **Any iOS Device (arm64)**.
2. Product → **Archive**.
3. Espera a que compile (~2-3 min). Se abre el **Organizer**.

### 12b. Distribuir

1. En el Organizer, selecciona el archive.
2. Click **Distribute App**.
3. Selecciona **App Store Connect** → **Upload**.
4. Opciones: deja todo por defecto (Include bitcode: desactivado en Xcode 14+).
5. Click **Upload**.
6. Espera validación (~5-10 min).

### 12c. Enviar a Review

1. App Store Connect → Tu app → **TestFlight** o directamente **App Store**.
2. Selecciona el build subido.
3. Rellena:
   - **What's New in This Version:** 
     ```
     Versión 1.0 — Lanzamiento inicial
     • Escaneo con marco guía por tipo de documento
     • Editor con redacciones arrastrables y redimensionables
     • Ajustes de imagen profesionales
     • iCloud sync (Pro)
     • Importar desde Google Drive, Dropbox, OneDrive (Pro)
     ```
   - **App Review Information:** añade una cuenta de demo si el reviewer necesita acceso
4. Click **Submit for Review**.

---

## 13. Configuración de StoreKit .storekit para testing local

El archivo `Shield/Resources/Shield.storekit` ya existe. Verifica que contiene los 3 productos con los IDs correctos:

```json
{
  "identifier": "com.shield.redact.pro.monthly",
  "type": "autoRenewable",
  "referenceName": "Shield Pro Monthly"
},
{
  "identifier": "com.shield.redact.pro.annual", 
  "type": "autoRenewable",
  "referenceName": "Shield Pro Annual"
},
{
  "identifier": "com.shield.redact.pro.lifetime",
  "type": "nonConsumable",
  "referenceName": "Shield Pro Lifetime"
}
```

Para activarlo en el scheme:
1. Xcode → Product → **Scheme → Edit Scheme**.
2. Tab **Run → Options**.
3. **StoreKit Configuration** → selecciona `Shield.storekit`.

---

## 14. Checklist final antes de submit

```
[ ] PrivacyInfo.xcprivacy está marcado en Target Membership (paso 1)
[ ] Team configurado en Signing & Capabilities (paso 2)
[ ] Capability iCloud + CloudKit activa (paso 3)
[ ] Container iCloud.com.shield.redact creado en developer.apple.com (paso 3)
[ ] Capability In-App Purchase activa (paso 4)
[ ] URL scheme "shield" en Info.plist (paso 5)
[ ] 3 productos IAP creados en App Store Connect (paso 6)
[ ] Privacy Policy URL activa y accesible (paso 7)
[ ] Terms of Use URL activa y accesible (paso 7)
[ ] URLs en PaywallView.swift apuntan a dominios reales (paso 7b)
[ ] Ícono 1024×1024 en Assets.xcassets (paso 9)
[ ] App creada en App Store Connect con Bundle ID correcto (paso 10)
[ ] Screenshots preparados para 6.9" y 6.5" (paso 11)
[ ] Build compila sin warnings en Release (paso 12a)
[ ] Build subido a App Store Connect (paso 12b)
[ ] Enviado a Review (paso 12c)
```

---

## 15. Frameworks usados — sin dependencias externas

El proyecto usa solo frameworks de Apple (no hay CocoaPods, SPM, ni Carthage):

| Framework | Uso |
|-----------|-----|
| SwiftUI | UI completa |
| StoreKit 2 | In-App Purchases |
| LocalAuthentication | Face ID / Touch ID |
| VisionKit | Scanner de documentos |
| Vision | OCR (VNRecognizeTextRequest) |
| CloudKit | Sync iCloud |
| AuthenticationServices | OAuth (ASWebAuthenticationSession) |
| PDFKit | Render y export PDF |
| CoreImage | Filtros de imagen, perspectiva, blur |
| CryptoKit | AES-256 GCM para cifrado local |
| Security | Keychain para claves de cifrado y PIN |

**No necesitas** `pod install`, `swift package resolve` ni nada similar.  
Solo `Cmd+B` en Xcode.
