@echo off
echo Iniciando SoundFlow Backend...
echo.
cd /d %~dp0
python -m uvicorn backend.app:app --reload --port 8000 --host 0.0.0.0
pause

