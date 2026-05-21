# 🚀 START HERE - DBMind Installation Suite

Welcome to the DBMind One-Click Installation Suite! This document will guide you to the right resource based on your needs.

## ⚡ Super Quick Start (2 Minutes)

If you're experienced and just want to get started:

```bash
# Validate your setup
./validate-config.sh

# Run installation
./install-dbmind.sh

# Access services
# - Prometheus: http://localhost:9090
# - DBMind: http://localhost:8080
```

---

## 🎯 What Do You Need?

### "I'm new to this and need guidance"
👉 **Go to: [QUICK_START.md](QUICK_START.md)**
- Step-by-step setup instructions
- Common tasks explained
- Quick reference commands
- Typical installation takes 5-15 minutes

### "I need to verify my system is ready"
👉 **Go to: [CHECKLIST.md](CHECKLIST.md)**
- Pre-installation verification checklist
- All prerequisites explained
- Test commands provided
- Safety checks included

### "I want complete details before starting"
👉 **Go to: [README_INSTALLER.md](README_INSTALLER.md)**
- Complete feature overview
- All scripts explained
- Architecture and design
- Best practices and recommendations

### "I have questions about specific topics"
👉 **Go to: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
- Detailed installation steps
- Comprehensive troubleshooting (25+ solutions)
- Advanced configuration
- Service management
- Backup and restore procedures

### "I need to understand all the files"
👉 **Go to: [FILE_REFERENCE.md](FILE_REFERENCE.md)**
- What each file does
- When to use each script
- Configuration file details
- Getting started workflow

### "Something is wrong and I need help"
👉 **Go to: [DEPLOYMENT_GUIDE.md - Troubleshooting Section](DEPLOYMENT_GUIDE.md#troubleshooting)**
- 25+ common issues and solutions
- How to debug problems
- Where to check logs
- How to verify installation

---

## 📚 Document Overview

| Document | Purpose | Read Time | When |
|----------|---------|-----------|------|
| **QUICK_START.md** | Fast installation guide | 5 min | First-time users |
| **CHECKLIST.md** | Pre-installation checklist | 10 min | Before installing |
| **README_INSTALLER.md** | Complete overview | 10 min | Want full context |
| **DEPLOYMENT_GUIDE.md** | Detailed reference | 20 min | Need details or help |
| **FILE_REFERENCE.md** | File documentation | 10 min | Understanding files |

---

## 🔧 Available Scripts

### Main Installation Script
```bash
./install-dbmind.sh
```
**What it does**: Automated setup of all components  
**Time**: 5-15 minutes  
**When to use**: Initial deployment

### Service Manager
```bash
./manage-services.sh status          # Check status
./manage-services.sh start prometheus # Start service
./manage-services.sh logs dbmind     # View logs
./manage-services.sh health          # Run health check
```
**What it does**: Manage and monitor services  
**When to use**: After installation for ongoing management

### Configuration Validator
```bash
./validate-config.sh
```
**What it does**: Verify system is ready  
**When to use**: Before installation (optional but recommended)

### Uninstaller
```bash
sudo ./uninstall-dbmind.sh
```
**What it does**: Clean removal of all components  
**When to use**: Need to remove installation

---

## ✅ Installation Workflow

### Step 1: Check Prerequisites (5 minutes)

```bash
# Follow the checklist
cat CHECKLIST.md

# Or run the validator
./validate-config.sh
```

### Step 2: Prepare Your Information

You'll need:
- [ ] Database IP address (e.g., 192.168.10.153)
- [ ] Database port (default: 26000)
- [ ] Desired DBMind port (default: 8080)
- [ ] Desired Prometheus port (default: 9090)

### Step 3: Run Installation

```bash
./install-dbmind.sh
```

The script will:
1. Detect your system architecture
2. Ask for your configuration
3. Download components
4. Install and configure everything
5. Start all services
6. Verify everything works

### Step 4: Access Services

| Service | Address |
|---------|---------|
| **Prometheus** | http://localhost:9090 |
| **DBMind** | http://localhost:8080 |
| **Node Exporter** | http://localhost:9100/metrics |

### Step 5: Verify Installation

```bash
# Check service status
./manage-services.sh status

# Run health checks
./manage-services.sh health

# View service logs
./manage-services.sh logs prometheus
```

---

## 🆘 Troubleshooting Quick Links

| Problem | Solution |
|---------|----------|
| Installation fails | See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting) |
| Service won't start | Check [Service Management](DEPLOYMENT_GUIDE.md#service-management) |
| Can't connect to database | See [Database Connection Issues](DEPLOYMENT_GUIDE.md#issue-database-connection-failed) |
| Port already in use | See [Port Configuration](DEPLOYMENT_GUIDE.md#issue-port-already-in-use) |
| Want to customize setup | See [Advanced Configuration](DEPLOYMENT_GUIDE.md#advanced-configuration) |

---

## 💡 Common Questions

### Q: How long does installation take?
**A**: Usually 5-15 minutes, depending on your internet speed and system performance.

### Q: What if I want to use different ports?
**A**: Just enter different ports when the script prompts you. You can also modify them later in the systemd service files.

### Q: Can I install this on my laptop?
**A**: Yes! Just ensure your database IP is correct and you have internet access to download components.

### Q: What happens if something goes wrong during installation?
**A**: The script has comprehensive error handling. If something fails, it will tell you exactly what went wrong. You can then check the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting) or run `validate-config.sh` to diagnose the issue.

### Q: How do I uninstall if I change my mind?
**A**: Simply run `sudo ./uninstall-dbmind.sh` to remove everything cleanly.

### Q: Can I run this multiple times?
**A**: It's designed for fresh installation. To change settings later, edit the configuration files or use `systemctl` to manage services.

### Q: Is there any way to backup my configuration?
**A**: Yes! See [Backup Configuration](DEPLOYMENT_GUIDE.md#backup-configuration) in the deployment guide.

---

## 📋 Pre-Installation Checklist

Quick verification (2 minutes):

```bash
# Check if you're on a supported architecture
uname -m
# Output should be: x86_64 or aarch64

# Check if you have the required tools
which wget && echo "wget ✓" || echo "wget ✗"
which tar && echo "tar ✓" || echo "tar ✗"
which curl && echo "curl ✓" || echo "curl ✗"

# Check if database tools exist
which gsql && echo "gsql ✓" || echo "gsql ✗"
which gs_dbmind && echo "gs_dbmind ✓" || echo "gs_dbmind ✗"

# Test database connectivity (update with your IP/port)
gsql -h 192.168.10.153 -p 26000 -U postgres -d postgres -c "SELECT 1;"
```

If all show ✓, you're ready to go!

---

## 🎓 Learning Resources

### Official Documentation
- **openGauss**: https://opengauss.org/
- **Prometheus**: https://prometheus.io/docs/
- **DBMind**: https://github.com/opengauss/openGauss-DBMind

### Key Concepts

**Prometheus**: Collects and stores time-series metrics  
**Node Exporter**: Exports system metrics (CPU, memory, disk)  
**OpenGauss Exporter**: Exports database metrics  
**DBMind**: Analysis, diagnosis, and optimization engine  

---

## 🚦 Decision Tree

```
START HERE
    │
    ├─→ "I'm ready to install now"
    │   └─→ Run: ./install-dbmind.sh
    │
    ├─→ "I need to verify my system first"
    │   └─→ Read: CHECKLIST.md
    │
    ├─→ "I'm completely new and confused"
    │   └─→ Read: QUICK_START.md
    │
    ├─→ "I want to understand everything"
    │   └─→ Read: README_INSTALLER.md
    │
    ├─→ "Something went wrong"
    │   └─→ Read: DEPLOYMENT_GUIDE.md (Troubleshooting section)
    │
    ├─→ "I want to understand the files"
    │   └─→ Read: FILE_REFERENCE.md
    │
    └─→ "I need detailed instructions"
        └─→ Read: DEPLOYMENT_GUIDE.md
```

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| Read this document | 2 min |
| Run pre-checks (CHECKLIST.md) | 10 min |
| Run installation script | 5-15 min |
| Access and verify services | 2 min |
| **Total** | **20-30 min** |

---

## 🎯 Next Steps

### Right Now
1. ✅ You're reading this - Good!
2. 👉 Choose one of the options above based on your needs
3. 📖 Read the recommended document
4. 🚀 Run the installation

### After Installation
1. ✅ Verify services are running: `./manage-services.sh status`
2. 🌐 Access Prometheus: http://localhost:9090
3. 🎛️ Access DBMind: http://localhost:8080
4. 📊 Start using DBMind for monitoring

---

## 📞 Need Help?

1. **Check the relevant section in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)**
2. **Run the validator**: `./validate-config.sh`
3. **Check service status**: `./manage-services.sh status`
4. **View logs**: `./manage-services.sh logs <service-name>`
5. **Read [FILE_REFERENCE.md](FILE_REFERENCE.md)** for file details

---

## 🎉 Ready?

### Choose Your Path:

| If you want to... | Go to... |
|------------------|----------|
| Get started quickly | [QUICK_START.md](QUICK_START.md) |
| Verify your system | [CHECKLIST.md](CHECKLIST.md) |
| Understand everything | [README_INSTALLER.md](README_INSTALLER.md) |
| Get detailed help | [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) |
| Understand the files | [FILE_REFERENCE.md](FILE_REFERENCE.md) |

**Or just run**: `./install-dbmind.sh` 🚀

---

**Last Updated**: May 21, 2024  
**Version**: 1.0  
**Supported Architectures**: x86_64, aarch64
