# Shield — Pasos manuales completos

> **Última revisión:** 30 de abril de 2026
> **Estado del código:** compila y ejecuta en simulador (iPhone Air, iOS 26.2).
> Todo lo que Claude puede hacer por código ya está hecho. Este documento cubre exclusivamente lo que requiere intervención humana en Xcode, portales de Apple y servicios externos.

---

## ESTADO RÁPIDO

| # | Tarea | Tiempo est. | Bloqueante | Estado |
|---|-------|-------------|-----------|--------|
| 1 | ~~Añadir `PrivacyInfo.xcprivacy` al target~~ | — | ~~Sí — App Store~~ | ✅ Ya hecho |
| 2 | Configurar firma de código (Team) | 2 min | Sí — compilar en device | ⬜ Pendiente |
| 3 | Añadir capability **iCloud + CloudKit** | 3 min | Sí — sync iCloud | ⬜ Pendiente |
| 4 | Añadir capability **In-App Purchase** | 1 min | Sí — monetización | ⬜ Pendiente |
| 5 | Añadir URL scheme `shield` en Info.plist | 2 min | Sí — OAuth nube | ⬜ Pendiente |
| 6 | Crear productos IAP en App Store Connect | 15 min | Sí — monetización | ⬜ Pendiente |
| 7 | Configurar trial 7 días y win-back en App Store Connect | 10 min | Sí — conversión | ⬜ Pendiente |
| 8 | Activar Privacy Policy y Terms of Use | 30 min | **Sí — App Store** | ⬜ Pendiente |
| 9 | Registrar Client IDs OAuth (Google/Dropbox/OneDrive) | 30 min | No* | ⬜ Opcional |
| 10 | Añadir ícono de app | 5 min | Sí — subir a Store | ⬜ Pendiente |
| 11 | Crear app en App Store Connect + metadatos | 30 min | Sí — publicar | ⬜ Pendiente |
| 12 | Preparar screenshots | 30 min | Sí — publicar | ⬜ Pendiente |
| 13 | Archive + Upload + Submit | 15 min | Sí — publicar | ⬜ Pendiente |

\* El selector nativo de archivos iOS ya incluye Google Drive, Dropbox y OneDrive sin OAuth si las apps están instaladas. El OAuth añade autenticación directa sin necesidad de las apps instaladas.

---

## 1. ~~Añadir `PrivacyInfo.xcprivacy` al target~~ — YA COMPLETADO

**Estado:** El archivo `Shield/Resources/PrivacyInfo.xcprivacy` ya existe y está correctamente asignado al target `Shield` en `project.pbxproj` (línea 384: `A028 /* PrivacyInfo.xcprivacy in Resources */`). No necesitas hacer nada.

**Por qué era obligatorio (contexto):** Apple rechaza automáticamente builds desde iOS 17.4+ que usen "Required Reason APIs" — entre ellas `UserDefaults`, que Shield usa para preferencias — sin un privacy manifest declarado. El rechazo ocurre durante la validación automática al subir el build, antes de llegar siquiera a revisión humana. Sin este archivo, todo el trabajo de desarrollo no llegaría a producción.

El manifest actual declara:
- `NSPrivacyTracking: false` — la app no hace tracking publicitario.
- `NSPrivacyTrackingDomains: []` — sin dominios de tracking.
- `NSPrivacyCollectedDataTypes: []` — sin datos recopilados.
- `NSPrivacyAccessedAPITypes: [UserDefaults / CA92.1]` — uso de UserDefaults justificado como "storing user preferences" (razón CA92.1, la correcta para preferencias de la app).

---

## 2. Configurar firma de código (Signing)

**Por qué importa:** Sin una firma válida asociada a tu Apple Developer Program, el build no puede instalarse en un dispositivo físico ni subirse a App Store Connect. Es el primer paso para poder probar en un iPhone real y para publicar.

**Pasos:**
1. Abre `Shield.xcodeproj` en Xcode.
2. Click en el proyecto raíz (`Shield`) en el Navigator.
3. Selecciona el target **Shield** → tab **Signing & Capabilities**.
4. En **Team**: selecciona tu cuenta de Apple Developer.
   - Si no aparece: Xcode → Settings → Accounts → añade tu Apple ID.
5. Bundle ID: `com.shield.redact`
   - Si ya existe otro proyecto con ese ID en tu cuenta, cámbialo a `com.tuapellido.shield` y actualiza también en `CloudSyncManager.swift` la línea del container de CloudKit.
6. Activa **"Automatically manage signing"** — Xcode gestiona los certificados y provisioning profiles automáticamente.

**Verificación:** `Cmd+B` compila sin error de firma. Si conectas un iPhone, aparece como destino válido.

---

## 3. Añadir capability: iCloud + CloudKit

**Por qué importa:** `CloudSyncManager` sincroniza los metadatos de la biblioteca del usuario entre dispositivos usando CloudKit Private Database. Sin el entitlement activo en el build, todas las llamadas a CloudKit fallan silenciosamente — el usuario activa la opción en Ajustes, la app no muestra error, pero nunca sincroniza. Esto destruye la confianza en una función que es ancla de valor Pro.

**El container que espera el código:** `iCloud.com.shield.redact` (definido en `CloudSyncManager.swift`).

**Pasos en Xcode:**
1. Target **Shield** → **Signing & Capabilities**.
2. Click **+ Capability** → busca **iCloud** → Add.
3. En la sección iCloud que aparece:
   - Marca **CloudKit** (no solo "iCloud Documents" — son distintos).
   - En **Containers**: click en **+** → introduce `iCloud.com.shield.redact`.
4. Xcode añade `Shield.entitlements` con:
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array><string>iCloud.com.shield.redact</string></array>
   <key>com.apple.developer.icloud-services</key>
   <array><string>CloudKit</string></array>
   ```

**Pasos en el Apple Developer Portal** (necesario para producción):
1. Ve a [developer.apple.com](https://developer.apple.com) → Certificates, IDs & Profiles → Identifiers.
2. Selecciona el App ID `com.shield.redact`.
3. Capabilities → activa **iCloud** → marca **Include CloudKit support**.
4. Save.

**Si prefieres usar un container con tu propio Bundle ID:**
Cambia en `CloudSyncManager.swift` línea ~5:
```swift
private let container = CKContainer(identifier: "iCloud.com.tuapellido.shield")
```
Y usa ese mismo ID en Xcode.

---

## 4. Añadir capability: In-App Purchase

**Por qué importa:** Sin el entitlement `com.apple.developer.in-app-purchase`, StoreKit 2 no puede cargar los productos desde App Store Connect en producción. El `PremiumManager` no muestra precios, `purchase()` no funciona, y la app llega a la App Store sin capacidad de monetizar. Es el entitlement más crítico después de la firma.

**Pasos en Xcode:**
1. Target **Shield** → **Signing & Capabilities**.
2. Click **+ Capability** → busca **In-App Purchase** → Add.
3. Xcode añade el entitlement automáticamente. No hay configuración adicional.

**Nota sobre testing local:** El archivo `Shield/Resources/Shield.storekit` permite probar compras en el simulador sin este entitlement activo. Pero en producción y TestFlight, el entitlement es imprescindible.

---

## 5. Añadir URL scheme `shield` en Info.plist

**Por qué importa:** El flujo OAuth de Google Drive, Dropbox y OneDrive usa `ASWebAuthenticationSession`. Cuando el usuario completa el login en el navegador del sistema, iOS redirige a `shield://oauth/<provider>` para devolver el control a la app. Sin el URL scheme registrado, iOS no sabe que `shield://` pertenece a Shield y el callback se pierde — el usuario queda bloqueado en el navegador sin retorno. Los conectores de nube quedan inoperativos.

**Pasos en Xcode:**
1. En el Navigator, selecciona `Shield/Info.plist`.
2. Click derecho → **Open As → Source Code**.
3. Añade dentro de `<dict>` (al final, antes del `</dict>` de cierre):

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
5. Verificación: Target → Info tab → URL Types → debe aparecer `shield` con Identifier `com.shield.redact.oauth`.

**Comprobación adicional — NSFaceIDUsageDescription:**
Si no existe ya en el plist, añade:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Shield usa Face ID para proteger tu bóveda de documentos.</string>
```
Sin este string, la app se cuelga al solicitar Face ID por primera vez en un dispositivo real.

---

## 6. Crear productos IAP en App Store Connect

**Por qué importa:** StoreKit 2 carga los productos desde los servidores de Apple usando los Product IDs definidos en `PremiumManager.swift`. Si esos IDs no existen en App Store Connect, `pm.products` queda vacío, el paywall no muestra precios, y ningún usuario puede comprar. Los product IDs son la conexión entre el código y la tienda — deben coincidir exactamente.

**IDs que espera el código** (en `PremiumManager.swift`):
- `com.shield.redact.pro.monthly`
- `com.shield.redact.pro.annual`
- `com.shield.redact.pro.lifetime`

**URL:** [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Tu app → Monetization → In-App Purchases / Subscriptions

### 6a. Crear Subscription Group
1. Sección **Subscriptions** → **+ Create Subscription Group**.
2. Nombre del grupo: `Shield Pro`
3. Reference Name: `shield_pro_group`

### 6b. Crear los 3 productos

**Producto 1 — Mensual:**
| Campo | Valor | Argumento |
|-------|-------|-----------|
| Type | Auto-Renewable Subscription | Ingresos recurrentes predecibles |
| Product ID | `com.shield.redact.pro.monthly` | Debe coincidir exactamente con el código |
| Duration | 1 Month | Barrera de entrada baja para usuarios indecisos |
| Price | Tier 3 (~4,99 USD) | Por debajo de ShareWipe ($X/mes), accesible |
| Display Name (ES) | Shield Pro Mensual | |
| Display Name (EN) | Shield Pro Monthly | |
| Description (ES) | Acceso completo a todas las funciones de Shield Pro. | |
| Description (EN) | Full access to all Shield Pro features. | |

**Producto 2 — Anual (ancla principal):**
| Campo | Valor | Argumento |
|-------|-------|-----------|
| Type | Auto-Renewable Subscription | |
| Product ID | `com.shield.redact.pro.annual` | Debe coincidir exactamente con el código |
| Duration | 1 Year | Mejor LTV, menor churn que mensual |
| Price | Tier 23 (~34,99 USD) | Equivale a ~2,91/mes — el "ahorro" es el argumento de conversión |
| Display Name (ES) | Shield Pro Anual | |
| Display Name (EN) | Shield Pro Annual | |
| Description (ES) | La mejor oferta — acceso completo durante 1 año. | |
| Description (EN) | Best value — full access for 1 year. | |

> El paywall muestra este plan como seleccionado por defecto. El badge de ahorro se calcula automáticamente comparando con el mensual. El trial de 7 días se configura en el paso 7.

**Producto 3 — Lifetime (ancla de precio alto):**
| Campo | Valor | Argumento |
|-------|-------|-----------|
| Type | Non-Consumable | Pago único, sin renovación |
| Product ID | `com.shield.redact.pro.lifetime` | Debe coincidir exactamente con el código |
| Price | Tier 16 (~79,99 USD) | El precio alto hace que el anual parezca razonable (efecto ancla) |
| Display Name (ES) | Shield Pro — Pago único | |
| Display Name (EN) | Shield Pro — Lifetime | |
| Description (ES) | Acceso de por vida a Shield Pro. Un pago, para siempre. | |
| Description (EN) | Lifetime access to Shield Pro. Pay once, own forever. | |

> El lifetime no es el producto principal — es el ancla que sube el valor percibido del anual. No lo pongas como plan destacado en el paywall.

---

## 7. Configurar trial de 7 días y win-back en App Store Connect

**Por qué importa:** El trial reduce la fricción de conversión al eliminar el riesgo percibido: el usuario prueba Pro sin pagar antes de decidir. En apps de privacidad donde el valor se entiende tras usar la app, no antes, el trial suele doblar la tasa de inicio de suscripción frente a un paywall directo. El win-back recupera suscriptores cancelados antes de que pasen 30 días — ventana donde la intención de volver es más alta.

**El `.storekit` local ya tiene el trial configurado para testing** — pero eso solo afecta al simulador. Para producción, el trial debe configurarse en App Store Connect.

### 7a. Configurar Introductory Offer (trial 7 días) en el plan anual

1. App Store Connect → Tu app → Subscriptions → Shield Pro → **Shield Pro Annual**.
2. Sección **Introductory Offers** → **+**.
3. Configura:
   - **Type:** Free Trial
   - **Duration:** 7 days
   - **Eligible customers:** New subscribers only
4. Save.

**Efecto en el código:** `PremiumManager` usa StoreKit 2 y detecta automáticamente el introductory offer. El paywall ya muestra el badge "7 días gratis / 7-day free trial" en el plan anual (implementado en `PaywallView.swift`). El botón CTA se convierte en "Probar gratis 7 días" automáticamente vía StoreKit cuando el usuario es elegible.

### 7b. Configurar Win-back Offer

**Por qué importa:** El 70% de los usuarios que cancelan una suscripción consideran volver en los primeros 30 días. Una oferta de win-back (descuento o período gratis) enviada justo después de la cancelación captura esa intención antes de que se enfríe.

1. App Store Connect → Tu app → Subscriptions → Shield Pro → pestaña **Win-Back Offers**.
2. **+ Create Win-Back Offer**:
   - **Reference Name:** `winback_annual_30off`
   - **Product:** Shield Pro Annual
   - **Offer Type:** Discount (30% off, primer año)
   - **Duration:** 1 year
   - **Eligible subscribers:** Previously subscribed, now lapsed
   - **Eligibility window:** Lapsed within 30 days
3. Save y activa la oferta.

**Nota:** El código de Shield no necesita cambios para detectar win-back offers — StoreKit 2 los presenta automáticamente en el flujo de compra cuando el usuario es elegible y abre el paywall.

---

## 8. Activar Privacy Policy y Terms of Use

**Por qué es obligatorio:** App Store Review Guideline 5.1.1 exige una URL de Privacy Policy funcional en cualquier app que incluya suscripciones o que recopile datos del usuario. Sin ella, la app es rechazada en revisión y en muchos casos ni siquiera supera la validación automática. Además, el paywall de Shield ya enlaza a esas URLs — si no son accesibles, el usuario que pulsa "Privacidad" ve un error, lo que destruye la confianza en el momento más sensible (la decisión de pagar).

**URLs que espera la app** (hardcoded en `PaywallView.swift` líneas 14-15):
- `https://shieldapp.io/privacy`
- `https://shieldapp.io/terms`

### 8a. Qué deben decir los documentos

**Puntos clave que DEBEN declararse** (específicos a Shield):
- La app **no recopila** datos personales del usuario.
- Los documentos se **procesan localmente** en el dispositivo — no se envían a servidores.
- Los documentos cifrados pueden sincronizarse a **iCloud** (base de datos privada de CloudKit, solo accesible por el usuario).
- Los conectores de nube (Google Drive, Dropbox, OneDrive) transfieren archivos **al dispositivo** para procesarlos localmente — no a servidores de Shield.
- El cifrado usa **AES-256** con clave maestra en el **Keychain** del dispositivo.
- Los In-App Purchases son gestionados por **Apple** bajo sus propios términos.
- La telemetría local (logs de eventos) se almacena **en el dispositivo** y nunca sale de él.

**Herramientas para generar los documentos** (gratuitas, incluyen GDPR/CCPA):
- [app-privacy-policy.com](https://app-privacy-policy.com) — genera política en ES + EN en minutos
- [privacypolicies.com](https://www.privacypolicies.com)
- [termly.io](https://termly.io) — Privacy Policy + Terms of Service completos

### 8b. Opciones para hospedar las URLs

**Opción A — Dominio propio `shieldapp.io` (recomendado a largo plazo):**
El dominio transmite profesionalidad en el momento del paywall. Un usuario que ve `shieldapp.io/privacy` confía más que uno que ve `github.io/shield-legal`. Para una app de privacidad, donde la confianza es el producto, el dominio importa.

1. Compra `shieldapp.io` (~$10/año) en Namecheap, Google Domains, etc.
2. Crea dos páginas estáticas: `privacy.html` y `terms.html`.
3. Hostea en GitHub Pages, Netlify o Vercel (gratis, HTTPS automático).
4. Apunta el DNS de `shieldapp.io` al servicio de hosting.
5. Las URLs del código (`PaywallView.swift` líneas 14-15) ya apuntan a este dominio — no necesitas tocar el código.

**Opción B — GitHub Pages sin dominio propio (gratis, funciona para revisión):**
Válido para pasar la revisión de Apple mientras compras el dominio. No es la experiencia final recomendada.

1. Crea un repositorio público: `shield-legal`.
2. Añade `privacy.html` y `terms.html` con el contenido generado.
3. Settings → Pages → Source: `main branch / root`.
4. URLs resultantes: `https://tunombre.github.io/shield-legal/privacy.html`
5. **Actualiza** `PaywallView.swift` líneas 14-15:
   ```swift
   private let privacyURL = URL(string: "https://tunombre.github.io/shield-legal/privacy.html")
   private let termsURL   = URL(string: "https://tunombre.github.io/shield-legal/terms.html")
   ```

**Opción C — Notion (más rápido, no recomendado):**
Funciona para una primera revisión de Apple, pero la URL de Notion tiene el riesgo de romperse si mueves la página, y la experiencia de usuario (carga del editor de Notion en un WebView) es pobre en el momento de la decisión de compra. Úsalo solo si necesitas subir en las próximas 24 horas.

### 8c. Registrar en App Store Connect

1. App Store Connect → Tu app → **App Information**.
2. Campo **Privacy Policy URL**: pega la URL de la política de privacidad.
3. Save.

---

## 9. Registrar Client IDs OAuth (opcional pero recomendado para Pro)

**Por qué importa:** Sin OAuth, los usuarios pueden igualmente importar desde Google Drive, Dropbox y OneDrive si tienen las apps instaladas — el selector nativo de iOS las incluye. Pero si no tienen la app instalada, no pueden conectar. El OAuth añade autenticación directa sin dependencia de apps externas, lo que amplía el alcance del conector Pro y reduce fricción para usuarios que usan la nube desde el navegador.

**Impacto en conversión:** Los conectores de nube son una función explícita de Shield Pro en el paywall. Si no funcionan correctamente, el argumento de venta Pro se debilita.

### 9a. Google Drive — Google Cloud Console

1. Ve a [console.cloud.google.com](https://console.cloud.google.com).
2. Crea un proyecto: `Shield App`.
3. APIs & Services → **Enable APIs** → activa **Google Drive API**.
4. Credentials → **Create Credentials** → **OAuth 2.0 Client ID**.
   - Application type: **iOS**.
   - Bundle ID: `com.shield.redact`.
5. Copia el **Client ID** (formato `XXXXXX.apps.googleusercontent.com`).
6. En `ExternalStorageManager.swift`, busca la línea del Client ID de Google y reemplaza el placeholder:
   ```swift
   // Busca: googleClientID
   private let googleClientID = "TU_CLIENT_ID_AQUI"
   ```

### 9b. Dropbox — Dropbox Developer Console

1. Ve a [www.dropbox.com/developers/apps](https://www.dropbox.com/developers/apps).
2. **Create app** → **Scoped access** → **Full Dropbox**.
3. Settings → **Redirect URIs**: añade `shield://oauth/dropbox`.
4. Permissions tab: activa `files.content.read`.
5. Copia el **App key**.
6. En `ExternalStorageManager.swift`:
   ```swift
   private let dropboxAppKey = "TU_APP_KEY_AQUI"
   ```

### 9c. OneDrive — Azure Portal

1. Ve a [portal.azure.com](https://portal.azure.com) → Azure Active Directory → App registrations.
2. **New registration**:
   - Name: `Shield`
   - Account types: **Accounts in any organizational directory and personal Microsoft accounts**
   - Redirect URI: **Public client/native** → `shield://oauth/oneDrive`
3. API Permissions → Microsoft Graph → Delegated: `Files.Read`, `offline_access`.
4. Copia el **Application (client) ID**.
5. En `ExternalStorageManager.swift`:
   ```swift
   private let oneDriveClientID = "TU_CLIENT_ID_AQUI"
   ```

---

## 10. Añadir ícono de app

**Por qué importa:** App Store Connect rechaza builds sin ícono. Además, el ícono es el primer touchpoint visual de la app — en la categoría de privacidad y seguridad, un ícono que transmita protección y seriedad convierte mejor en las búsquedas de App Store que uno genérico.

**Requisito técnico:** PNG 1024×1024 px, sin transparencia (canal alfa), sin esquinas redondeadas (iOS las aplica automáticamente).

**Concepto recomendado** (consistente con el sistema de diseño existente):
- Fondo: negro `#0A0A0B` (igual que `ShieldTheme.background`)
- Elemento principal: escudo en amarillo `#FFD60A` (el amarillo Shield)
- Opcional: trazo fino blanco o cerradura dentro del escudo

**Herramientas:**
- Figma — control total, exporta a 1024×1024
- [appicon.co](https://www.appicon.co) — sube 1024×1024, descarga el `.xcassets` completo listo para arrastrar
- SF Symbols Pro — para usar el símbolo `shield.fill` como base

**Pasos en Xcode:**
1. Navigator → `Shield/Resources/Assets.xcassets` → `AppIcon`.
2. Arrastra el PNG 1024×1024 al slot **"App Icon"** (1024 pt, @1x, All platforms).
3. Desde iOS 13, Xcode solo necesita una imagen de 1024px — genera todos los tamaños automáticamente.

---

## 11. Crear la app en App Store Connect + metadatos

**Por qué importa:** Los metadatos de App Store (nombre, subtítulo, descripción, palabras clave) determinan en gran medida la discoverability orgánica (ASO). En la categoría de privacidad documental, las búsquedas más frecuentes son "redact", "hide", "PDF", "ID", "passport" — el campo de keywords tiene 100 caracteres y debe usarse completo.

### 11a. Crear la app

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+**.
2. Rellena:
   - **Platform:** iOS
   - **Name:** `Shield — Redact & Protect Docs`
   - **Primary Language:** English (o Spanish, según tu mercado principal)
   - **Bundle ID:** `com.shield.redact`
   - **SKU:** `shield-redact-2026`
3. Tras crear, completa **App Information**:
   - **Subtitle:** `Protect what you share`
   - **Privacy Policy URL:** (del paso 8)
   - **Category:** Productivity (principal) / Utilities (secundaria)
4. **Pricing and Availability**:
   - Price: Free (los ingresos vienen de los IAPs).
   - Territories: All.

### 11b. Metadatos — Español

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

SHIELD PRO — 7 días gratis:
• Documentos y exportaciones ilimitadas
• 9 estilos: pixelado, blur, diagonal, etiqueta REDACTED…
• Bóveda cifrada AES-256 con Face ID
• Modos avanzados: Legal, Salud, Banca
• Ajuste completo: saturación, nitidez, recorte, volteo, rotación
• Marca de agua personalizable
• Sincronización iCloud entre dispositivos
• Importar desde Google Drive, Dropbox y OneDrive
• Sin marca de agua en las exportaciones
• Privacy Score antes de cada exportación
```

**Palabras clave (100 caracteres exactos):**
`redactar,documentos,privacidad,ocultar,DNI,pasaporte,PDF,datos,proteger,tachar,borrar,seguro`

### 11c. Metadatos — English

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

SHIELD PRO — 7-day free trial:
• Unlimited documents and exports
• 9 styles: pixelate, blur, diagonal, REDACTED label…
• AES-256 encrypted vault with Face ID
• Advanced modes: Legal, Health, Banking
• Full adjustments: saturation, sharpness, crop, flip, rotate
• Custom watermark
• iCloud sync across devices
• Import from Google Drive, Dropbox and OneDrive
• No watermark on exports
• Privacy Score before every export
```

**Keywords (100 chars):**
`redact,documents,privacy,hide,ID,passport,PDF,data,protect,black out,secure,blur,sensitive`

---

## 12. Preparar screenshots

**Por qué importa:** Los screenshots son el factor de conversión número uno en la página de App Store — más que la descripción, que la mayoría no lee. En la categoría de privacidad, los screenshots que más convierten muestran el problema resuelto (un documento con datos ocultos, listo para compartir), no las herramientas. El usuario debe poder decir "eso es exactamente lo que necesito" en menos de 3 segundos.

**Tamaños requeridos por Apple:**
| Dispositivo | Resolución | Obligatorio |
|------------|-----------|-------------|
| 6.9" iPhone 16 Pro Max | 1320 × 2868 px | **Sí** |
| 6.5" iPhone 11 Pro Max | 1242 × 2688 px | Recomendado |
| 5.5" iPhone 8 Plus | 1242 × 2208 px | Si quieres cubrir iOS antiguo |

**Cómo capturar en simulador:**
1. Xcode → ejecutar en simulador **iPhone 16 Pro Max**.
2. Navega a la pantalla deseada.
3. Simulador → `Cmd+S` → guarda en el Escritorio.

**Pantallas recomendadas (en este orden narrativo):**

1. **Editor con redacciones aplicadas** — mensaje: "oculta lo sensible en segundos". Muestra un DNI con redacciones en pixelado o blur y el Privacy Score en verde.
2. **Exportar: Privacy Score** — muestra el panel colapsable con puntuación 95/100 y los 4 checks en verde. Mensaje: "sabes exactamente qué estás compartiendo".
3. **Scanner con marco guía** — muestra el overlay del tipo "DNI" con las zonas OCR dibujadas. Mensaje: "captura perfecta desde el primer intento".
4. **Modos rápidos** — muestra los chips Legal/Salud/Banca con lock de Pro y los libres activos. Mensaje: "redacción automática por caso de uso".
5. **Home / Biblioteca** — muestra la colección de documentos con categorías y el badge "2/3 documentos" Free.
6. **Paywall con trial** — muestra el plan anual seleccionado con el badge "7 días gratis" en verde.

**Herramientas de diseño de screenshots** (para añadir títulos y marcos de dispositivo):
- [AppLaunchpad](https://theapplaunchpad.com) — plantillas iOS gratuitas
- [Screenshots.pro](https://screenshots.pro)
- Figma con mockups de iPhone

---

## 13. Archive, Upload y Submit

**Por qué es el paso final:** El Archive compila el código en modo Release (optimizaciones activadas, debug info eliminada), lo firma con el certificado de distribución y lo empaqueta para App Store Connect. Sin este paso, nada de lo anterior llega a los usuarios.

### 13a. Compilar en Release

1. Selector de destino en Xcode (arriba izquierda): cambia el simulador a **Any iOS Device (arm64)**.
2. Product → **Archive**.
3. Espera ~2-5 min. Se abre el **Organizer** automáticamente.

### 13b. Distribuir a App Store Connect

1. En el Organizer, selecciona el archive más reciente.
2. Click **Distribute App**.
3. Selecciona **App Store Connect** → **Upload**.
4. Deja todas las opciones por defecto (Strip Swift symbols: sí, Upload symbols: sí).
5. Click **Upload**.
6. Espera la validación automática de Apple (~5-15 min). Recibirás un email cuando el build esté disponible.

### 13c. Enviar a Review

1. App Store Connect → Tu app → **App Store** → selecciona el build subido.
2. Rellena **What's New in This Version (v1.0)**:
   ```
   Versión 1.0 — Lanzamiento inicial

   • Escaneo multipágina con marco guía por tipo de documento
   • OCR local con detección automática de campos sensibles
   • 7 modos rápidos de redacción (Alquiler, Viaje, Empleo, Legal, Salud, Banca, Verificación)
   • Ajustes de imagen profesionales persistidos en el documento
   • Privacy Score antes de exportar
   • Bóveda cifrada AES-256 con Face ID (Pro)
   • Sincronización iCloud entre dispositivos (Pro)
   • Eliminación automática de metadatos EXIF/GPS al exportar
   ```
3. **App Review Information**: si la app requiere autenticación para que el reviewer pueda probarla, proporciona una cuenta de demo o instrucciones para saltarse la autenticación en la sección "Notes".
4. Click **Submit for Review**.

**Tiempo esperado de revisión:** 24-48 horas para primera revisión. Si hay rechazo, Apple especifica el motivo con exactitud y el reenvío suele aprobarse en 24 horas.

---

## 14. Checklist final antes de submit

```
Seguridad y compliance
[ ] Capability iCloud + CloudKit activa (paso 3)
[ ] Container iCloud.com.shield.redact creado en developer.apple.com (paso 3)
[ ] Capability In-App Purchase activa (paso 4)
[ ] URL scheme "shield" registrado en Info.plist (paso 5)
[ ] NSFaceIDUsageDescription en Info.plist (paso 5)

Monetización
[ ] Subscription Group "Shield Pro" creado en App Store Connect (paso 6)
[ ] 3 productos IAP con IDs exactos creados y en estado "Ready to Submit" (paso 6)
[ ] Introductory Offer 7 días configurado en plan anual (paso 7a)
[ ] Win-back offer configurado (paso 7b)

Compliance legal
[ ] Privacy Policy URL activa y accesible (paso 8)
[ ] Terms of Use URL activa y accesible (paso 8)
[ ] URLs en PaywallView.swift apuntan a dominios reales con contenido (paso 8)
[ ] Privacy Policy URL registrada en App Store Connect → App Information (paso 8c)

Assets
[ ] Ícono 1024×1024 px en Assets.xcassets/AppIcon (paso 10)
[ ] Screenshots para 6.9" iPhone 16 Pro Max (paso 12)

App Store Connect
[ ] App creada con Bundle ID com.shield.redact (paso 11)
[ ] Metadatos ES y EN completados (paso 11)
[ ] Build compilado en Release sin warnings (paso 13a)
[ ] Build subido y validado por Apple (paso 13b)
[ ] Enviado a Review con "What's New" completo (paso 13c)
```

---

## 15. Frameworks usados — sin dependencias externas

El proyecto usa exclusivamente frameworks de Apple. No hay CocoaPods, Swift Package Manager, ni Carthage. Solo `Cmd+B` en Xcode.

| Framework | Uso en Shield |
|-----------|--------------|
| SwiftUI | UI completa (28 archivos Swift) |
| StoreKit 2 | IAPs: suscripciones y lifetime |
| LocalAuthentication | Face ID / Touch ID para vault y lock screen |
| VisionKit | Scanner de documentos con VNDocumentCameraViewController |
| Vision | OCR con VNRecognizeTextRequest, MRZ, confianza de campos |
| CloudKit | Sincronización de metadatos en Private Database |
| AuthenticationServices | OAuth con ASWebAuthenticationSession |
| PDFKit | Leer y generar PDFs |
| CoreImage | Filtros de imagen, blur gaussiano, ajustes de color |
| ImageIO | Exportación JPEG sin metadatos EXIF/GPS |
| CryptoKit | AES-256-GCM para cifrado de archivos locales |
| Security | Keychain para clave maestra y PIN |
| Combine | Timer de inactividad para auto-lock |
