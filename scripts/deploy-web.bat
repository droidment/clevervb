@echo off
setlocal enabledelayedexpansion

REM CleverVB Web Deployment Script for Windows
REM This script builds and deploys the Flutter web app to Firebase

echo 🚀 Starting CleverVB Web Deployment...

REM Check if we're in the project root
if not exist "pubspec.yaml" (
    echo ❌ Error: Please run this script from the project root directory
    exit /b 1
)

REM Check if required tools are installed
where flutter >nul 2>nul
if errorlevel 1 (
    echo ❌ Flutter is required but not installed. Aborting.
    exit /b 1
)

where firebase >nul 2>nul
if errorlevel 1 (
    echo ❌ Firebase CLI is required but not installed. Aborting.
    exit /b 1
)

REM Run database migrations first
echo 📊 Running database migrations...
cd supabase
where supabase >nul 2>nul
if errorlevel 1 (
    echo ⚠️  Supabase CLI not found. Please run migrations manually:
    echo    1. Go to your Supabase project dashboard
    echo    2. Run the SQL from migrations/20250618042746_fix_user_table_and_rls.sql
) else (
    supabase db push
    echo ✅ Database migrations completed
)
cd ..

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Build for web with release mode
echo 🔨 Building Flutter web app...
flutter build web --release --web-renderer html

REM Check if build was successful
if not exist "build\web" (
    echo ❌ Flutter build failed
    exit /b 1
)

REM Deploy to Firebase
echo 🚀 Deploying to Firebase...
firebase deploy --only hosting

echo ✅ Deployment completed successfully!
echo 🌐 Your app should be available at your Firebase hosting URL

REM Check Firebase project
echo 📝 Firebase project info:
firebase projects:list

pause 