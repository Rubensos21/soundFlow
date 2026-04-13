# Instrucciones para iniciar el Backend

## Opción 1: Usar el script de PowerShell (Recomendado)

1. Abre PowerShell en la carpeta `backend`
2. Ejecuta:
```powershell
.\start_server.ps1
```

Si tienes problemas con la política de ejecución, ejecuta primero:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Opción 2: Manual

1. **Crear entorno virtual** (solo la primera vez):
```powershell
python -m venv .venv
```

2. **Activar entorno virtual**:
```powershell
.\.venv\Scripts\Activate.ps1
```

3. **Instalar dependencias** (solo la primera vez):
```powershell
pip install -r requirements.txt
```

4. **Iniciar servidor**:
```powershell
python -m uvicorn backend.app:app --reload --port 8000
```

## Verificar que funciona

Una vez iniciado, deberías ver:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Abre en tu navegador: http://localhost:8000/health
Deberías ver: `{"status":"ok"}`

## Endpoints disponibles

- GET http://localhost:8000/health
- GET http://localhost:8000/auth/spotify
- GET http://localhost:8000/auth/deezer
- GET http://localhost:8000/auth/apple
- GET http://localhost:8000/me/linked-accounts
- POST http://localhost:8000/api/generate-playlist/prompt
- POST http://localhost:8000/api/generate-playlist/facial

