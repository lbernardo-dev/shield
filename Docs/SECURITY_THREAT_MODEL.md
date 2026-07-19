# Modelo de amenazas de Shield

## Datos protegidos

Shield protege imágenes originales, previsualizaciones renderizadas, PDF de origen,
metadatos documentales, evidencia OCR y telemetría local. Todos esos activos se
guardan cifrados con AES-GCM y protección de archivos `complete`.

La biblioteca y la bóveda usan claves maestras distintas. La clave de la bóveda se
crea en Keychain con `WhenPasscodeSetThisDeviceOnly`; mover un documento a la bóveda
lo descifra y vuelve a cifrar de forma transaccional con la clave separada. Si la
operación no puede completarse, el documento conserva su ubicación y estado previos.

## Adversarios contemplados

- Otra app sin acceso al sandbox.
- Lectura de una copia física de archivos cuando el dispositivo está bloqueado.
- Observación del selector de aplicaciones mientras Shield está inactivo.
- Intentos repetidos de adivinar el PIN local.
- Recuperación de texto o metadatos desde un PDF exportado.
- Fallos parciales o cancelación durante importación, traslado o exportación.

## Controles

- AES-GCM autenticado, claves no sincronizables y vinculadas al dispositivo.
- PIN de seis cifras derivado con sal aleatoria y 60.000 iteraciones HMAC-SHA256;
  comparación constante y bloqueo exponencial persistido en Keychain.
- Face ID/Touch ID mediante LocalAuthentication; el PIN es un mecanismo alternativo.
- Pantalla neutra inmediata al pasar a estado inactivo y cierre de la sesión de bóveda.
- Exportación rasterizada, sin metadatos heredados, seguida de verificación adversarial.
- Temporales con nombres únicos, protección completa y eliminación al abandonar el flujo.
- Telemetría exclusivamente local, cifrada, acotada y limitada a claves enumeradas sin PII.
- Borrado de todos los assets conocidos del documento, incluidos originales y fuentes.

## Límites explícitos

- Shield no impide una fotografía externa de la pantalla ni las capturas de pantalla
  iniciadas conscientemente por el usuario mientras la app está activa.
- Un dispositivo ya desbloqueado y comprometido, o un proceso con control total del
  sistema, queda fuera del modelo de amenazas.
- La bóveda añade separación de clave y control de acceso dentro de Shield; no sustituye
  el código del dispositivo ni un sistema de gestión empresarial.
- Los estilos de desenfoque, píxel y semitransparencia son visuales. En exportaciones
  verificadas se convierten en máscaras opacas.

## Validación de seguridad

Cada release debe superar build con concurrencia estricta, tests de cifrado/traslado/
borrado, tests de PIN, pruebas adversariales de PDF y un smoke test de bloqueo UI.
