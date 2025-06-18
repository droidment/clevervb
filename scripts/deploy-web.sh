#!/bin/bash

# CleverVB Web Deployment Script
# This script builds the Flutter web app with environment variables for secure API key handling

set -e

echo "🚀 CleverVB Web Deployment Script"
echo "================================="

# Check if environment variables are provided
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Required environment variables not set!"
    echo "Please set the following environment variables:"
    echo "  - SUPABASE_URL"
    echo "  - SUPABASE_ANON_KEY"
    echo ""
    echo "Example usage:"
    echo "  export SUPABASE_URL='https://your-project.supabase.co'"
    echo "  export SUPABASE_ANON_KEY='your-anon-key-here'"
    echo "  export ENVIRONMENT='production'"
    echo "  ./scripts/deploy-web.sh"
    exit 1
fi

# Set default environment if not specified
if [ -z "$ENVIRONMENT" ]; then
    export ENVIRONMENT="production"
fi

echo "📋 Configuration:"
echo "  Environment: $ENVIRONMENT"
echo "  Supabase URL: $SUPABASE_URL"
echo "  Supabase Key: ${SUPABASE_ANON_KEY:0:20}...[HIDDEN]"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build web app with environment variables
echo "🔨 Building Flutter web app with secure configuration..."
flutter build web \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --dart-define=ENABLE_LOGGING=false \
  --release

echo "✅ Build completed successfully!"
echo ""
echo "📁 Web build output located at: build/web/"
echo ""
echo "🌐 Deployment options:"
echo "  1. Upload build/web/ contents to your web hosting service"
echo "  2. Use Firebase Hosting: firebase deploy"
echo "  3. Use Netlify: netlify deploy --prod --dir=build/web"
echo "  4. Use Vercel: vercel --prod build/web"
echo ""
echo "🔒 Security reminder:"
echo "  - Your API keys are now injected at build time"
echo "  - They are not stored in your source code"
echo "  - Make sure to keep your environment variables secure!" 