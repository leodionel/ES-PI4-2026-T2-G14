@echo off
rem Atalho para o Windows: duplo clique ou "scripts\modo-b.bat".
rem Chama o PowerShell sem depender da politica de execucao de scripts.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0modo-b.ps1" %*
