# Fly.io Deployment Guide (FREE TIER ONLY)

This guide helps you deploy Fizzy to Fly.io **completely free** with zero charges.

## ⚠️ FREE TIER GUARANTEES

This configuration is locked to Fly.io's free tier:
- **VM**: 1 shared-cpu-1x with 256MB RAM (FREE)
- **Storage**: 1GB persistent volume (FREE - up to 3GB total)
- **Bandwidth**: 160GB/month outbound (FREE)
- **Auto-stop**: App stops when idle, starts on request (FREE)
- **No charges**: You will NEVER be billed with this configuration

## 🚀 Quick Start

### 1. First-time Setup

```bash
# Add flyctl to your PATH (add this to ~/.zshrc)
export PATH="/Users/pdrlaguna/.fly/bin:$PATH"

# Login to Fly.io
flyctl auth login

# Edit fly.toml and change the app name (line 11)
# Change 'fizzy-app' to something unique like 'your-name-fizzy'
```

### 2. Deploy

```bash
# Run the deployment script
bin/deploy-fly
```

That's it! Your app will be live at `https://your-app-name.fly.dev`

## 📊 Monitoring & Management

### Check Status
```bash
flyctl status
```

### View Logs
```bash
flyctl logs
```

### SSH into VM
```bash
flyctl ssh console
```

### Open Rails Console
```bash
flyctl ssh console
cd /rails
bin/rails console
```

### Database Console
```bash
flyctl ssh console
cd /rails
bin/rails dbconsole
```

### Verify Free Tier Settings
```bash
flyctl scale show  # Should show: shared-cpu-1x, 256MB RAM
flyctl volumes list  # Should show: 1GB volume
```

## 🔄 Updating Your App

After making code changes:

```bash
bin/deploy-fly
```

The script handles everything automatically.

## 💾 Database Backups

Your SQLite database is stored in a persistent volume. To backup:

```bash
# SSH into the VM
flyctl ssh console

# Create backup
cd /data
sqlite3 production.sqlite3 ".backup backup-$(date +%Y%m%d).db"

# Download backup to your local machine (from another terminal)
flyctl ssh sftp get /data/backup-YYYYMMDD.db ./backup.db
```

## 🐛 Troubleshooting

### App won't start
```bash
flyctl logs  # Check for errors
```

### Out of memory
The free tier has only 256MB RAM. This is intentional to stay free. The app will be slow but functional.

### Database locked errors
SQLite can have lock issues under high concurrency. For production use, consider upgrading to Postgres (costs money) or use this only for personal/demo projects.

### Cold starts
When idle, the app stops. First request after idle takes ~10-30 seconds. This is normal for free tier.

## 💰 Cost Monitoring

To ensure you're never charged:

```bash
# Check current usage
flyctl status

# Verify machine specs
flyctl scale show

# Should always show:
#   - shared-cpu-1x
#   - 256MB RAM
#   - 1 instance max
```

If you ever see different specs, run:
```bash
flyctl scale vm shared-cpu-1x --memory 256
flyctl scale count 1
```

## 🚫 What NOT to Do

To avoid charges:
- ❌ Don't scale beyond 1 instance
- ❌ Don't create volumes larger than 3GB total
- ❌ Don't use dedicated-cpu VMs
- ❌ Don't enable auto-scaling
- ❌ Don't add a separate database (Postgres/MySQL costs money)
- ❌ Don't exceed 160GB bandwidth/month

## 🎯 Limitations (Free Tier)

- **Slow performance**: 256MB RAM is minimal
- **Cold starts**: App stops when idle
- **SQLite only**: No Postgres/MySQL (they cost money)
- **Single instance**: No redundancy
- **Limited bandwidth**: 160GB/month
- **Shared CPU**: Performance varies

**This is perfect for:**
- Personal projects
- Demos
- Learning/testing
- Low-traffic apps

**This is NOT suitable for:**
- Production apps with real users
- High-traffic sites
- Apps requiring fast response times
- Mission-critical applications

## 📝 Notes

- The app auto-stops after ~5 minutes of inactivity
- First request after idle wakes the app (~10-30s delay)
- Storage is persistent across deployments
- Logs are retained for 7 days
- Free tier is subject to Fly.io's current pricing (as of Dec 2024)

## 🆘 Need Help?

- Fly.io Docs: https://fly.io/docs/
- Fly.io Community: https://community.fly.io/
- Check status: flyctl doctor

## ✅ Pre-flight Checklist

Before deploying:
- [ ] Changed app name in fly.toml (must be unique)
- [ ] Logged in: `flyctl auth login`
- [ ] config/master.key exists
- [ ] Dockerfile is present
- [ ] Committed latest code changes

Then run: `bin/deploy-fly`

---

**Remember**: This configuration is designed to NEVER charge you. Enjoy your free hosting! 🎉
