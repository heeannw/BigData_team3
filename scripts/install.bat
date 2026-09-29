@echo off
rem Offline RAG chatbot installer (double-click). Runs scripts\install.ps1
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
pause
