@echo off
title System Information
color 0A

cls
echo ==========================================
echo           System Information
echo ==========================================
echo.
echo Computer Name: %COMPUTERNAME%
echo Username: %USERNAME%
echo Current Date/Time: %DATE% %TIME%
echo.
echo === Hardware Information ===
echo Processor:
systeminfo | findstr /C:"Processor"
echo.
echo Memory:
systeminfo | findstr /C:"Total Physical Memory"
echo.
echo === Storage Information ===
echo Available Drives:
dir C:\ /-c 2>nul
if exist D:\ dir D:\ /-c 2>nul
if exist E:\ dir E:\ /-c 2>nul
if exist F:\ dir F:\ /-c 2>nul
echo.
echo === Network Information ===
echo Network Interfaces:
netsh interface show interface
echo.
echo === Current IP Configuration ===
ipconfig /all
echo.
echo === System Information ===
systeminfo | findstr /C:"OS Name" /C:"OS Version" /C:"System Type"
echo.
pause
