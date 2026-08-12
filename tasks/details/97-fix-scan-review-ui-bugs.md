# 97-fix-scan-review-ui-bugs

- Number: 97
- Slug: fix-scan-review-ui-bugs

## Notes
- Corregido el solapamiento del header superior con la barra de estado de iOS (hora y señal/batería) aumentando el padding superior a `max(topInset + 6, 16)` en `ScanReviewView`.
- Corregida la autoselección errónea de rectángulos pequeños internos (ej. chip del DNI) mediante cálculo del área normalizada del cuadrilátero con filtro `quadArea >= 0.35` en `detectPerspectiveRect`.
- Añadido botón explícito "Restablecer recorte" en `quickGeometrySection` para restaurar la imagen completa con 1 toque.
- Mejorado el layout de herramientas inferiores `controls` con `ScrollView(.vertical, showsIndicators: true)`, padding inferior de 28pt para la Home bar de iOS y un botón primario "Continuar" al final del panel.
