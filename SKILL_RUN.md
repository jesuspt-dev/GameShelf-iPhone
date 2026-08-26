# Ejecución de ejemplo — iphone-app-on-demand

## Prompt de ejemplo

> Quiero una app nativa para mi iPhone llamada GameShelf para registrar todos los videojuegos que juego. En la pantalla principal quiero tener una sección/tarjeta por cada consola que yo añada (PC, PS5, Switch, Xbox, etc.) y quiero que la tarjeta muestre una imagen de la propia consola. Al tocar una consola quiero ver mi biblioteca de esa plataforma en forma de cuadrícula con las carátulas de los juegos. Cuando añada un juego, escribiré su nombre y la app deberá buscar automáticamente varias opciones de carátula para que pueda elegir la correcta. Quiero poder marcar cada juego como Jugando, Completado, Pendiente, Pausado o Abandonado, añadirlo a favoritos, darle de 1 a 5 estrellas y guardar notas. Todo debe guardarse localmente en mi iPhone. Trabajo desde Windows, así que prepara también el proyecto Xcode, el workflow de GitHub Actions para generar un IPA sin firmar con Xcode 26 y los scripts necesarios para subirlo a GitHub e instalarlo después con AltStore.

## Decisiones aplicadas

- Arquitectura nativa SwiftUI.
- Persistencia local con SwiftData.
- Keychain para la API key opcional.
- Wikipedia/Wikimedia como búsqueda de imágenes sin credenciales.
- RAWG como fuente opcional para identificación del juego.
- Atribución mediante enlaces desde la app.
- Sin backend, cuenta de usuario ni telemetría.
- Build reproducible mediante GitHub Actions.
- Sideload mediante AltStore Classic.

## Resultado

El repositorio entregado contiene la aplicación completa, el proyecto Xcode, recursos, workflow de compilación, scripts para Windows y documentación de instalación.
