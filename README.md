# SoundFlow

SoundFlow es una aplicacion multiplataforma hecha con Flutter (frontend) y FastAPI (backend).
La app permite generar playlists con IA, gestionar cuentas vinculadas de streaming (modo mock para desarrollo) y explorar musica desde una interfaz moderna.

## Tecnologias

- Frontend: Flutter / Dart
- Backend: FastAPI / Python
- Base de datos local: SQLite
- IDE recomendado: Visual Studio Code

## Estructura del proyecto

```text
soundFlow/
|- lib/                       # App Flutter
|- backend/                   # API FastAPI
|- assets/                    # SVG, imagenes, fuentes
|- android/ ios/ windows/ ... # Targets de Flutter
|- pubspec.yaml               # Dependencias Flutter
|- README.md
```

## Requisitos previos

Instala estas herramientas antes de iniciar:

1. Git
2. Flutter SDK
3. Visual Studio Code
4. Python 3.10+ (recomendado 3.11-3.13, tambien funciona 3.14 con la configuracion actual)
5. Visual Studio 2022 Community con workload de C++ (si vas a ejecutar en Windows Desktop)

## Instalacion del SDK de Flutter (Windows)

1. Descarga Flutter SDK desde la documentacion oficial:
	https://docs.flutter.dev/get-started/install/windows
2. Extrae Flutter en una ruta sin espacios, por ejemplo:
	`C:\src\flutter`
3. Agrega `C:\src\flutter\bin` al `PATH` de Windows.
4. Abre una terminal nueva y valida:

```powershell
flutter --version
flutter doctor
```

5. Corrige lo que indique `flutter doctor` (Android toolchain, Visual Studio C++, etc.).

## Configuracion de Visual Studio Code

Instala estas extensiones:
1. Flutter (oficial)
2. Dart (oficial)
3. Python (oficial, para backend)

Opcional:
1. Error Lens
2. GitLens

## Clonar e inicializar el proyecto

```powershell
git clone <URL_DEL_REPO>
cd soundFlow
```

## Instalar dependencias del frontend

Desde la raiz del proyecto:

```powershell
flutter pub get
```

## Instalar dependencias del backend

El proyecto incluye script de arranque para backend en:
`backend/start_server.ps1`

Desde la raiz del proyecto, ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\backend\start_server.ps1
```

Este script:

1. Crea/reutiliza `.venv` en `backend/`
2. Instala dependencias de `backend/requirements.txt`
3. Arranca FastAPI en `http://localhost:8000`

Prueba rapida del backend:

```powershell
Invoke-RestMethod http://localhost:8000/health | ConvertTo-Json -Compress
```

Respuesta esperada:

```json
{"status":"ok"}
```

Documentacion Swagger:

- http://localhost:8000/docs

## Ejecutar la app Flutter

Abre una segunda terminal (deja el backend corriendo en la primera):

```powershell
cd D:\VisualStudioCode\soundFlow
flutter run -d windows
```

Tambien puedes ejecutar en web:

```powershell
flutter run -d chrome
```

## Flujo de inicio recomendado (resumen)

1. Terminal 1:

```powershell
cd D:\VisualStudioCode\soundFlow
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\backend\start_server.ps1
```

2. Terminal 2:

```powershell
cd D:\VisualStudioCode\soundFlow
flutter pub get
flutter run -d windows
```

## Configuracion de red usada por Flutter

La app usa diferentes hosts segun plataforma en `lib/services/api_client.dart`:

- Web y desktop: `http://localhost:8000`
- Android emulador: `http://10.0.2.2:8000`

Si usas Android fisico, debes cambiar el host por la IP local de tu PC.

## Solucion de problemas

### 1) `The term '.\start_server.ps1' is not recognized`

Estas en la raiz. El script esta en `backend/`.

Usa:

```powershell
.\backend\start_server.ps1
```

### 2) `Cannot convert value Bypass.\backend\start_server.ps1`

Te falta separar comandos. Correcto:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\backend\start_server.ps1
```

### 3) `Building with plugins requires symlink support`

Activa Developer Mode en Windows:

```powershell
start ms-settings:developers
```

Luego reinicia terminal/VS Code y ejecuta:

```powershell
flutter clean
flutter pub get
flutter run -d windows
```

### 4) `{"detail":"Not Found"}` en backend

El backend esta arriba, pero consultaste una ruta inexistente (por ejemplo `/`).
Usa `http://localhost:8000/health` o `http://localhost:8000/docs`.

## Variables de entorno y secretos

No subas secretos a Git. Este repo ya ignora:

- `.env`, `.env.*`
- llaves y certificados (`*.pem`, `*.key`, `*.p12`, etc.)
- bases de datos locales (`*.db`, `*.sqlite*`)

Si necesitas compartir configuracion, usa un archivo ejemplo como `.env.example`.

## Comandos utiles

```powershell
# Ver dispositivos disponibles
flutter devices

# Verificar toolchain
flutter doctor -v

# Formatear Dart
dart format lib test

# Ejecutar tests Flutter
flutter test
```

## Estado actual de desarrollo

- Backend con endpoints funcionales para desarrollo local
- Integraciones OAuth en modo mock para pruebas
- Frontend Flutter listo para ejecutar en Windows y web

---

Si quieres, puedo agregar una seccion de despliegue (release APK/EXE y backend en produccion) en este mismo README.
