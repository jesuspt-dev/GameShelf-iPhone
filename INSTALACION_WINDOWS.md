# GameShelf — compilar e instalar en iPhone desde Windows

El proyecto está preparado para el mismo flujo de sideloading utilizado en las apps anteriores: Windows se usa para editar/subir el código, GitHub Actions ejecuta Xcode 26 en macOS, genera un IPA sin firma y AltStore Classic lo firma localmente con el Apple ID al instalarlo.

## 1. Comprobación local

Ejecuta:

```text
COMPROBAR_PROYECTO.bat
```

Comprueba que estén presentes los archivos esenciales del proyecto.

## 2. Crear un repositorio GitHub

Crea un repositorio vacío, por ejemplo:

```text
gameshelf-iphone
```

Puede ser privado. No añadas README, `.gitignore` ni licencia desde GitHub porque el proyecto ya los contiene.

## 3. Subir desde Windows

Método rápido:

```text
SUBIR_A_GITHUB.bat
```

El script:

- comprueba Git;
- inicializa el repositorio local si hace falta;
- crea el commit;
- configura `main`;
- pide la URL HTTPS del repositorio si todavía no existe `origin`;
- ejecuta `git push`.

También puede hacerse manualmente:

```powershell
git init
git add .
git commit -m "GameShelf 1.0 - iPhone app"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/gameshelf-iphone.git
git push -u origin main
```

## 4. Generar GameShelf-iPhone.ipa

El workflow se ejecuta automáticamente al hacer push a `main`. También puede lanzarse manualmente:

1. Abre el repositorio en GitHub.
2. Entra en `Actions`.
3. Selecciona `Build GameShelf iPhone IPA`.
4. Pulsa `Run workflow`.
5. Abre la ejecución.
6. Cuando finalice correctamente, baja a `Artifacts`.
7. Descarga `GameShelf-iPhone`.
8. Extrae el ZIP.

Dentro estarán:

```text
GameShelf-iPhone.ipa
GameShelf-iPhone.ipa.sha256
```

El IPA está deliberadamente sin firmar. No se almacenan certificados, perfiles de aprovisionamiento, contraseña de Apple ni claves privadas en GitHub.

## 5. Instalar AltStore Classic en Windows

La documentación oficial de AltStore Classic para Windows indica como flujo principal:

1. Instalar iTunes e iCloud directamente desde Apple.
2. Instalar AltServer para Windows.
3. Ejecutar AltServer como administrador.
4. Conectar el iPhone, desbloquearlo y confiar en el ordenador.
5. Activar la sincronización por Wi-Fi en iTunes si quieres refrescos sin cable.
6. Instalar AltStore en el iPhone desde AltServer.
7. Confiar en el perfil de desarrollador si iOS lo solicita.
8. Activar `Ajustes > Privacidad y seguridad > Modo de desarrollador`.

Guía oficial:

```text
https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
```

## 6. Instalar GameShelf

### Desde AltStore Classic

1. Pasa `GameShelf-iPhone.ipa` al iPhone.
2. Abre AltStore Classic.
3. Entra en `My Apps`.
4. Pulsa `+`.
5. Selecciona `GameShelf-iPhone.ipa`.
6. AltStore firma e instala la app.

### Directamente desde AltServer

AltServer también permite sideload directo. En Windows, mantén pulsada `Shift` al abrir el menú del icono de AltServer para mostrar `Sideload .ipa…`, selecciona el IPA y el iPhone.

## 7. Renovación

Con una cuenta gratuita, las apps instaladas mediante AltStore expiran después de 7 días. AltStore intenta refrescarlas automáticamente cuando puede comunicarse con AltServer; también puede hacerse con `Refresh All`.

AltStore documenta además un límite de 3 apps sideloaded activas simultáneamente para cuentas gratuitas.

No desinstales GameShelf si quieres conservar la base local. Una re-firma/refresco sobre la misma instalación está pensada para mantener los datos.

## 8. Configurar RAWG opcionalmente

RAWG no es necesario para usar GameShelf.

Si quieres que la app identifique mejor el título antes de buscar la carátula:

1. Abre `https://rawg.io/apidocs` y consigue una API key.
2. En GameShelf abre el icono de engranaje.
3. Pega la API key.
4. Pulsa `Guardar clave`.

La API key queda en Keychain dentro del iPhone.

## 9. Qué hace el workflow

`.github/workflows/build-ipa.yml`:

1. usa un runner `macos-26`;
2. selecciona Xcode 26;
3. comprueba el SDK iPhoneOS;
4. instala la plataforma iOS si el runner la requiere;
5. valida `Info.plist` y el proyecto;
6. compila `Release` para `generic/platform=iOS`;
7. deshabilita la firma de código;
8. empaqueta `Payload/GameShelf.app` como IPA;
9. comprueba el ZIP;
10. calcula SHA-256;
11. publica ambos archivos como artifact.

## Actualizar desde GameShelf 1.0 a 1.1

Si ya tienes GameShelf instalado y quieres conservar tu colección:

1. Sustituye los archivos del repositorio por esta versión 1.1.
2. Ejecuta `SUBIR_A_GITHUB.bat` para subir los cambios.
3. Descarga el nuevo `GameShelf-iPhone.ipa` generado por Actions.
4. Instálalo/refresca la app con el mismo Apple ID y el mismo App ID/bundle que venías usando.
5. **No desinstales primero GameShelf** si quieres conservar los datos locales.

La versión 1.1 no cambia el esquema de SwiftData. Las consolas y juegos existentes se mantienen. Al abrirla por primera vez, las imágenes de las consolas se irán procesando y guardando como recortes transparentes en la caché local.
