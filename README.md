# GameShelf 1.1

Aplicación nativa para iPhone para organizar una colección personal de videojuegos por consola.

## Novedades de 1.1

- Rediseño completo de las tarjetas de consola para que nunca desborden el ancho de la pantalla.
- Cuadrícula principal con dos columnas de ancho idéntico en iPhone.
- Las consolas ya no se muestran como una fotografía recortada de fondo.
- La imagen del hardware se descarga desde Wikipedia y **Apple Vision elimina el fondo localmente en el iPhone**.
- El resultado se guarda como PNG transparente en caché y se presenta con `scaledToFit`, centrado y con márgenes consistentes.
- La misma presentación de dispositivo aislado se usa en la ficha de cada consola.
- Si Vision no consigue realizar el recorte, GameShelf degrada de forma segura a la imagen original o al icono de respaldo.
- Ajustes incluye una acción para regenerar la caché de recortes.
- La fuente de PC pasa a una página centrada en el hardware (`Computer case`) para obtener una imagen más apropiada.
- Las consolas ya guardadas conservan sus juegos y pueden actualizar automáticamente una fuente antigua cuando el preset ha cambiado.

## Qué incluye

- SwiftUI + SwiftData.
- iOS 17 o superior; preparada para compilar con Xcode 26.
- Inicio con tarjetas de consolas y dispositivo aislado sobre fondo transparente.
- Catálogo de consolas: PlayStation, Xbox, Nintendo, Sega, PC y Steam Deck.
- Biblioteca separada por consola.
- Juegos mostrados en cuadrícula con carátula.
- Búsqueda de carátulas relacionadas mediante Wikipedia/Wikimedia.
- Integración opcional con RAWG para identificar el juego, año y plataformas antes de elegir carátula.
- Estados: Jugando, Completado, Pendiente, Pausado y Abandonado.
- Favoritos, valoración de 1 a 5 estrellas y notas.
- Filtros y buscador.
- Datos almacenados exclusivamente en el iPhone mediante SwiftData.
- RAWG API key opcional guardada en Keychain.
- App icon incluido.
- Workflow de GitHub Actions que compila un IPA sin firma para instalar con AltStore Classic.

## Imágenes transparentes de consolas

El flujo es completamente automático:

1. Al añadir una consola, GameShelf consulta la imagen de la página correspondiente de Wikipedia.
2. La app descarga una versión rasterizada de tamaño controlado.
3. `VNGenerateForegroundInstanceMaskRequest` de Apple Vision detecta los objetos principales.
4. GameShelf genera una imagen recortada con el fondo transparente.
5. El PNG resultante se guarda únicamente en la caché local del iPhone.
6. SwiftUI lo presenta con `scaledToFit`, por lo que el dispositivo mantiene su proporción y no puede forzar el ancho de la tarjeta.

No se sube ninguna imagen del usuario ni del dispositivo a un servidor para realizar este proceso.

## Flujo principal

1. Abrir GameShelf.
2. Pulsar `+` y añadir una consola.
3. La app consulta Wikipedia y prepara automáticamente el recorte transparente del dispositivo.
4. Entrar en la consola.
5. Pulsar `+` para añadir un juego.
6. Escribir el nombre del juego.
7. Si hay una RAWG API key configurada, seleccionar primero la coincidencia correcta.
8. GameShelf busca imágenes relacionadas en Wikipedia/Wikimedia y muestra varias opciones.
9. Elegir una carátula.
10. Elegir estado, favorito, valoración y notas.
11. Guardar.

## RAWG es opcional

La app funciona sin RAWG. En ese caso el nombre escrito por el usuario se usa directamente para buscar carátulas.

Si quieres mejorar la identificación de títulos:

1. Consigue una API key personal en `https://rawg.io/apidocs`.
2. Abre `GameShelf > Ajustes`.
3. Pega la API key.
4. Pulsa `Guardar clave`.

La clave se guarda mediante Keychain y no se escribe en el repositorio ni en archivos de configuración.

## Fuentes de imágenes

- Consolas: imagen principal/rasterizada de la página correspondiente de Wikipedia, procesada localmente para eliminar el fondo.
- Carátulas: resultados de páginas de Wikipedia relacionadas con el nombre del juego.
- Si se usa RAWG, la ficha del juego ofrece un enlace a RAWG para cumplir la atribución requerida por el proveedor.

Las imágenes de Wikipedia/Wikimedia pueden tener licencias distintas según el archivo. GameShelf conserva un enlace a la página fuente para que pueda consultarse su procedencia.

## Compilar desde Windows

Consulta `INSTALACION_WINDOWS.md`.

## Privacidad

GameShelf no tiene login, backend, telemetría ni analítica. Las consultas de imágenes se realizan directamente desde el iPhone a Wikipedia y, si el usuario lo configura, a RAWG. El recorte de fondo se realiza enteramente en el dispositivo mediante Apple Vision.
