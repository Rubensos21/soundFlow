# 🚀 Cómo Ejecutar SoundFlow

## 📋 Requisitos Previos

- Python 3.8+ instalado
- Flutter instalado
- PowerShell 7+ (para Windows)

---

## 🔧 PASO 1: Ejecutar el Backend (FastAPI)

### Opción A: Usando el Script Automático (RECOMENDADO)

Abre PowerShell y ejecuta:

```powershell
cd D:\Flutter\chat_app\backend
.\start_server.ps1
```

Este script automáticamente:
- ✅ Crea el entorno virtual si no existe
- ✅ Instala todas las dependencias necesarias
- ✅ Inicia el servidor en `http://localhost:8000`

### Opción B: Manualmente

```powershell
# Navegar al directorio backend
cd D:\Flutter\chat_app\backend

# Crear entorno virtual (solo la primera vez)
python -m venv .venv

# Activar entorno virtual
.\.venv\Scripts\Activate.ps1

# Instalar dependencias (solo la primera vez)
pip install -r requirements.txt
pip install python-multipart

# Volver al directorio raíz
cd ..

# Ejecutar el servidor
python -m uvicorn backend.app:app --reload --port 8000
```

✅ **El backend estará corriendo en:** `http://localhost:8000`

Para verificar que funciona, abre: `http://localhost:8000/health`

---

## 📱 PASO 2: Ejecutar el Frontend (Flutter)

Abre una **NUEVA TERMINAL** de PowerShell y ejecuta:

### Para Windows Desktop (Recomendado):

```powershell
cd D:\Flutter\chat_app
flutter run -d windows
```

### Para Chrome:

```powershell
cd D:\Flutter\chat_app
flutter run -d chrome
```

### Para Edge:

```powershell
cd D:\Flutter\chat_app
flutter run -d edge
```

### Para dejar que Flutter elija:

```powershell
cd D:\Flutter\chat_app
flutter run
# Luego selecciona el dispositivo (1, 2, o 3)
```

---

## 🔗 PASO 3: Vincular Cuentas de Streaming

1. **En la app**, haz clic en el logo de Spotify, Deezer o Apple Music
2. Se abrirá tu **navegador predeterminado**
3. Verás una página morada bonita que dice **"¡Cuenta Vinculada!"**
4. La ventana se cerrará automáticamente después de 3 segundos (o ciérrala manualmente)
5. Vuelve a la app y verás que la cuenta está vinculada

### 📌 Nota Importante:

- El flujo OAuth está **simulado (mockeado)** para desarrollo
- No necesitas credenciales reales de Spotify/Deezer/Apple Music
- La autenticación es instantánea y siempre exitosa

---

## 🐛 Solución de Problemas

### Error: "ERR_CONNECTION_REFUSED"

✅ **Solución:** El backend no está corriendo. Ejecuta el `start_server.ps1`

### Error: "No se pudo abrir el enlace de autenticación"

✅ **Solución:** Asegúrate de que el backend esté corriendo en `http://localhost:8000`

### La cuenta no se muestra como vinculada

✅ **Solución:** 
1. Presiona el botón "Listo" en el diálogo que aparece después de vincular
2. Si estás en la pantalla de configuración, presiona el ícono de refrescar 🔄

### El servidor no inicia

✅ **Solución:**
```powershell
cd D:\Flutter\chat_app\backend
Remove-Item -Recurse -Force .venv
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install python-multipart
```

---

## 📦 Estructura del Proyecto

```
chat_app/
├── backend/                    # Backend FastAPI
│   ├── app.py                 # API principal
│   ├── config.py              # Configuración
│   ├── start_server.ps1       # Script de inicio automático
│   └── requirements.txt       # Dependencias Python
├── lib/                       # Frontend Flutter
│   ├── main.dart             # Login con logos SVG
│   ├── signup_screen.dart    # Registro con logos SVG
│   ├── account_settings.dart # Configuración con logos SVG
│   └── services/
│       └── api_client.dart   # Cliente HTTP
└── assets/
    └── svg/                   # Logos de las plataformas
        ├── spotify.svg
        ├── deezer.svg
        └── applemusic.svg
```

---

## ✨ Características Implementadas

- ✅ Logos SVG reales de Spotify, Deezer y Apple Music
- ✅ Flujo OAuth simulado (mock) para desarrollo
- ✅ Página de éxito bonita al vincular cuentas
- ✅ Auto-cierre de ventana del navegador
- ✅ Diálogos informativos en la app
- ✅ Backend con FastAPI y SQLite
- ✅ Frontend Flutter multiplataforma

---

## 🎨 Próximos Pasos (Opcional)

Para conectar con las APIs reales:

1. Crea aplicaciones en:
   - Spotify Developer Dashboard
   - Deezer Developers
   - Apple Music Developer

2. Configura las credenciales en `backend/.env`:
   ```env
   SPOTIFY_CLIENT_ID=tu_client_id
   SPOTIFY_CLIENT_SECRET=tu_client_secret
   DEEZER_APP_ID=tu_app_id
   DEEZER_SECRET=tu_secret
   ```

3. Implementa el flujo OAuth real en `backend/app.py`

---

## 📞 Ayuda

Si tienes problemas, verifica:

1. ✅ Python está instalado: `python --version`
2. ✅ Flutter está instalado: `flutter --version`
3. ✅ El backend está corriendo: Abre `http://localhost:8000/health`
4. ✅ No hay otro servicio usando el puerto 8000

---

**¡Disfruta usando SoundFlow! 🎵**

