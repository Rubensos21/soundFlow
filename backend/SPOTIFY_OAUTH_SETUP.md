# 🎵 Configuración de Spotify OAuth REAL

## 📋 Cómo Obtener las Credenciales de Spotify

Sigue estos pasos para conectar tu app con Spotify real:

### 1️⃣ Crear una Aplicación en Spotify Developer Dashboard

1. Ve a: **https://developer.spotify.com/dashboard**
2. Inicia sesión con tu cuenta de Spotify
3. Haz clic en **"Create app"**
4. Llena el formulario:
   - **App name:** `SoundFlow` (o el nombre que prefieras)
   - **App description:** `Aplicación para generar playlists con IA`
   - **Redirect URI:** `http://localhost:8000/auth/spotify/callback`
   - **API/SDKs:** Marca `Web API`
   - Acepta los términos y condiciones
5. Haz clic en **"Save"**

### 2️⃣ Obtener Client ID y Client Secret

1. En el dashboard de tu app, ve a **"Settings"**
2. Encontrarás:
   - **Client ID:** Cópialo
   - **Client Secret:** Haz clic en "View client secret" y cópialo

### 3️⃣ Configurar en el Backend

Tienes **2 opciones**:

#### **Opción A: Crear archivo .env** (Recomendado)

Crea un archivo `.env` en `chat_app/backend/`:

```env
# Spotify OAuth Credentials
SPOTIFY_CLIENT_ID=tu_client_id_aqui
SPOTIFY_CLIENT_SECRET=tu_client_secret_aqui

# Otras configuraciones
DATABASE_URL=sqlite:///./soundflow.db
JWT_SECRET=dev-secret-change-in-production
JWT_ALG=HS256
```

#### **Opción B: Variables de Entorno**

En PowerShell:

```powershell
$env:SPOTIFY_CLIENT_ID="tu_client_id_aqui"
$env:SPOTIFY_CLIENT_SECRET="tu_client_secret_aqui"
```

### 4️⃣ Reiniciar el Backend

```powershell
cd D:\Flutter\chat_app\backend
.\start_server.ps1
```

---

## ✅ Verificar que Funciona

### Paso 1: Vincular Cuenta

1. Ejecuta la app en Windows Desktop:
   ```powershell
   cd D:\Flutter\chat_app
   flutter run -d windows
   ```

2. Haz clic en el **ícono de headphones** (🎧) en la barra inferior

3. Haz clic en **"Conectar con Spotify"**

4. Se abrirá tu navegador con la página de autorización de Spotify

5. Inicia sesión en Spotify y autoriza la aplicación

6. Serás redirigido de vuelta y verás **"¡Cuenta Vinculada!"**

### Paso 2: Ver tus Datos Reales

Una vez conectado, verás:

- ✅ **Tu perfil de Spotify** (nombre e imagen)
- ✅ **Tus playlists reales** de Spotify
- ✅ **Tus canciones favoritas** (top tracks)
- ✅ **Canciones recientemente reproducidas**

---

## 🔧 Configuración Adicional (Opcional)

### Agregar más Redirect URIs

Si quieres probar en diferentes entornos:

1. Ve a **Settings** en el dashboard de Spotify
2. En **Redirect URIs**, agrega:
   - Para desarrollo: `http://localhost:8000/auth/spotify/callback`
   - Para Android: `http://10.0.2.2:8000/auth/spotify/callback`
   - Para producción: `https://tudominio.com/auth/spotify/callback`

### Permisos (Scopes)

Los scopes configurados automáticamente son:

- `user-read-private` - Leer perfil privado
- `user-read-email` - Leer email
- `playlist-read-private` - Leer playlists privadas
- `playlist-read-collaborative` - Leer playlists colaborativas
- `user-top-read` - Leer canciones y artistas favoritos
- `user-read-recently-played` - Leer historial de reproducción
- `user-library-read` - Leer biblioteca (liked songs)

---

## 🐛 Solución de Problemas

### Error: "INVALID_CLIENT"

✅ **Solución:** Verifica que el `Client ID` y `Client Secret` sean correctos.

### Error: "Redirect URI mismatch"

✅ **Solución:** 
1. Ve al dashboard de Spotify
2. Settings → Redirect URIs
3. Asegúrate de tener: `http://localhost:8000/auth/spotify/callback`
4. Haz clic en "Save"

### No aparecen mis datos de Spotify

✅ **Solución:**
1. Verifica que el token se guardó:
   ```powershell
   cd D:\Flutter\chat_app\backend
   python check_db.py
   ```
2. Deberías ver una cuenta de Spotify vinculada
3. Si no, intenta desconectar y reconectar

### Token expirado

Los tokens de Spotify expiran después de 1 hora. Si esto pasa:

1. Desconecta la cuenta
2. Vuelve a conectar (el proceso es automático)

---

## 🎯 Modo de Desarrollo (Sin Credenciales)

Si **NO** configuras credenciales de Spotify, la app funcionará en **modo mock**:

- ✅ Las funcionalidades siguen funcionando
- ✅ No verás datos reales de Spotify
- ✅ Útil para desarrollo sin internet o sin cuenta Spotify

Para activar modo real, simplemente configura las credenciales.

---

## 📚 Documentación Oficial

- **Spotify Web API:** https://developer.spotify.com/documentation/web-api
- **OAuth 2.0:** https://developer.spotify.com/documentation/web-api/concepts/authorization
- **Scopes:** https://developer.spotify.com/documentation/web-api/concepts/scopes

---

## 🚀 Próximos Pasos

Una vez configurado Spotify, puedes:

1. ✅ Ver todas tus playlists reales
2. ✅ Ver tus canciones favoritas
3. ✅ Ver tu historial de reproducción
4. ✅ Buscar música en Spotify
5. ✅ Generar playlists basadas en tus gustos reales

---

**¿Necesitas ayuda?** Revisa los logs del backend en la terminal donde ejecutaste `start_server.ps1`

