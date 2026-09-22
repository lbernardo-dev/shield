# 184-move-coffee-button-paywall-scroll

- Number: 184
- Slug: move-coffee-button-paywall-scroll

## Notes

- En `Shield/Views/Paywall/PaywallView.swift`, se extrajo `SupportCoffeeButton` de `ctaSection` (el cual se renderiza dentro del footer flotante/fijo `ShieldStickyFooter`).
- `ShieldStickyFooter` ahora mantiene una altura compacta con el botón principal de CTA ("Iniciar prueba gratis"), el mensaje de error si aplica y los enlaces legales (`footerLinks`).
- `SupportCoffeeButton` se reubicó al final del `ScrollView` principal del Paywall, justo después de `faqSection`, de modo que aparece de forma natural al hacer scroll hasta el final del contenido sin saturar la pantalla ni sobrecargar la barra fija.
- Compilación verificada: `** BUILD SUCCEEDED **` mediante `scripts/xcbuild.sh`.
- App instalada y lanzada en el simulador iPhone 18 Pro (PID 91979).
