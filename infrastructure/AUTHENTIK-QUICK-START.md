# Authentik Quick Start Guide

## Step 1: Change Your Password

1. Go to https://auth.nianticbooks.com
2. Log in with:
   - Username: `akadmin`
   - Password: `TempPassword123!`
3. Click your avatar (top right) → **Settings**
4. Click **Change Password**
5. Set a strong, memorable password

---

## Step 2: Set Up Home Assistant OAuth2

### In Authentik Web UI:

1. Navigate to **Applications** → **Providers**
2. Click **Create**
3. Select **OAuth2/OpenID Provider**
4. Fill in the form:
   - **Name:** `Home Assistant`
   - **Authorization flow:** `default-provider-authorization-implicit-consent`
   - **Client type:** `Confidential`
   - **Client ID:** Leave auto-generated (SAVE THIS VALUE)
   - **Client secret:** Leave auto-generated (SAVE THIS VALUE)
   - **Redirect URIs:** Click "Add new item" and enter:
     ```
     https://bob.nianticbooks.com/auth/external/callback
     ```
   - **Signing key:** `authentik Self-signed Certificate`
5. Click **Finish**
6. **IMPORTANT:** Copy the Client ID and Client Secret - you'll need these!

### Create the Application:

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Fill in:
   - **Name:** `Home Assistant`
   - **Slug:** `home-assistant`
   - **Provider:** Select the "Home Assistant" provider you just created
   - **Launch URL:** `https://bob.nianticbooks.com`
4. Click **Create**

### Configure Home Assistant:

Unfortunately, Home Assistant doesn't natively support generic OAuth2 for authentication (only for integrations). We need to use a different approach.

**Option 1: Use Authentik's Proxy Provider (Recommended)**

This puts Authentik in front of Home Assistant:

1. In Authentik, create a new **Proxy Provider** instead:
   - **Name:** `Home Assistant Proxy`
   - **Authorization flow:** `default-provider-authorization-implicit-consent`
   - **Type:** `Forward auth (single application)`
   - **External host:** `https://bob.nianticbooks.com`
   - **Internal host:** `http://10.0.10.24:8123`

2. Update Caddy configuration on VPS to use forward auth:
   ```
   bob.nianticbooks.com {
       forward_auth 10.0.10.21:9000 {
           uri /outpost.goauthentik.io/auth/caddy
           copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email
       }
       reverse_proxy 10.0.10.24:8123
   }
   ```

**Option 2: Command Line Auth Provider**

Use Home Assistant's command_line auth provider with Authentik LDAP (requires setting up LDAP in Authentik first).

**Option 3: Just use strong passwords**

Since Home Assistant SSO is complex, you could just set a strong password for now and focus on the easier integrations (Proxmox, n8n).

---

## Step 3: Set Up Proxmox OpenID Connect (EASIER!)

### In Authentik Web UI:

1. Navigate to **Applications** → **Providers**
2. Click **Create**
3. Select **OAuth2/OpenID Provider**
4. Fill in:
   - **Name:** `Proxmox`
   - **Authorization flow:** `default-provider-authorization-implicit-consent`
   - **Client type:** `Confidential`
   - **Client ID:** `proxmox` (manually set this!)
   - **Client secret:** Leave auto-generated (SAVE THIS VALUE)
   - **Redirect URIs:** Add these three:
     ```
     https://10.0.10.2:8006
     https://10.0.10.3:8006
     https://10.0.10.4:8006
     https://freddesk.nianticbooks.com
     ```
   - **Scopes:** `openid`, `profile`, `email` (default)
5. Click **Finish**
6. **SAVE THE CLIENT SECRET!**

### Create Application:

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Fill in:
   - **Name:** `Proxmox`
   - **Slug:** `proxmox`
   - **Provider:** Select "Proxmox" provider
   - **Launch URL:** `https://freddesk.nianticbooks.com`
4. Click **Create**

### Configure Proxmox (Run on each host):

SSH to each Proxmox host and run:

```bash
# For main-pve (10.0.10.3)
ssh root@10.0.10.3

pveum realm add authentik --type openid \
  --issuer-url https://auth.nianticbooks.com/application/o/proxmox/ \
  --client-id proxmox \
  --client-key "<YOUR-CLIENT-SECRET-FROM-ABOVE>" \
  --username-claim preferred_username \
  --scopes "openid profile email" \
  --autocreate 1 \
  --default 0

# Repeat for gaming-pve (10.0.10.2) and backup-pve (10.0.10.4)
```

### Test Proxmox Login:

1. Go to https://freddesk.nianticbooks.com
2. From the **Realm** dropdown, select **authentik**
3. Enter your Authentik username
4. You'll be redirected to Authentik to log in
5. After authentication, you'll be back in Proxmox!

---

## Step 4: Set Up n8n OAuth2 (EASY!)

### In Authentik Web UI:

1. Navigate to **Applications** → **Providers**
2. Click **Create**
3. Select **OAuth2/OpenID Provider**
4. Fill in:
   - **Name:** `n8n`
   - **Authorization flow:** `default-provider-authorization-implicit-consent`
   - **Client type:** `Confidential`
   - **Client ID:** `n8n` (manually set)
   - **Client secret:** Leave auto-generated (SAVE THIS)
   - **Redirect URIs:**
     ```
     http://10.0.10.22:5678/rest/oauth2-credential/callback
     ```
5. Click **Finish**

### Create Application:

1. **Applications** → **Applications** → **Create**
2. Fill in:
   - **Name:** `n8n`
   - **Slug:** `n8n`
   - **Provider:** Select "n8n" provider
   - **Launch URL:** `http://10.0.10.22:5678`
3. Click **Create**

### Configure n8n:

SSH to n8n container:

```bash
ssh root@10.0.10.3
pct enter 110

# Add environment variables (adjust path as needed)
cat >> /path/to/n8n/env/file << 'EOF'
N8N_SSO_OIDC_ENABLED=true
N8N_SSO_OIDC_CONFIG_issuer=https://auth.nianticbooks.com/application/o/n8n/
N8N_SSO_OIDC_CONFIG_clientId=n8n
N8N_SSO_OIDC_CONFIG_clientSecret=<YOUR-CLIENT-SECRET>
N8N_SSO_OIDC_CONFIG_authorizationUrl=https://auth.nianticbooks.com/application/o/authorize/
N8N_SSO_OIDC_CONFIG_tokenUrl=https://auth.nianticbooks.com/application/o/token/
N8N_SSO_OIDC_CONFIG_userinfoUrl=https://auth.nianticbooks.com/application/o/userinfo/
EOF

# Restart n8n
systemctl restart n8n  # or docker restart n8n
```

---

## Step 5: UniFi RADIUS (Advanced)

UniFi Controller authentication via RADIUS is complex and requires:
1. Setting up RADIUS provider in Authentik
2. Configuring UniFi to use RADIUS
3. This is primarily for WiFi auth, not controller login

**Recommendation:** Skip this for now, focus on Proxmox and n8n first.

---

## Priority Order (Easiest First):

1. **Change Authentik password** ← DO THIS FIRST!
2. **Proxmox** ← EASY, high value
3. **n8n** ← EASY, medium value
4. **Home Assistant** ← COMPLEX, skip for now
5. **UniFi** ← ADVANCED, skip for now

---

## Troubleshooting

### "Invalid redirect URI" error
- Make sure the redirect URI in Authentik EXACTLY matches what the application sends
- Include/exclude trailing slashes carefully
- Check http vs https

### "Client authentication failed"
- Double-check Client ID and Client Secret match exactly
- No extra spaces or characters

### Can't log in to Proxmox with Authentik
- Make sure you selected the "authentik" realm from the dropdown
- Check that the issuer URL ends with `/application/o/proxmox/`
- Verify client secret was entered correctly

### Authentik shows "User not found"
- The user must exist in Authentik first
- Either use `akadmin` or create a new user in **Directory** → **Users**

---

## Next Steps After Setup

1. Create additional users in Authentik (**Directory** → **Users**)
2. Set up groups for access control (**Directory** → **Groups**)
3. Enable MFA for admin accounts (**Flows** → Add MFA stage)
4. Set up proper password policies (**Policies** → **Password Policies**)
5. Configure session timeouts (**System** → **Settings**)

---

## Backup Your Configuration

After setup, export your configuration:

```bash
ssh root@10.0.10.3
pct enter 121
cd /opt/authentik
docker compose exec server ak export > /backup/authentik-$(date +%Y%m%d).json
```

Save Client IDs and Client Secrets in a password manager!
