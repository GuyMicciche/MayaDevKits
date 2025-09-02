@echo off
setlocal enabledelayedexpansion

:: Drag-and-drop target folder
set "INPUT_DIR=%~1"
if "%INPUT_DIR%"=="" (
    echo Drag and drop plugin folder onto this script
    pause
    exit /b
)

:: Configure devkit base path (modify according to your setup)
set "DEVKIT_BASE=%~dp0"

:: Get plugin name from folder name
for %%F in ("%INPUT_DIR%") do set "PLUGIN_NAME=%%~nxF"
set "BUILD_ROOT=%INPUT_DIR%\build"

:: Supported Maya versions and their VS generators
set MAYA_VERSIONS=2019,2020,2022,2023,2024,2025,2026
set GENERATOR_2019="Visual Studio 17 2022"
set GENERATOR_2020="Visual Studio 17 2022"
set GENERATOR_2022="Visual Studio 17 2022"
set GENERATOR_2023="Visual Studio 17 2022"
set GENERATOR_2024="Visual Studio 17 2022"
set GENERATOR_2025="Visual Studio 17 2022"
set GENERATOR_2026="Visual Studio 17 2022"

:: Build for each Maya version
for %%Y in (%MAYA_VERSIONS%) do (
    echo.
    echo [Building for Maya %%Y]
    
	:: Create build structure
	mkdir "%BUILD_ROOT%\%%Y\plug-ins" >nul 2>&1
    mkdir "%BUILD_ROOT%\%%Y\scripts" >nul 2>&1
	
    :: Set version-specific paths
    set "YEAR=%%Y"
	set "DEVKIT_LOCATION=%DEVKIT_BASE:\=/%!YEAR!"
    set "BUILD_DIR=%BUILD_ROOT%\!YEAR!\build"
    set "OUTPUT_DIR=%BUILD_ROOT%\!YEAR!\plug-ins"
    
    :: Check devkit exists
    if not exist "!DEVKIT_LOCATION!" (
        echo Skipping Maya !YEAR! - Devkit not found at !DEVKIT_LOCATION!
        exit /b
    )
    
    :: Set appropriate VS generator
    call set "VS_GEN=%%GENERATOR_!YEAR!%%"
    
    :: Configure build
    echo Configuring for Maya !YEAR!...
    cmake -H"%INPUT_DIR:\=/%" -B"!BUILD_DIR:\=/!" ^
          -G !VS_GEN! ^
          -DMAYA_VERSION=!YEAR! ^
          -DMAYA_DEVKIT="!DEVKIT_LOCATION:\=/!" ^
          -DCMAKE_INSTALL_PREFIX="!OUTPUT_DIR:\=/!"
    
    :: Build project
    echo Building !PLUGIN_NAME!...
    cmake --build "!BUILD_DIR!" --config Release
    
    :: Copy output
    if exist "!BUILD_DIR!\Release\!PLUGIN_NAME!.mll" (
        copy /Y "!BUILD_DIR!\Release\!PLUGIN_NAME!.mll" "!OUTPUT_DIR!\" >nul
        echo Success: !PLUGIN_NAME!_!YEAR!.mll created
    ) else (
        echo Error: Build failed for Maya !YEAR!
    )
)

:: Copy scripts to all version folders
if exist "%INPUT_DIR%\scripts\*.mel" (
    for %%Y in (%MAYA_VERSIONS%) do (
        if exist "%BUILD_ROOT%\%%Y" (
            xcopy /Y /Q "%INPUT_DIR%\scripts\*.mel" "%BUILD_ROOT%\%%Y\scripts\" >nul
        )
    )
    echo Copied MEL scripts from scripts folder to all version folders
) else if exist "%INPUT_DIR%\*.mel" (
    for %%Y in (%MAYA_VERSIONS%) do (
        if exist "%BUILD_ROOT%\%%Y" (
            xcopy /Y /Q "%INPUT_DIR%\*.mel" "%BUILD_ROOT%\%%Y\scripts\" >nul
        )
    )
    echo Copied MEL scripts from root plugin folder to all version folders
) else (
    echo No MEL scripts found to copy
)

echo.
echo Build process complete!
echo Check results in: %BUILD_ROOT%
pause