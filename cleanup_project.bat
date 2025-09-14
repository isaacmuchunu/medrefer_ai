@echo off
echo MedRefer AI Project Cleanup Script
echo ===================================

echo.
echo Step 1: Stopping any running Flutter processes...
taskkill /f /im dart.exe 2>nul
taskkill /f /im flutter.exe 2>nul
taskkill /f /im dartaotruntime.exe 2>nul

echo.
echo Step 2: Waiting for processes to terminate...
timeout /t 3 /nobreak >nul

echo.
echo Step 3: Attempting to remove problematic Flutter directory...
if exist "lib\presentation\splash_screen\flutter" (
    echo Found problematic Flutter directory. Attempting removal...
    rmdir /s /q "lib\presentation\splash_screen\flutter" 2>nul
    if exist "lib\presentation\splash_screen\flutter" (
        echo WARNING: Could not remove directory automatically.
        echo Please manually delete: lib\presentation\splash_screen\flutter
        echo You may need to:
        echo 1. Close your IDE/editor
        echo 2. Restart your computer
        echo 3. Manually delete the directory
    ) else (
        echo Successfully removed problematic Flutter directory.
    )
) else (
    echo No problematic Flutter directory found.
)

echo.
echo Step 4: Cleaning Flutter project...
flutter clean 2>nul

echo.
echo Step 5: Getting dependencies...
flutter pub get 2>nul

echo.
echo Step 6: Running Flutter doctor...
flutter doctor

echo.
echo Cleanup completed!
echo If you still see VCS errors in your IDE, please:
echo 1. Close your IDE completely
echo 2. Delete the problematic directory manually if it still exists
echo 3. Restart your IDE
echo 4. Re-import the project

pause
