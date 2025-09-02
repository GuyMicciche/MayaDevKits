@echo off
setlocal enabledelayedexpansion

:: Automatically setup Visual Studio Developer environment
echo Setting up Visual Studio Developer environment...

:: Try VS 2022 first
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
    echo Using Visual Studio 2022 Community
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" >nul
    echo Using Visual Studio 2022 Professional
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul
    echo Using Visual Studio 2022 Enterprise
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" >nul
    echo Using Visual Studio 2019 Professional
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat" >nul
    echo Using Visual Studio 2019 Community
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat" (
    call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat" >nul
    echo Using Visual Studio 2019 Enterprise
) else (
    echo ERROR: Visual Studio Developer Command Prompt not found
    pause
    exit /b 1
)

:: Verify the environment is working
cl >nul 2>&1
if errorlevel 1 (
    echo ERROR: Visual C++ compiler not available
    pause
    exit /b 1
)

echo Developer environment ready!
echo.

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

:: Store the original directory
set "ORIGINAL_DIR=%CD%"

:: Supported Maya versions and their VS generators
set MAYA_VERSIONS=2019,2020,2022,2023,2024,2025,2026
set GENERATOR_2019="Visual Studio 17 2022"
set GENERATOR_2020="Visual Studio 17 2022"
set GENERATOR_2022="Visual Studio 17 2022"
set GENERATOR_2023="Visual Studio 17 2022"
set GENERATOR_2024="Visual Studio 17 2022"
set GENERATOR_2025="Visual Studio 17 2022"
set GENERATOR_2026="Visual Studio 17 2022"

:: Check if this is a Qt plugin and if we need Developer Command Prompt
set "IS_QT_PLUGIN=0"
if exist "%INPUT_DIR%\%PLUGIN_NAME%.pro" (
    set "IS_QT_PLUGIN=1"
    echo Detected Qt plugin project: %PLUGIN_NAME%.pro
    
    :: Check if cl.exe is available (indicates we're in Developer Command Prompt)
    cl >nul 2>&1
    if errorlevel 1 (
        echo.
        echo ERROR: Qt plugin detected for Maya 2024 and earlier versions
        echo This requires Microsoft Visual C++ compiler environment.
        echo.
        echo Please run this script from one of these:
        echo - Developer Command Prompt for Visual Studio
        echo - Visual Studio Developer PowerShell
        echo - Or run vcvars64.bat first
        echo.
        echo Example paths to find Developer Command Prompt:
        echo - Start Menu ^> Visual Studio ^> Developer Command Prompt for VS 2022
        echo - Start Menu ^> Visual Studio ^> Developer PowerShell for VS 2022
        echo.
        pause
        exit /b 1
    ) else (
        echo Visual C++ compiler environment detected - proceeding with Qt build
    )
)

:: Build for each Maya version
for %%Y in (%MAYA_VERSIONS%) do (
    echo.
    echo [Building for Maya %%Y]
    
    :: Create build structure
    mkdir "%BUILD_ROOT%\%%Y\plug-ins" >nul 2>&1
    mkdir "%BUILD_ROOT%\%%Y\scripts" >nul 2>&1
    
    :: Set version-specific paths
    set "YEAR=%%Y"
    set "DEVKIT_DIR=%DEVKIT_BASE:\=/%!YEAR!"
    set "DEVKIT_LOCATION=!DEVKIT_DIR:\=/!"
    set "BUILD_DIR=%BUILD_ROOT%\!YEAR!\build"
    set "OUTPUT_DIR=%BUILD_ROOT%\!YEAR!\plug-ins"
    
    :: Check devkit exists
    if not exist "!DEVKIT_DIR!" (
        echo Skipping Maya !YEAR! - Devkit not found at !DEVKIT_DIR!
        goto :skip_to_next
    )
    
    :: Determine build method
    set "USE_QMAKE=0"
    if !IS_QT_PLUGIN! EQU 1 (
        if !YEAR! LEQ 2024 (
            set "USE_QMAKE=1"
        )
    )
    
    if !USE_QMAKE! EQU 1 (
        :: Use qmake for Qt plugins on Maya 2024 and earlier
        echo Using qmake build for Qt plugin on Maya !YEAR!
        
        :: Ensure we're in the correct directory and store current location
        cd /d "!ORIGINAL_DIR!"
        
        :: Create a temporary copy of the .pro file with version-specific settings
        set "TEMP_PRO=%INPUT_DIR%\temp_!YEAR!.pro"
        copy /Y "%INPUT_DIR%\!PLUGIN_NAME!.pro" "!TEMP_PRO!" >nul
        
        :: Change to input directory for qmake
        cd /d "%INPUT_DIR%"
        
        :: Run qmake with the .pro file
        echo Running qmake for Maya !YEAR!...
        "!DEVKIT_LOCATION!\devkit\bin\qmake" "!TEMP_PRO!"
        
        if !ERRORLEVEL! EQU 0 (
            echo Building with nmake...
            nmake release
            
            :: Copy output file
            if exist "release\!PLUGIN_NAME!.mll" (
                copy /Y "release\!PLUGIN_NAME!.mll" "!OUTPUT_DIR!\" >nul
                echo Success: !PLUGIN_NAME!.mll created for Maya !YEAR!
            ) else if exist "!PLUGIN_NAME!.mll" (
                copy /Y "!PLUGIN_NAME!.mll" "!OUTPUT_DIR!\" >nul
                echo Success: !PLUGIN_NAME!.mll created for Maya !YEAR!
            ) else (
                echo Warning: No .mll file found after build for Maya !YEAR!
            )
            
            :: Clean the directory
            nmake distclean >nul 2>&1
            if exist "release" rmdir /s /q "release" >nul 2>&1
            if exist "debug" rmdir /s /q "debug" >nul 2>&1
            if exist "vc140.idb" del /q /f "vc140.idb" >nul 2>&1
        ) else (
            echo Error: qmake failed for Maya !YEAR!
        )
        
        :: Clean up temporary .pro file
        if exist "!TEMP_PRO!" del /q /f "!TEMP_PRO!" >nul 2>&1
        
        :: Return to original directory
        cd /d "!ORIGINAL_DIR!"
    ) else (
        :: Use cmake for all other cases
        echo Using cmake build for Maya !YEAR!
        
        call set "VS_GEN=%%GENERATOR_!YEAR!%%"
        
        echo Configuring for Maya !YEAR!...
        cmake -H"%INPUT_DIR:\=/%" -B"!BUILD_DIR:\=/!" ^
              -G !VS_GEN! ^
              -DMAYA_VERSION=!YEAR! ^
              -DMAYA_DEVKIT="!DEVKIT_DIR:\=/!" ^
              -DCMAKE_INSTALL_PREFIX="!OUTPUT_DIR:\=/!"
        
        echo Building !PLUGIN_NAME!...
        cmake --build "!BUILD_DIR!" --config Release
        
        if exist "!BUILD_DIR!\Release\!PLUGIN_NAME!.mll" (
            copy /Y "!BUILD_DIR!\Release\!PLUGIN_NAME!.mll" "!OUTPUT_DIR!\" >nul
            echo Success: !PLUGIN_NAME!.mll created for Maya !YEAR!
        ) else (
            echo Error: Build failed for Maya !YEAR!
        )
    )
    
    :skip_to_next
    REM This label allows us to skip to the next iteration
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