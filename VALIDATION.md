# Validación de GameShelf

Esta revisión aplica endurecimiento específico para builds Release con Xcode 26:

- Se evita ordenar `@Query` mediante macros de `SortDescriptor`; el orden se realiza en Swift.
- La relación consola/juegos se mantiene de forma explícita y el borrado en cascada se ejecuta desde la app.
- `GameStatus` declara `Hashable` explícitamente.
- Release usa compilación `singlefile` para diagnósticos más claros.
- GitHub Actions guarda `xcodebuild.log` y `GameShelf.xcresult` cuando el build falla.
- Si `xcodebuild` devuelve un código distinto de cero, el workflow imprime al final las líneas `error:` y las últimas líneas del log.

Validaciones locales efectuadas:

- parseo de todos los `.swift` con Swift;
- sintaxis de `Info.plist`;
- sintaxis de `project.pbxproj`;
- JSON de `Assets.xcassets`;
- dimensiones de los iconos;
- ausencia de API keys incrustadas.

El build iOS completo requiere el SDK de iPhone y se ejecuta en el runner macOS de GitHub Actions.
