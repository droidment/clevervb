# 🚀 CleverVB Web Deployment Guide

This guide explains how to securely deploy your CleverVB Flutter web application while protecting your API keys.

## 🔐 Security Overview

### ✅ What We've Implemented
- **Environment Variables**: API keys are injected at build time, not hardcoded
- **Build-time Injection**: Secrets are embedded only during the build process
- **Source Code Protection**: No sensitive keys in your Git repository
- **Development Fallbacks**: Safe defaults for local development

### 🚨 Important Security Notes

1. **Supabase Anonymous Key**: This key is designed to be exposed on the client-side
2. **RLS Policies**: Your real security comes from Supabase Row Level Security policies
3. **Never expose service role keys**: Only use the anonymous (public) key for web apps

## 🛠️ Deployment Methods

### Method 1: Using Deployment Scripts (Recommended)

#### For Windows:
```cmd
# Set your environment variables
set SUPABASE_URL=https://your-project.supabase.co
set SUPABASE_ANON_KEY=your-anonymous-key-here
set ENVIRONMENT=production

# Run the deployment script
scripts\deploy-web.bat
```

#### For macOS/Linux:
```bash
# Set your environment variables
export SUPABASE_URL='https://your-project.supabase.co'
export SUPABASE_ANON_KEY='your-anonymous-key-here'
export ENVIRONMENT='production'

# Make script executable and run
chmod +x scripts/deploy-web.sh
./scripts/deploy-web.sh
```

### Method 2: Manual Flutter Build

```bash
flutter build web \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anonymous-key-here" \
  --dart-define=ENVIRONMENT="production" \
  --dart-define=ENABLE_LOGGING=false \
  --release
```

## 🌐 Hosting Platforms

### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init hosting

# Deploy
firebase deploy
```

### Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=build/web
```

### Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod build/web
```

### GitHub Pages
1. Build your app using the deployment script
2. Copy `build/web/` contents to your GitHub Pages repository
3. Ensure `index.html` is in the root directory

## 🔧 Environment Variables Reference

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SUPABASE_URL` | ✅ | Your Supabase project URL | `https://abc123.supabase.co` |
| `SUPABASE_ANON_KEY` | ✅ | Your Supabase anonymous/public key | `eyJhbGciOiJIUzI1...` |
| `ENVIRONMENT` | ❌ | Deployment environment | `production` |
| `ENABLE_LOGGING` | ❌ | Enable debug logging | `false` |
| `GOOGLE_WEB_CLIENT_ID` | ❌ | Google OAuth client ID | `123-abc.apps.googleusercontent.com` |

## 🔒 Security Best Practices

### 1. Supabase Security
- ✅ Use Row Level Security (RLS) policies on all tables
- ✅ Never expose service role keys in client applications
- ✅ Regularly rotate your API keys
- ✅ Monitor usage in Supabase dashboard

### 2. Environment Management
- ✅ Use different Supabase projects for development/production
- ✅ Store environment variables securely (not in scripts)
- ✅ Use CI/CD secrets for automated deployments

### 3. Web App Security
- ✅ Enable HTTPS on your hosting platform
- ✅ Configure proper Content Security Policy (CSP)
- ✅ Implement proper authentication flows
- ✅ Validate all user inputs

## 🚀 CI/CD Deployment

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.0'
    
    - name: Build web app
      run: |
        flutter build web \
          --dart-define=SUPABASE_URL="${{ secrets.SUPABASE_URL }}" \
          --dart-define=SUPABASE_ANON_KEY="${{ secrets.SUPABASE_ANON_KEY }}" \
          --dart-define=ENVIRONMENT="production" \
          --release
    
    - name: Deploy to Firebase
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        projectId: your-firebase-project-id
```

## 🔍 Troubleshooting

### Common Issues

**1. "Missing environment variables" error:**
- Ensure all required environment variables are set
- Check for typos in variable names
- Verify variables are exported in your shell

**2. "API key not working" error:**
- Confirm you're using the anonymous key, not service role key
- Check Supabase project URL is correct
- Verify RLS policies allow your operations

**3. "Build fails" error:**
- Run `flutter clean && flutter pub get`
- Check Flutter version compatibility
- Ensure all dependencies are up to date

### Verification Steps

1. **Build locally first:**
   ```bash
   flutter build web --release
   ```

2. **Test environment variables:**
   ```bash
   echo $SUPABASE_URL
   echo $SUPABASE_ANON_KEY
   ```

3. **Verify configuration:**
   Add this to your main.dart temporarily:
   ```dart
   print('Supabase URL: ${Env.supabaseUrl}');
   print('Environment: ${Env.environment}');
   ```

## 📞 Support

If you encounter issues:
1. Check the Flutter documentation
2. Review Supabase documentation
3. Check your hosting platform's logs
4. Verify your RLS policies in Supabase

## 🎉 Success!

Once deployed, your CleverVB app will be:
- ✅ Secure with proper API key handling
- ✅ Optimized for production performance  
- ✅ Protected by Supabase Row Level Security
- ✅ Ready for your users to enjoy!

---

**Remember**: The anonymous key is meant to be public, but your real security comes from properly configured RLS policies in Supabase! 