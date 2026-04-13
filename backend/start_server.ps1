Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SoundFlow Backend Server" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function New-Venv {
    param(
        [string]$BackendDir
    )

    if (Get-Command py -ErrorAction SilentlyContinue) {
        py -3 -m venv (Join-Path $BackendDir ".venv")
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        python -m venv (Join-Path $BackendDir ".venv")
    } else {
        throw "No se encontro Python. Instala Python 3.8+ y vuelve a intentar."
    }
}

# Cambiar al directorio backend
$backendDir = $PSScriptRoot
Set-Location $backendDir
$venvPath = Join-Path $backendDir ".venv"
$venvPython = Join-Path $backendDir ".venv\Scripts\python.exe"

# Verificar si existe el entorno virtual
if (-not (Test-Path $venvPath)) {
    Write-Host "Creando entorno virtual..." -ForegroundColor Yellow
    New-Venv -BackendDir $backendDir
    Write-Host "Entorno virtual creado!" -ForegroundColor Green
}

# Verificar si el entorno virtual es usable (evita venv roto por cambio de Python base)
$venvHealthy = $false
if (Test-Path $venvPython) {
    & $venvPython -c "import sys" *> $null
    if ($LASTEXITCODE -eq 0) {
        $venvHealthy = $true
    }
}

if (-not $venvHealthy) {
    Write-Host "El entorno virtual actual esta roto o apunta a un Python inexistente. Recreando..." -ForegroundColor Yellow
    if (Test-Path $venvPath) {
        Remove-Item -Recurse -Force $venvPath
    }
    New-Venv -BackendDir $backendDir
    Write-Host "Entorno virtual recreado!" -ForegroundColor Green
}

# Activar entorno virtual
Write-Host "Activando entorno virtual..." -ForegroundColor Yellow
$activateScript = Join-Path $backendDir ".venv\Scripts\Activate.ps1"
& $activateScript

function Test-RequiredPackagesInstalled {
    param(
        [string]$BackendDir
    )

    $requiredPaths = @(
        (Join-Path $BackendDir ".venv\Lib\site-packages\fastapi"),
        (Join-Path $BackendDir ".venv\Lib\site-packages\uvicorn"),
        (Join-Path $BackendDir ".venv\Lib\site-packages\pydantic")
    )

    foreach ($path in $requiredPaths) {
        if (-not (Test-Path $path)) {
            return $false
        }
    }

    return $true
}

# Verificar si las dependencias están instaladas
if (-not (Test-RequiredPackagesInstalled -BackendDir $backendDir)) {
    Write-Host "Instalando dependencias..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: fallo la instalacion de dependencias." -ForegroundColor Red
        Write-Host "Tip: este proyecto requiere paquetes compatibles con tu version de Python." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Dependencias instaladas!" -ForegroundColor Green
} else {
    # Verificar si python-multipart está instalado (requerido para FastAPI con archivos)
    if (-not (Test-Path .venv\Lib\site-packages\multipart)) {
        Write-Host "Instalando python-multipart..." -ForegroundColor Yellow
        pip install python-multipart
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: no se pudo instalar python-multipart." -ForegroundColor Red
            exit 1
        }
        Write-Host "python-multipart instalado!" -ForegroundColor Green
    }
}

# Cambiar al directorio padre para que Python pueda encontrar el módulo backend
$parentDir = Split-Path -Parent $backendDir
Set-Location $parentDir

Write-Host ""
Write-Host "Iniciando servidor en http://localhost:8000" -ForegroundColor Green
Write-Host "Presiona Ctrl+C para detener el servidor" -ForegroundColor Yellow
Write-Host ""
Write-Host "Directorio actual: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Iniciar servidor desde el directorio padre
# Usar la ruta completa del Python del entorno virtual
$pythonExe = Join-Path $backendDir ".venv\Scripts\python.exe"
& $pythonExe -m uvicorn backend.app:app --reload --port 8000 --host 0.0.0.0
