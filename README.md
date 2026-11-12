# FLauncher (fork)

#### This is a fork of the GitLab repository at: https://gitlab.com/flauncher/flauncher.

FLauncher is an open-source alternative launcher for Android TV, built with [Flutter](https://flutter.dev).

## Download

Each push and pull request builds `flauncher-armeabi-v7a-release.apk` and uploads it as a [GitHub Actions](https://github.com/AndreaMangas31/flauncher/actions) artifact. A tag `v*` also attaches that APK to a [GitHub Release](https://github.com/AndreaMangas31/flauncher/releases).

If the fork has no release keystore secrets, the APK is signed with the Android debug key so it can be installed with `adb install`. That signature does not match an install of the upstream release (`me.efesser.flauncher` signed by osrosal). Uninstall the previous app first (`adb uninstall me.efesser.flauncher`), then install this APK.

## Features

For a list of the changes introduced by this fork from the original, see the [CHANGELOG](CHANGELOG.md) file.

- [x] No ads
- [x] Customizable categories
- [x] Manually reorder apps within categories
- [x] Wallpaper support
- [x] Open "Android Settings"
- [x] Open "App info"
- [x] Uninstall app
- [x] Clock
- [x] Switch between row and grid for categories
- [x] Support for non-TV (sideloaded) apps
- [x] Navigation sound feedback
- [ ] Force stop app

## Screenshots

|                                            |                                            |                                            |
| ------------------------------------------ | ------------------------------------------ | ------------------------------------------ |
| ![](screenshots/Screenshot_1624378896.png) | ![](screenshots/Screenshot_1624378921.png) | ![](screenshots/Screenshot_1624378938.png) |

## Recomendadas por Senku

La fila del final de la pantalla de inicio no es una categoría de aplicaciones. FLauncher descarga un feed JSON, guarda la última copia válida y la vuelve a pedir al abrir el launcher y cada 6 horas. Si no hay red o el JSON no es válido, se muestra la copia guardada; si tampoco hay copia, la fila se oculta. Un fallo del feed no cierra el launcher.

La URL por defecto es `https://raw.githubusercontent.com/AndreaMangas31/flauncher/main/recommendations/recommendations.json`. Se cambia en Ajustes, junto con el interruptor que muestra u oculta la fila. El ejemplo versionado está en [`recommendations/recommendations.json`](recommendations/recommendations.json).

```json
{
  "updatedAt": "2026-11-10T00:00:00Z",
  "items": [
    {
      "title": "Ejemplo: serie de placeholder",
      "description": "Texto corto en español.",
      "platform": "Netflix",
      "type": "serie",
      "status": "en emisión",
      "imageUrl": "https://example.com/poster.png",
      "deepLink": "https://www.netflix.com/title/80057281",
      "packageName": "com.netflix.ninja"
    }
  ]
}
```

| Campo         | Obligatorio | Notas                                                                                                                                                                                                                                             |
| ------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `updatedAt`   | sí          | Fecha ISO-8601 del feed. Si falta o no se puede leer, el feed se descarta.                                                                                                                                                                        |
| `items`       | sí          | Lista. Una entrada incompleta se omite; el resto se muestra.                                                                                                                                                                                      |
| `title`       | sí          | Título de la ficha.                                                                                                                                                                                                                               |
| `description` | sí          | Texto corto en español. Se ve al enfocar la ficha con el mando.                                                                                                                                                                                   |
| `platform`    | sí          | Por ejemplo Netflix, Crunchyroll, Disney+, Prime Video, HBO Max o Filmin.                                                                                                                                                                         |
| `type`        | sí          | `serie` o `película`.                                                                                                                                                                                                                             |
| `status`      | sí          | `en emisión` o `estreno`.                                                                                                                                                                                                                         |
| `imageUrl`    | sí          | URL del póster. Si la imagen falla, la ficha sigue visible.                                                                                                                                                                                       |
| `deepLink`    | no          | Se abre con `ACTION_VIEW` si alguna actividad lo resuelve.                                                                                                                                                                                        |
| `packageName` | no          | Si el enlace no resuelve, se abre esta aplicación. Paquetes habituales en Android TV: `com.netflix.ninja`, `com.crunchyroll.crunchyroid`, `com.disney.disneyplus`, `com.amazon.amazonvideo.livingroom`, `com.wbd.stream`, `com.filmin.filminapp`. |

Seleccionar la ficha intenta el `deepLink` y, si el sistema no lo resuelve, lanza `packageName`.

## Set FLauncher as default launcher

### Method 1: remap the Home button

This is the "safer" and easiest way. Use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap the Home button of the remote to launch FLauncher.

### Method 2: disable the default launcher

**:warning: Disclaimer :warning:**

**You are doing this at your own risk, and you'll be responsible in any case of malfunction on your device.**

The following commands have been tested on Chromecast with Google TV only. This may be different on other devices.

Once the default launcher is disabled, press the Home button on the remote, and you'll be prompted by the system to choose which app to set as default.

#### Disable default launcher

```shell
# Disable com.google.android.apps.tv.launcherx which is the default launcher on CCwGTV
$ adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
# com.google.android.tungsten.setupwraith will then be used as a 'fallback' and will automatically
# re-enable the default launcher, so disable it as well
$ adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```

#### Re-enable default launcher

```shell
$ adb shell pm enable com.google.android.apps.tv.launcherx
$ adb shell pm enable com.google.android.tungsten.setupwraith
```

#### Known issues

On Chromecast with Google TV (maybe others), the "YouTube" remote button will stop working if the default launcher is disabled. As a workaround, you can use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap it correctly.

## Wallpaper

Because Android's `WallpaperManager` is not available on some Android TV devices, FLauncher implements its own wallpaper management method.

Please note that changing wallpaper requires a file explorer to be installed on the device in order to pick a file.

## Support the original author: [etienn01](https://github.com/etienn01)

<a href="https://www.buymeacoffee.com/etienn01" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>

### Qué necesitas

Flutter 3.24.5 (fijado en pubspec.yaml)
Java 17
Android SDK con compileSdk 35
Un emulador Android TV o una tele/caja real por adb

### Como arrancar

```shell
emulator -avd flauncher-tv
flutter run
```
