# App de Moda - Login & Register

## 🎨 Paleta de Colores Vibrante y Moderna

La aplicación utiliza una paleta de colores vibrante y enérgica, perfecta para una app de ropa y moda contemporánea:

### Colores Principales
- **Deep Purple** (#6B4CE6) - Púrpura vibrante para elementos principales
- **Hot Pink** (#FF3D8F) - Rosa fucsia brillante para CTAs y acentos
- **Coral** (#FF6B6B) - Coral energético para elementos destacados
- **Mint** (#4ECDC4) - Menta fresca para variaciones
- **Lavender** (#B8A4FF) - Lavanda suave para detalles

### Colores Neutros Modernos
- **Dark Navy** (#1A1F3A) - Azul marino profundo para textos principales
- **Charcoal** (#2D3142) - Carbón moderno para textos secundarios
- **Soft White** (#FFFBFE) - Blanco suave para superficies
- **Cream** (#FFF8F3) - Crema cálido para fondos
- **Light Gray** (#F5F5F7) - Gris claro para divisores

### Colores de Acento Fashion
- **Gold** (#FFD700) - Dorado brillante para elementos premium
- **Peach** (#FFB4A2) - Durazno para toques suaves
- **Sky Blue** (#89CFF0) - Azul cielo para variaciones
- **Rose** (#FFC0CB) - Rosa clásico para detalles

### Degradados
- **Primary Gradient**: Hot Pink → Deep Purple (diagonal)
- **Secondary Gradient**: Coral → Peach (diagonal)

## ✨ Características Implementadas

### Pantalla de Login
- Diseño minimalista y vibrante
- Logo con degradado de hot pink a deep purple
- Animaciones suaves con `animate_do`:
  - `FadeInDown` para el header
  - `FadeInUp` para el formulario
  - `ElasticIn` para botones
- Campo de email con validación
- Campo de contraseña con toggle de visibilidad (icono hot pink)
- Checkbox "Recordarme" (hot pink)
- Botón "¿Olvidaste tu contraseña?" (hot pink)
- Botón principal con fondo hot pink vibrante
- Botones de login social con bordes lavender
- Link a pantalla de registro (hot pink)

### Pantalla de Register
- Diseño consistente con la pantalla de login
- Logo con degradado coral a peach
- Campos de formulario:
  - Nombre completo
  - Email
  - Contraseña
  - Confirmar contraseña
- Validaciones completas:
  - Email válido
  - Contraseñas coinciden
  - Longitud mínima de caracteres
- Checkbox de términos y condiciones (deep purple)
- Links interactivos en hot pink
- Botones de registro social con bordes lavender
- Link a pantalla de login (hot pink)

### Componente Reutilizable
- `AuthTextField`: Widget personalizado para campos de formulario
  - Estilo consistente con colores vibrantes
  - Iconos personalizables en charcoal
  - Labels en dark navy
  - Validación integrada
  - Soporte para texto oculto

## 🎭 Animaciones

Todas las pantallas utilizan animaciones elegantes de `animate_do`:
- **FadeInDown**: Animación de entrada desde arriba para headers
- **FadeInUp**: Animación de entrada desde abajo para formularios
- **ElasticIn**: Animación elástica para botones principales

## 📱 Navegación

La aplicación utiliza `go_router` para la navegación:
- Ruta inicial: `/` (Login)
- Ruta de registro: `/register`

## 🎨 Diseño UI/UX

- Espaciado consistente y generoso
- Tipografía bold y moderna (pesos 600-800)
- Bordes redondeados suaves
- Campos de entrada con fondo soft white y bordes lavender
- Botones con colores vibrantes (hot pink, deep purple)
- Iconos outline para un look moderno
- Sombras coloridas para profundidad (hot pink, coral)
- Degradados en elementos clave
- Divisores sutiles en lavender

## 🚀 Próximos Pasos

- [ ] Implementar lógica de autenticación (backend)
- [ ] Conectar con API de autenticación
- [ ] Agregar manejo de estados (Provider/Riverpod)
- [ ] Implementar recuperación de contraseña
- [ ] Agregar autenticación social real
- [ ] Implementar persistencia de sesión
- [ ] Agregar pantalla de home/productos

## 📝 Notas

- Los formularios tienen validación básica del lado del cliente
- Los handlers de login/register muestran un SnackBar de placeholder
- Los botones sociales están listos para integración futura
- El diseño es completamente responsive
- La paleta de colores es vibrante y moderna, perfecta para moda

---

**Autor**: Desarrollado con Flutter y ❤️
**Versión**: 2.0.0 - Paleta Vibrante
