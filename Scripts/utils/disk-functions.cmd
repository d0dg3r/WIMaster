# Festplatten-Hilfsfunktionen
# Diese Funktionen können von anderen Scripts aufgerufen werden

REM Get the main directory (two levels up from utils)
set "SCRIPT_DIR=%~dp0..\.."
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:LIST_DISKS
# Listet alle verfügbaren Festplatten auf
echo Available Disks:
echo ================
echo list disk | diskpart
echo.
echo Detailed disk information:
echo Using diskpart to list disks...
echo list disk | diskpart
goto :eof

:GET_DISK_INFO
# Parameter: %1 = Disk Number
set disk_num=%1
if "%disk_num%"=="" set disk_num=0

echo Information for Disk %disk_num%:
echo ================================
(
echo select disk %disk_num%
echo detail disk
echo list partition
echo exit
) | diskpart
goto :eof

:FORMAT_DISK
# Parameter: %1 = Disk Number, %2 = File System, %3 = Label
set disk_num=%1
set fs_type=%2
set volume_label=%3

if "%disk_num%"=="" set disk_num=0
if "%fs_type%"=="" set fs_type=ntfs
if "%volume_label%"=="" set volume_label=Windows

echo Formatting Disk %disk_num% with %fs_type% filesystem...
(
echo select disk %disk_num%
echo clean
echo create partition primary
echo active
echo format fs=%fs_type% quick label="%volume_label%"
echo assign
echo exit
) | diskpart
echo Disk formatted successfully.
goto :eof

:CREATE_UEFI_PARTITIONS
# Parameter: %1 = Disk Number, %2 = Volume Label
set disk_num=%1
set volume_label=%2

if "%disk_num%"=="" set disk_num=0
if "%volume_label%"=="" set volume_label=Windows

echo Creating UEFI partitions on Disk %disk_num%...
(
echo select disk %disk_num%
echo clean
echo convert gpt
echo create partition efi size=100
echo format fs=fat32 quick
echo assign letter=S
echo create partition msr size=128
echo create partition primary
echo format fs=ntfs quick label="%volume_label%"
echo assign letter=C
echo exit
) | diskpart
echo UEFI partitions created successfully.
goto :eof

:CREATE_MBR_PARTITIONS
# Parameter: %1 = Disk Number, %2 = Volume Label
set disk_num=%1
set volume_label=%2

if "%disk_num%"=="" set disk_num=0
if "%volume_label%"=="" set volume_label=Windows

echo Creating MBR partitions on Disk %disk_num%...
(
echo select disk %disk_num%
echo clean
echo create partition primary
echo active
echo format fs=ntfs quick label="%volume_label%"
echo assign letter=C
echo exit
) | diskpart
echo MBR partitions created successfully.
goto :eof

:CHECK_DISK_HEALTH
# Parameter: %1 = Disk Number (optional)
set disk_num=%1

if "%disk_num%"=="" (
    echo Checking health of all disks...
    echo Using diskpart to list disks...
    echo list disk | diskpart
) else (
    echo Checking health of Disk %disk_num%...
    echo Using diskpart to check specific disk...
    echo select disk %disk_num% | diskpart
    echo detail disk | diskpart
)
goto :eof

:INSTALL_BOOT_FILES
# Parameter: %1 = Windows Path, %2 = Boot Path, %3 = Firmware Type
set windows_path=%1
set boot_path=%2
set firmware_type=%3

if "%windows_path%"=="" set windows_path=C:\Windows
if "%boot_path%"=="" set boot_path=S:
if "%firmware_type%"=="" set firmware_type=UEFI

echo Installing boot files...
echo Windows Path: %windows_path%
echo Boot Path: %boot_path%
echo Firmware Type: %firmware_type%

bcdboot %windows_path% /s %boot_path% /f %firmware_type%
if %errorlevel%==0 (
    echo Boot files installed successfully.
    set BOOT_INSTALLED=1
) else (
    echo Failed to install boot files.
    set BOOT_INSTALLED=0
)
goto :eof
