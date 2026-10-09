# Brew

App iOS en SwiftUI y SwiftData para registrar cafés, preparar con cuatro métodos y mejorar el siguiente intento mediante recomendaciones locales.

## Alcance actual

- Biblioteca de cafés, edición, archivo y restauración.
- Setup manual o receta inicial para V60, AeroPress, French Press y Espresso.
- Pasos guiados con objetivos de tiempo y agua; copia de los pasos dentro de cada brew.
- Timer con pausa, reanudación y recuperación tras cerrar la app.
- Evaluación opcional, notas editables y recomendaciones sobre una variable.
- Historial, Top 3 y repetición con o sin ajuste.
- Pruebas unitarias y flujos completos de UI.

Por tiempo, equipo guardado, onboarding y Settings quedan fuera de esta entrega. Las recetas iniciales son puntos de partida ajustables, no una garantía de resultado.

## Ejecutar

Abrir `Brew.xcodeproj`, elegir el scheme `Brew` y ejecutar en un simulador o dispositivo con iOS 26.5 o posterior. Para un dispositivo físico, configurar el equipo de firma en Xcode.

```sh
xcodebuild test -project Brew.xcodeproj -scheme Brew \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
```

Las pruebas de UI crean un café desde la interfaz y usan una base independiente por prueba. La misma base se reutiliza al relanzar la app dentro de esa prueba para comprobar persistencia; no se toca la biblioteca habitual. Esta selección de almacenamiento solo está disponible en builds Debug.
