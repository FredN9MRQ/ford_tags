# Authentik SSO Integration Guide

**Last Updated:** 2025-12-13

## Overview

This guide provides step-by-step instructions for integrating all homelab services with Authentik SSO (10.0.10.21).

**Goal:** Single sign-on for all services - log in to Authentik once, access everything without individual passwords.

## Authentik Access

- **URL:** https://auth.nianticbooks.com
- **Admin Username:** akadmin
- **Admin Password:** TempPassword123! (CHANGE THIS IMMEDIATELY)

## Integration Status

| Service | IP | Protocol | Status |
|---------|-----|----------|--------|
| Home Assistant | 10.0.10.24 | OAuth2/OIDC | Not Started |
| Proxmox (main-pve) | 10.0.10.3 | OpenID Connect | Not Started |
| Proxmox (gaming-pve) | 10.0.10.2 | OpenID Connect | Not Started |
| Proxmox (backup-pve) | 10.0.10.4 | OpenID Connect | Not Started |
| n8n | 10.0.10.22 | OAuth2/OIDC | Not Started |
| UniFi Controller | 10.0.10.1 | RADIUS | Not Started |

---

## 1. Home Assistant OAuth2 Integration

### Prerequisites
- Home Assistant accessible at https://bob.nianticbooks.com
- Authentik admin access

### Step 1: Create OAuth2 Provider in Authentik

1. Log in to Authentik at https://auth.nianticbooks.com
2. Navigate to **Applications** → **Providers**
3. Click **Create**
4. Select **OAuth2/OpenID Provider**
5. Configure:
   - **Name:** Home Assistant
   - **Authorization Flow:** default-provider-authorization-implicit-consent
   - **Client Type:** Confidential
   - **Client ID:** (auto-generated - save this)
   - **Client Secret:** (auto-generated - save this)
   - **Redirect URIs:**
     ```
     https://bob.nianticbooks.com/auth/external/callback
     ```
   - **Signing Key:** authentik Self-signed Certificate
6. Click **Finish**

### Step 2: Create Application in Authentik

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure:
   - **Name:** Home Assistant
   - **Slug:** home-assistant
   - **Provider:** Select the provider created above
   - **Launch URL:** https://bob.nianticbooks.com
4. Click **Create**

### Step 3: Configure Home Assistant

1. Open Home Assistant configuration at https://bob.nianticbooks.com
2. Navigate to **Settings** → **People** → **Integrations**
3. Click **Add Integration**
4. Search for **Generic OAuth2**
5. Configure:
   - **Client ID:** (from Step 1)
   - **Client Secret:** (from Step 1)
   - **Authorize URL:** `https://auth.nianticbooks.com/application/o/authorize/`
   - **Token URL:** `https://auth.nianticbooks.com/application/o/token/`
   - **User Info URL:** `https://auth.nianticbooks.com/application/o/userinfo/`

### Step 4: Edit configuration.yaml

Add the following to `/config/configuration.yaml`:

```yaml
auth_providers:
  - type: homeassistant
  - type: command_line
    command: /config/authentik_auth.sh
    args: ["<<username>>", "<<password>>"]
    meta: true
```

Create `/config/authentik_auth.sh`:

```bash
#!/bin/bash
# Authentik OAuth2 authentication script for Home Assistant
# This script validates credentials against Authentik

USERNAME=$1
PASSWORD=$2

# OAuth2 token endpoint
TOKEN_URL="https://auth.nianticbooks.com/application/o/token/"
CLIENT_ID="<your-client-id>"
CLIENT_SECRET="<your-client-secret>"

# Get token
RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET")

# Check if token was received
if echo "$RESPONSE" | grep -q "access_token"; then
  echo "$USERNAME"
  exit 0
else
  exit 1
fi
```

Make executable: `chmod +x /config/authentik_auth.sh`

### Step 5: Restart and Test

1. Restart Home Assistant
2. Navigate to https://bob.nianticbooks.com
3. You should see an option to "Sign in with Authentik"
4. Click and authenticate through Authentik

---

## 2. Proxmox OpenID Connect Integration

### Prerequisites
- Proxmox hosts accessible (10.0.10.2, 10.0.10.3, 10.0.10.4)
- Authentik admin access

### Step 1: Create OpenID Provider in Authentik

1. Log in to Authentik at https://auth.nianticbooks.com
2. Navigate to **Applications** → **Providers**
3. Click **Create**
4. Select **OAuth2/OpenID Provider**
5. Configure:
   - **Name:** Proxmox
   - **Authorization Flow:** default-provider-authorization-implicit-consent
   - **Client Type:** Confidential
   - **Client ID:** proxmox
   - **Client Secret:** (auto-generated - save this)
   - **Redirect URIs:**
     ```
     https://10.0.10.2:8006
     https://10.0.10.3:8006
     https://10.0.10.4:8006
     https://freddesk.nianticbooks.com
     ```
   - **Scopes:** openid, profile, email
6. Click **Finish**

### Step 2: Create Application in Authentik

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure:
   - **Name:** Proxmox
   - **Slug:** proxmox
   - **Provider:** Select the provider created above
   - **Launch URL:** https://freddesk.nianticbooks.com
4. Click **Create**

### Step 3: Configure Proxmox (Repeat for each host)

SSH to each Proxmox host and run:

```bash
# Add OpenID Connect realm
pveum realm add authentik --type openid \
  --issuer-url https://auth.nianticbooks.com/application/o/proxmox/ \
  --client-id proxmox \
  --client-key "<client-secret-from-step-1>" \
  --username-claim preferred_username \
  --scopes "openid profile email" \
  --autocreate 1 \
  --default 0
```

### Step 4: Create Proxmox User Group

In Authentik:

1. Navigate to **Directory** → **Groups**
2. Click **Create**
3. Configure:
   - **Name:** proxmox-admins
   - **Parent:** (leave empty)
4. Click **Create**

### Step 5: Configure Group Mapping in Proxmox

On each Proxmox host:

```bash
# Create group for Authentik users
pveum group add authentik-admins

# Add PVEAdmin role to the group
pveum acl modify / --group authentik-admins --role PVEAdmin
```

### Step 6: Test Login

1. Navigate to https://freddesk.nianticbooks.com
2. Select **Realm: authentik** from dropdown
3. Enter your Authentik username
4. You should be redirected to Authentik for authentication

---

## 3. n8n OAuth2 Integration

### Prerequisites
- n8n accessible at 10.0.10.22
- Authentik admin access

### Step 1: Create OAuth2 Provider in Authentik

1. Log in to Authentik at https://auth.nianticbooks.com
2. Navigate to **Applications** → **Providers**
3. Click **Create**
4. Select **OAuth2/OpenID Provider**
5. Configure:
   - **Name:** n8n
   - **Authorization Flow:** default-provider-authorization-implicit-consent
   - **Client Type:** Confidential
   - **Client ID:** n8n
   - **Client Secret:** (auto-generated - save this)
   - **Redirect URIs:**
     ```
     http://10.0.10.22:5678/rest/oauth2-credential/callback
     https://n8n.nianticbooks.com/rest/oauth2-credential/callback
     ```
6. Click **Finish**

### Step 2: Create Application in Authentik

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure:
   - **Name:** n8n
   - **Slug:** n8n
   - **Provider:** Select the provider created above
   - **Launch URL:** http://10.0.10.22:5678
4. Click **Create**

### Step 3: Configure n8n Environment Variables

SSH to n8n container (ID 110):

```bash
ssh root@10.0.10.3
pct enter 110

# Edit n8n environment file
nano /etc/environment
```

Add:

```bash
N8N_SSO_ENABLED=true
N8N_SSO_OIDC_CONFIG_issuer=https://auth.nianticbooks.com/application/o/n8n/
N8N_SSO_OIDC_CONFIG_clientId=n8n
N8N_SSO_OIDC_CONFIG_clientSecret=<client-secret-from-step-1>
N8N_SSO_OIDC_CONFIG_authorizationUrl=https://auth.nianticbooks.com/application/o/authorize/
N8N_SSO_OIDC_CONFIG_tokenUrl=https://auth.nianticbooks.com/application/o/token/
N8N_SSO_OIDC_CONFIG_userinfoUrl=https://auth.nianticbooks.com/application/o/userinfo/
```

### Step 4: Restart n8n

```bash
systemctl restart n8n
# or if using Docker:
docker restart n8n
```

### Step 5: Test Login

1. Navigate to http://10.0.10.22:5678
2. Click **Sign in with SSO**
3. Authenticate through Authentik

---

## 4. UniFi RADIUS Integration

### Prerequisites
- UniFi Controller accessible at 10.0.10.1
- Authentik admin access

### Step 1: Enable RADIUS in Authentik

1. Log in to Authentik at https://auth.nianticbooks.com
2. Navigate to **Applications** → **Providers**
3. Click **Create**
4. Select **RADIUS Provider**
5. Configure:
   - **Name:** UniFi RADIUS
   - **Shared Secret:** (generate strong password - save this)
   - **Client Networks:** 10.0.10.0/24

### Step 2: Create Application in Authentik

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure:
   - **Name:** UniFi
   - **Slug:** unifi
   - **Provider:** Select RADIUS provider created above
   - **Launch URL:** https://10.0.10.1

### Step 3: Configure UniFi Controller

1. Log in to UniFi Controller at https://10.0.10.1
2. Navigate to **Settings** → **Profiles** → **RADIUS**
3. Click **Create New RADIUS Profile**
4. Configure:
   - **Profile Name:** Authentik
   - **Authentication Servers:**
     - **IP Address:** 10.0.10.21
     - **Port:** 1812
     - **Shared Secret:** (from Step 1)
   - **Accounting Servers:**
     - **IP Address:** 10.0.10.21
     - **Port:** 1813
     - **Shared Secret:** (from Step 1)
5. Click **Save**

### Step 4: Apply RADIUS to WiFi Networks

1. Navigate to **Settings** → **WiFi**
2. Edit your WiFi network
3. Under **Security:**
   - **Security Protocol:** WPA2 Enterprise
   - **RADIUS Profile:** Authentik
4. Click **Save**

### Step 5: Test Connection

1. Connect to WiFi network
2. Enter Authentik username and password
3. Should authenticate successfully

---

## Security Best Practices

### 1. Strong Password Policy

In Authentik:
1. Navigate to **Policies** → **Password Policies**
2. Create or edit policy:
   - **Minimum Length:** 12
   - **Enable zxcvbn:** Yes
   - **Minimum Score:** 3
   - **Check Static Rules:** Yes

### 2. Multi-Factor Authentication (MFA)

Enable for all admin users:
1. Navigate to **Flows & Stages**
2. Edit **default-authentication-flow**
3. Add stage: **authenticator-validation-stage**
4. Configure TOTP/WebAuthn

### 3. Session Timeout

1. Navigate to **System** → **Settings**
2. Configure:
   - **Session Duration:** 8 hours
   - **Remember Me Duration:** 30 days

### 4. Failed Login Protection

1. Navigate to **Policies** → **Reputation Policies**
2. Enable IP reputation blocking
3. Configure:
   - **Failed Login Threshold:** 5
   - **Block Duration:** 1 hour

---

## Troubleshooting

### Issue: "Invalid redirect URI"

**Solution:** Ensure the redirect URI in Authentik exactly matches the URI used by the application (including http/https, port, and path).

### Issue: "Invalid client credentials"

**Solution:** Double-check the Client ID and Client Secret match exactly between Authentik and the application.

### Issue: "User not authorized"

**Solution:** Check that the user has the appropriate group membership or permissions in Authentik.

### Issue: RADIUS authentication fails

**Solution:**
1. Verify shared secret matches
2. Check firewall allows UDP 1812/1813
3. Verify client network is in allowed list
4. Check Authentik logs: **Events** → **Logs**

---

## Backup Configuration

### Export Authentik Configuration

```bash
ssh root@10.0.10.3
pct enter 121
cd /opt/authentik
docker compose exec server ak export > /backup/authentik-config-$(date +%Y%m%d).json
```

### Backup PostgreSQL Database

```bash
ssh root@10.0.10.3
pct enter 102
pg_dump -U authentik authentik > /backup/authentik-db-$(date +%Y%m%d).sql
```

---

## Next Steps

1. ✅ Change default admin password
2. ⬜ Configure Home Assistant OAuth2
3. ⬜ Configure Proxmox OpenID Connect (all 3 hosts)
4. ⬜ Configure n8n OAuth2
5. ⬜ Configure UniFi RADIUS
6. ⬜ Enable MFA for admin accounts
7. ⬜ Create user accounts for family/authorized users
8. ⬜ Set up backup automation

---

## Additional Resources

- [Authentik Documentation](https://docs.goauthentik.io/)
- [Home Assistant Auth Providers](https://www.home-assistant.io/docs/authentication/providers/)
- [Proxmox OpenID Connect](https://pve.proxmox.com/wiki/User_Management#pveum_openid_configuration)
- [n8n SSO Documentation](https://docs.n8n.io/hosting/configuration/environment-variables/security/#sso)
