# 📧 Readify - Production Setup Guide

## 🔧 **Setting Up Real Email Accounts**

This guide will help you set up **real email functionality** for Gmail, Outlook, Yahoo, and custom email servers.

---

## 🏗️ **1. Gmail Setup (OAuth 2.0)**

### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable **Gmail API**
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client IDs**

### Step 2: Configure OAuth Client
- **Application type**: Web application
- **Authorized redirect URIs**:
  - `http://localhost:8080` (for web testing)
  - `https://yourdomain.com` (for production)

### Step 3: Update Configuration
1. Copy your **Client ID**
2. Update `web/index.html`:
   ```html
   <meta name="google-signin-client_id" content="YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com">
   ```
3. Update `lib/utils/constants.dart`:
   ```dart
   static const String googleClientId = 'YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com';
   ```

### Step 4: Android Configuration (Optional)
1. Download `google-services.json` from Firebase
2. Place in `android/app/google-services.json`

---

## 📧 **2. Outlook Setup (App Password)**

### Step 1: Enable App Passwords
1. Go to [Microsoft Account Security](https://account.microsoft.com/security)
2. Sign in to your Outlook account
3. Go to **Security** → **Advanced security options**
4. Enable **App passwords**
5. Generate a new app password for "Email app"

### Step 2: Use App Password
- **Email**: Your regular Outlook email
- **Password**: Use the generated app password (NOT your regular password)

### Step 3: Enable IMAP (if needed)
1. Go to Outlook.com → **Settings** → **Mail** → **Sync email**
2. Enable **IMAP access**

---

## 🟣 **3. Yahoo Setup (App Password)**

### Step 1: Enable App Passwords
1. Go to [Yahoo Account Security](https://login.yahoo.com/account/security)
2. Sign in to your Yahoo account
3. Enable **2-step verification** first
4. Go to **App passwords**
5. Generate password for "Email app"

### Step 2: Use App Password
- **Email**: Your regular Yahoo email
- **Password**: Use the generated app password

### Step 3: Enable IMAP Access
1. Go to Yahoo Mail → **Settings** → **More Settings**
2. Go to **Mailboxes** → **IMAP access**
3. Enable IMAP access

---

## ⚙️ **4. Custom Email Server Setup**

For custom email servers, you'll need:

### IMAP Settings:
- **Server**: `mail.yourdomain.com`
- **Port**: `993` (SSL) or `143` (non-SSL)
- **Security**: SSL/TLS recommended

### SMTP Settings:
- **Server**: `mail.yourdomain.com`
- **Port**: `587` (TLS) or `465` (SSL)
- **Security**: STARTTLS or SSL/TLS

### Common Providers:
- **Gmail**: imap.gmail.com:993, smtp.gmail.com:587
- **Outlook**: outlook.office365.com:993, smtp-mail.outlook.com:587
- **Yahoo**: imap.mail.yahoo.com:993, smtp.mail.yahoo.com:587

---

## 🚀 **5. Testing Your Setup**

### Test Accounts:
1. **Gmail**: Use OAuth (requires Google Cloud setup)
2. **Outlook**: Use email + app password
3. **Yahoo**: Use email + app password
4. **Custom**: Use email + regular password

### Quick Test:
```bash
flutter run -d chrome
```

### Troubleshooting:
- **Gmail OAuth errors**: Check client ID configuration
- **Authentication failed**: Verify app passwords are enabled
- **Connection timeout**: Check firewall/network settings
- **IMAP/SMTP errors**: Verify server settings and ports

---

## 🔐 **6. Security Notes**

- ✅ **Use app passwords** for Outlook/Yahoo (never regular passwords)
- ✅ **Enable 2FA** on all email accounts
- ✅ **Use SSL/TLS** for all connections
- ✅ **Store credentials securely** (app uses FlutterSecureStorage)
- ❌ **Never commit** real credentials to version control

---

## 📱 **7. Deployment**

### Web Deployment:
1. Update OAuth redirect URIs for your domain
2. Build: `flutter build web`
3. Deploy `build/web/` to your web server

### Mobile Deployment:
1. Add proper OAuth configurations
2. Build: `flutter build apk` or `flutter build ios`
3. Test on real devices

---

## ✅ **Success!**

Once configured, your Readify app will have:
- ✅ **Real Gmail integration** with OAuth
- ✅ **Real Outlook/Yahoo** with app passwords
- ✅ **Custom email servers** with IMAP/SMTP
- ✅ **Secure credential storage**
- ✅ **Full email functionality** (read, send, delete)

**Need help?** Check the troubleshooting section or create an issue!