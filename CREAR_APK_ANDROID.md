# 📱 Guía: Crear APK de SoundFlow para Android

## ✅ Configuraciones Realizadas

Ya he configurado tu app para Android:

- ✅ **Permisos de Internet** agregados
- ✅ **Cleartext Traffic** habilitado (para conectarse al backend en desarrollo)
- ✅ **Nombre de app** cambiado a "SoundFlow"
- ✅ **Todos los assets** configurados en `pubspec.yaml`

---

## 🚀 **Cómo Crear el APK**

### Opción 1: APK de Depuración (Debug) - Para Probar

Este es el más rápido y funciona para pruebas:

```powershell
cd D:\Flutter\chat_app
flutter build apk --debug
```

**Resultado:**
- 📦 APK ubicado en: `build\app\outputs\flutter-apk\app-debug.apk`
- ⚡ Tamaño: ~40-60 MB
- 🎯 Uso: Solo para pruebas/desarrollo
- ⚠️ No optimizado

---

### Opción 2: APK de Release (Producción) - Recomendado

Este está optimizado y es más pequeño:

```powershell
cd D:\Flutter\chat_app
flutter build apk --release
```

**Resultado:**
- 📦 APK ubicado en: `build\app\outputs\flutter-apk\app-release.apk`
- ⚡ Tamaño: ~15-25 MB (mucho más pequeño)
- 🎯 Uso: Para distribución/producción
- ✅ Optimizado y ofuscado

---

### Opción 3: APK por ABI (Más Pequeños)

Crea APKs separados por arquitectura (recomendado para producción):

```powershell
cd D:\Flutter\chat_app
flutter build apk --split-per-abi --release
```

**Resultado:**
- 📦 `app-armeabi-v7a-release.apk` (~8-12 MB) - Dispositivos antiguos
- 📦 `app-arm64-v8a-release.apk` (~10-15 MB) - Dispositivos modernos
- 📦 `app-x86_64-release.apk` (~10-15 MB) - Emuladores

**Ventaja:** Cada usuario descarga solo el APK de su arquitectura (más pequeño).

---

## 📋 **Paso a Paso Completo:**

### 1️⃣ **Limpiar Build Anterior** (Opcional pero Recomendado)

```powershell
cd D:\Flutter\chat_app
flutter clean
flutter pub get
```

### 2️⃣ **Crear APK**

Para pruebas rápidas:
```powershell
flutter build apk --debug
```

Para producción:
```powershell
flutter build apk --release
```

### 3️⃣ **Encontrar tu APK**

El APK estará en:
```
D:\Flutter\chat_app\build\app\outputs\flutter-apk\
```

Archivos generados:
- `app-debug.apk` o
- `app-release.apk` o
- `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, etc.

### 4️⃣ **Instalar en tu Dispositivo**

**Método A - USB:**
```powershell
# Con el dispositivo conectado por USB
flutter install
```

**Método B - Compartir APK:**
1. Copia el APK a tu teléfono
2. Abre el archivo en tu teléfono
3. Acepta instalar desde fuentes desconocidas
4. Instalar

**Método C - ADB:**
```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## ⚠️ **IMPORTANTE para Android:**

### 1. **Backend debe estar accesible desde tu dispositivo**

Si vas a usar el APK en un **dispositivo Android real**, necesitas:

#### **Opción A: Usar tu IP Local** (Dispositivo en mismo WiFi)

**1. Obtener tu IP:**
```powershell
ipconfig
# Busca IPv4 en tu WiFi: ej. 192.168.1.100
```

**2. Actualizar `api_client.dart`** línea 25:
```dart
} else if (Platform.isAndroid) {
  return 'http://192.168.1.100:8000';  // Tu IP aquí
}
```

**3. Actualizar Redirect URI de Spotify:**

En el dashboard de Spotify, agregar:
```
http://192.168.1.100:8000/auth/spotify/callback
```

Y en `backend/app.py` líneas 74 y 108:
```python
redirect_uri = "http://192.168.1.100:8000/auth/spotify/callback"
```

**4. Backend debe escuchar en 0.0.0.0:**
```powershell
cd D:\Flutter\chat_app
python -m uvicorn backend.app:app --host 0.0.0.0 --port 8000
```

#### **Opción B: Solo para Emulador**

Si solo usarás emulador, déjalo como está:
```dart
return 'http://10.0.2.2:8000';  // Ya configurado
```

---

### 2. **Firewall de Windows**

Permite Python en el firewall:

1. Busca "Firewall" en Windows
2. "Permitir una aplicación a través de Firewall"
3. Busca Python
4. Marca "Privadas" (red local)

---

## 🔨 **Comandos Completos:**

### Para APK de Debug (Pruebas Rápidas):

```powershell
cd D:\Flutter\chat_app
flutter clean
flutter pub get
flutter build apk --debug
```

### Para APK de Release (Producción):

```powershell
cd D:\Flutter\chat_app
flutter clean
flutter pub get
flutter build apk --release
```

### Para APKs Separados por Arquitectura:

```powershell
cd D:\Flutter\chat_app
flutter clean
flutter pub get
flutter build apk --split-per-abi --release
```

---

## 📊 **Comparación de Tipos de APK:**

| Tipo | Tamaño | Velocidad | Uso |
|------|--------|-----------|-----|
| **Debug** | ~50 MB | Más lento | 🧪 Solo pruebas |
| **Release** | ~20 MB | Rápido | ✅ Distribución |
| **Split ABI** | ~10 MB c/u | Rápido | ✅ Play Store |

---

## ⚙️ **Configuración para Producción (Opcional):**

### 1. Cambiar el App ID

Edita `android/app/build.gradle`:

```gradle
android {
    namespace = "com.tuempresa.soundflow"  // Cambiar esto
    compileSdk = flutter.compileSdkVersion
    // ...
    defaultConfig {
        applicationId = "com.tuempresa.soundflow"  // Y esto
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // ...
    }
}
```

### 2. Firmar el APK (Para Google Play Store)

Crea un keystore:

```powershell
keytool -genkey -v -keystore D:\Flutter\soundflow-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias soundflow
```

Crea `android/key.properties`:
```properties
storePassword=tu_password
keyPassword=tu_password
keyAlias=soundflow
storeFile=D:/Flutter/soundflow-key.jks
```

Edita `android/app/build.gradle` para usar la firma.

---

## 🎯 **Checklist Pre-Build:**

Antes de crear el APK, verifica:

- [ ] Permisos de internet agregados ✅ (ya está)
- [ ] Nombre de app configurado ✅ (ya está)
- [ ] Assets en pubspec.yaml ✅ (ya está)
- [ ] Si usarás dispositivo real: IP configurada en `api_client.dart`
- [ ] Si usarás dispositivo real: Redirect URI actualizada
- [ ] Backend corriendo en 0.0.0.0:8000

---

## 🐛 **Problemas Comunes:**

### "Error: Gradle build failed"

**Solución:**
```powershell
cd D:\Flutter\chat_app\android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### "Unable to load asset"

**Solución:**
```powershell
flutter clean
flutter pub get
flutter build apk
```

### "Internet permission denied"

**Solución:**
- Ya agregado en el AndroidManifest ✅

### "Cannot connect to backend"

**Solución para emulador:**
- Backend en: `http://0.0.0.0:8000`
- App usa: `http://10.0.2.2:8000` ✅

**Solución para dispositivo real:**
- Actualizar IP en `api_client.dart`
- Backend en: `http://0.0.0.0:8000`
- App usa: `http://TU_IP:8000`

---

## 📦 **Tamaños Esperados:**

```
Debug APK:     ~50-60 MB
Release APK:   ~18-25 MB
Split ARM64:   ~10-15 MB ⭐ Recomendado
Split ARM32:   ~8-12 MB
```

---

## 🎉 **Resumen Rápido:**

### Para Probar en Emulador:

```powershell
# 1. Backend
cd D:\Flutter\chat_app\backend
.\start_server.ps1

# 2. Build APK
cd D:\Flutter\chat_app
flutter build apk --debug

# 3. Instalar
flutter install
```

### Para Dispositivo Real:

```powershell
# 1. Obtener IP
ipconfig  # Ejemplo: 192.168.1.100

# 2. Actualizar api_client.dart línea 25
# return 'http://192.168.1.100:8000';

# 3. Build APK
flutter build apk --release

# 4. Compartir APK o instalar por USB
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## ✅ **Tu App Está Lista Para:**

- ✅ Crear APK de debug (pruebas)
- ✅ Crear APK de release (distribución)
- ✅ Funcionar en emulador Android
- ⚠️ Funcionar en dispositivo real (requiere ajuste de IP)

---

## 🚀 **¿Quieres Crear el APK Ahora?**

Dime qué tipo de APK necesitas:

1. **Debug** (para probar rápido en emulador)
2. **Release** (para distribuir a amigos)
3. **Split ABI** (APKs pequeños por arquitectura)

Y te ayudo a crearlo. 📱

