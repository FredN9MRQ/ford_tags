# Homelab Dashboard

**Simple, clean dashboard for quick access to all homelab resources when offsite.**

## Features

- 🎯 Visual organization by priority (Management, Apps, Storage)
- 🎨 Color-coded resource cards
- 📱 Mobile responsive
- ⌨️ Keyboard shortcut: Press 'h' to refresh
- 🚀 One-click launch of VS Code with Claude context

## Deployment Options

### Option 1: Docker Container (Recommended)

Deploy as a simple nginx container on your Docker host (10.0.10.29):

```bash
# Create on Docker host (10.0.10.29)
docker run -d \
  --name homelab-dashboard \
  -p 8080:80 \
  -v /path/to/homelab-dashboard:/usr/share/nginx/html:ro \
  --restart unless-stopped \
  nginx:alpine

# Access at: http://10.0.10.29:8080
```

Then add Twingate resource:
- Name: Homelab Dashboard
- IP: 10.0.10.29
- Port: 8080

### Option 2: Dockge Deployment

Use Dockge (10.0.10.27:5001) to manage the container:

1. Go to http://10.0.10.27:5001
2. Create new stack: "homelab-dashboard"
3. Use docker-compose.yml (see below)

### Option 3: Static File on Existing Web Server

Copy `index.html` to any existing web server:
- OMV web directory
- Any container with nginx/apache
- Even just open locally in browser

## Docker Compose

```yaml
version: '3.8'

services:
  dashboard:
    image: nginx:alpine
    container_name: homelab-dashboard
    ports:
      - "8080:80"
    volumes:
      - ./:/usr/share/nginx/html:ro
    restart: unless-stopped
```

## Adding New Resources

### Method 1: Edit HTML Directly (Simple)

Just edit `index.html` and add a new card:

```html
<a href="http://10.0.10.X:PORT" class="resource-card priority-2">
    <h3>Service Name</h3>
    <span class="url">http://10.0.10.X:PORT</span>
    <p class="description">What this service does</p>
</a>
```

### Method 2: JSON-Based (For Claude)

(Can be implemented if needed - let me know!)

Create `resources.json` with all resources, then generate `index.html` automatically.

## VS Code Workspace

The workspace file `homelab.code-workspace` includes:
- Infrastructure folder
- Claude shared context
- Home Assistant configs

**To use:**
1. Open the dashboard
2. Click "Launch Claude Code with Infrastructure"
3. Or manually: `code-insiders C:\Users\Fred\projects\claude-shared\homelab.code-workspace`

## Keyboard Shortcuts

- `h` - Refresh dashboard

## Current Resources

**Priority 1 - Management:**
- Proxmox Main (10.0.10.3:8006)
- Proxmox Router (10.0.10.2:8006)
- Proxmox Storage (10.0.10.4:8006)
- Grafana (10.0.10.25:3000)
- Authentik (10.0.10.21:9000)

**Priority 2 - Apps:**
- Home Assistant (10.0.10.24:8123)
- n8n (10.0.10.22:5678)

**Priority 3 - Storage:**
- OMV (10.0.10.5:80)
- Dockge (10.0.10.27:5001)

---

**Last Updated:** 2025-12-27
