@echo off
REM CleverVB Web Deployment Script for Windows
REM This script builds the Flutter web app with environment variables for secure API key handling

echo 🚀 CleverVB Web Deployment Script
echo =================================

REM Check if environment variables are provided
if "%SUPABASE_URL%"=="" goto missing_vars
if "%SUPABASE_ANON_KEY%"=="" goto missing_vars
goto vars_ok

:missing_vars
echo ❌ Error: Required environment variables not set!
echo Please set the following environment variables:
echo   - SUPABASE_URL
echo   - SUPABASE_ANON_KEY
echo.
echo Example usage:
echo   set SUPABASE_URL=https://your-project.supabase.co
echo   set SUPABASE_ANON_KEY=your-anon-key-here
echo   set ENVIRONMENT=production
echo   scripts\deploy-web.bat
exit /b 1

:vars_ok
REM Set default environment if not specified
if "%ENVIRONMENT%"=="" set ENVIRONMENT=production

echo 📋 Configuration:
echo   Environment: %ENVIRONMENT%
echo   Supabase URL: %SUPABASE_URL%
echo   Supabase Key: %SUPABASE_ANON_KEY:~0,20%...[HIDDEN]
echo.

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Build web app with environment variables
echo 🔨 Building Flutter web app with secure configuration...
flutter build web ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=ENVIRONMENT=%ENVIRONMENT% ^
  --dart-define=ENABLE_LOGGING=false ^
  --release

echo ✅ Build completed successfully!
echo.
echo 📁 Web build output located at: build\web\
echo.
echo 🌐 Deployment options:
echo   1. Upload build\web\ contents to your web hosting service
echo   2. Use Firebase Hosting: firebase deploy
echo   3. Use Netlify: netlify deploy --prod --dir=build\web
echo   4. Use Vercel: vercel --prod build\web
echo.
echo 🔒 Security reminder:
echo   - Your API keys are now injected at build time
echo   - They are not stored in your source code
echo   - Make sure to keep your environment variables secure! 