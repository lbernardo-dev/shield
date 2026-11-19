# 259-app-store-update-and-whats-new

- Number: 259
- Slug: app-store-update-and-whats-new

## Notes


- El arranque reutiliza la última versión registrada por AppEngagementKit. Para instalaciones anteriores a ese registro, usa el marcador local de instalación.
- La hoja de Novedades comparte contenido localizado con Ajustes y lo lee del bundle para funcionar sin red. En cada release se añade su versión y sus destacados a `AppRelease.highlights(for:)` y a `SettingsInfo.xcstrings`.
- La consulta usa el identificador público de MaskID y el país de StoreKit, con la región del dispositivo como respaldo. Compara versiones numéricas y comprueba el requisito de iOS. El aviso se puede posponer durante siete días.
- La consulta a la App Store de España devolvió MaskID 1.1.7 y un mínimo de iOS 18.0. El build de Debug para iOS Simulator finalizó correctamente.
- Ajusté la presentación para usar el fondo, tarjetas, insignias, separadores y botón principal de Shield. Los textos localizados del bundle y del catálogo se confirmaron en español e inglés.
- En el simulador iPhone 18 Pro dejé seleccionados el tema base y el sonido estacional desactivado. Restauré los valores de prueba de onboarding, Premium y versión vista, sin activar el periodo de acceso.
- El build Debug volvió a finalizar correctamente y la versión 1.1.7 está instalada. La comprobación visual de la hoja quedó interferida por otra app que tomó el primer plano del simulador, así que la confirmé mediante el código y los recursos compilados.
