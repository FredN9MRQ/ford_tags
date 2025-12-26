# WebAuthn Device Enrollment Guide

**ADHD-Friendly Quick Start for Face ID & Windows Hello**

---

## 🎯 What This Does

Lets you log into Authentik (and all SSO-connected services) using:
- 📱 **iPhone Face ID** - Just look at your phone
- 💻 **Windows Hello** - Fingerprint, face, or PIN
- 🔐 **Security Keys** - YubiKey, etc. (optional)

**After enrollment:** No more typing passwords! Just use biometrics.

---

## 📱 iPhone Face ID Enrollment

### Prerequisites
- iPhone with Face ID (iPhone X or newer)
- Safari browser (WebAuthn works best in Safari on iOS)

### Steps (2 minutes)

1. **Open Safari** on your iPhone
2. Go to: `https://auth.nianticbooks.com`
3. Log in with your Authentik username & password
4. Tap your **avatar** (top right) → **Settings**
5. Tap **MFA Devices**
6. Tap **Enroll WebAuthn Device**
7. **Name it:** `iPhone 15` (or whatever your model is)
8. Tap **Continue**
9. **Face ID prompt appears** - Look at your phone
10. ✅ **Done!**

### Testing
1. Log out of Authentik
2. Go to any SSO service (like Proxmox: `https://freddesk.nianticbooks.com`)
3. Select **authentik** realm
4. Click **Login with authentik**
5. After entering username, you'll see **"Use your passkey"**
6. Face ID activates automatically!

---

## 💻 Windows Hello Enrollment

### Prerequisites
- Windows 10/11 with Hello configured
- Supported hardware:
  - Fingerprint reader
  - IR camera (for face)
  - TPM 2.0 chip
- Chrome, Edge, or Firefox browser

### Steps (2 minutes)

1. **Open browser** (Chrome/Edge recommended)
2. Go to: `https://auth.nianticbooks.com`
3. Log in with your Authentik username & password
4. Click your **avatar** (top right) → **Settings**
5. Click **MFA Devices**
6. Click **Enroll WebAuthn Device**
7. **Name it:** `Work Laptop` or `Gaming PC`
8. Click **Continue**
9. **Windows Hello prompt appears**
   - Fingerprint: Touch the reader
   - Face: Look at camera
   - PIN: Enter your Windows PIN
10. ✅ **Done!**

### Testing
1. Log out of Authentik
2. Go to any SSO service
3. After entering username, Windows Hello will prompt automatically
4. Use your fingerprint/face/PIN to complete login

---

## 🔑 Security Key Enrollment (Optional)

### If you have a YubiKey or similar:

1. Follow the same steps as above
2. Name it: `YubiKey 5`
3. When prompted, **insert key and tap the button**
4. ✅ Done!

**Pro tip:** Enroll multiple devices as backups!

---

## 🔧 Managing Your Devices

### View Enrolled Devices
1. https://auth.nianticbooks.com
2. Avatar → Settings → MFA Devices
3. See all your enrolled WebAuthn devices

### Remove a Device
1. Go to MFA Devices
2. Click the **X** next to the device name
3. Confirm removal

### Rename a Device
1. Go to MFA Devices
2. Click **Edit** next to device
3. Change name
4. Save

---

## 🚨 Troubleshooting

### "WebAuthn not supported" error
- **iPhone:** Use Safari (not Chrome)
- **Windows:** Update to latest Windows 10/11
- **Browser:** Use Chrome, Edge, or Firefox (latest version)

### Face ID/Windows Hello doesn't prompt
- Make sure device is enrolled (check MFA Devices page)
- Try removing and re-enrolling
- Check browser is allowed to use biometrics

### Lost access to enrolled device
- Log in with username/password instead
- Remove lost device from MFA Devices
- Enroll new device

### Can't enroll - "Already registered"
- You may have enrolled this device before
- Check MFA Devices list
- Try a different name

---

## 💡 Pro Tips

### Multiple Devices
Enroll ALL your devices for convenience:
- Primary phone (Face ID)
- Work laptop (Windows Hello)
- Home desktop (Windows Hello)
- Backup security key (YubiKey)

### Backup Methods
Always have a backup login method:
- Password (keep it strong!)
- TOTP app (Google Authenticator, Authy)
- Security key

### Naming Convention
Use descriptive names:
- ✅ `iPhone 15 Pro - Personal`
- ✅ `ThinkPad X1 - Work`
- ✅ `YubiKey 5C - Backup`
- ❌ `Device 1`
- ❌ `My Phone`

---

## 📊 Where WebAuthn Works

After enrolling, you can use Face ID/Windows Hello to log into:

**Currently Configured:**
- ✅ Authentik SSO (https://auth.nianticbooks.com)
- ✅ Proxmox (https://freddesk.nianticbooks.com) - via Authentik
- ✅ Any future services connected to Authentik SSO

**How it works:**
1. You try to access a service (e.g., Proxmox)
2. Service redirects to Authentik for login
3. Authentik offers WebAuthn (Face ID/Windows Hello)
4. You authenticate with biometrics
5. Authentik logs you in and sends you back to the service
6. ✅ You're in!

---

## 🔐 Security Notes

### How Secure Is This?

**Very secure!** WebAuthn uses public-key cryptography:
- Private key stays on your device (never transmitted)
- Each service gets a unique credential
- Can't be phished (domain-bound)
- Requires physical device presence

**More secure than passwords** because:
- No password to steal
- No password to reuse
- No password to phish
- Requires biometric + device possession

### Privacy

- Authentik doesn't store your biometric data
- Biometrics stay on your device (iPhone/Windows)
- Only cryptographic signatures are sent
- Each service gets a unique identifier

---

## 📝 Quick Reference Card

### Enroll Device (30 seconds)
1. https://auth.nianticbooks.com
2. Avatar → Settings → MFA Devices
3. Enroll WebAuthn Device
4. Name it → Continue
5. Use Face ID / Windows Hello
6. Done!

### Login with WebAuthn
1. Go to any SSO service
2. Enter username
3. Face ID / Windows Hello prompts automatically
4. Authenticate
5. You're in!

### Remove Device
1. Settings → MFA Devices
2. Click X next to device
3. Confirm

---

## 🎓 Additional Resources

- **Authentik Docs:** https://docs.goauthentik.io/
- **WebAuthn Info:** https://webauthn.io/
- **Supported Browsers:** https://caniuse.com/webauthn

---

**Questions?** Check Authentik logs or test in an incognito window first!

**Last Updated:** 2025-12-25
