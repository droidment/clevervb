#!/bin/bash

# CleverVB Web Deployment Script
# This script builds and deploys the Flutter web app to Firebase

set -e  # Exit on any error

echo "🚀 Starting CleverVB Web Deployment..."

# Check if we're in the project root
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Check if required tools are installed
command -v flutter >/dev/null 2>&1 || { echo "❌ Flutter is required but not installed. Aborting." >&2; exit 1; }
command -v firebase >/dev/null 2>&1 || { echo "❌ Firebase CLI is required but not installed. Aborting." >&2; exit 1; }

# Run database migrations first
echo "📊 Running database migrations..."
cd supabase
if command -v supabase >/dev/null 2>&1; then
    supabase db push
    echo "✅ Database migrations completed"
else
    echo "⚠️  Supabase CLI not found. Please run migrations manually:"
    echo "   1. Go to your Supabase project dashboard"
    echo "   2. Run the SQL from migrations/20250618042746_fix_user_table_and_rls.sql"
fi
cd ..

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for web with release mode
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer html

# Check if build was successful
if [ ! -d "build/web" ]; then
    echo "❌ Flutter build failed"
    exit 1
fi

# Deploy to Firebase
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting

echo "✅ Deployment completed successfully!"
echo "🌐 Your app should be available at your Firebase hosting URL"

# Check Firebase project
echo "📝 Firebase project info:"
firebase projects:list 