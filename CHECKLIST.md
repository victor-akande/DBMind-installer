# DBMind Installation - Pre-Installation Checklist

Complete this checklist before running the installation script to ensure a smooth deployment.

## ✅ System Requirements Checklist

### Hardware
- [ ] System architecture is x86_64 or aarch64
  ```bash
  uname -m  # Should show x86_64 or aarch64
  ```

- [ ] At least 5GB free disk space in /opt/software/
  ```bash
  df -h /opt/software/ | tail -1  # Or df -h / if /opt doesn't exist
  ```

- [ ] At least 4GB RAM available
  ```bash
  free -h | grep Mem
  ```

### Network
- [ ] Internet connectivity for downloading components
  ```bash
  ping github.com
  ping opengauss.obs.cn-south-1.myhuaweicloud.com
  ```

- [ ] Firewall allows outbound connections on ports 80, 443

## ✅ Software Prerequisites Checklist

### Required Tools
- [ ] wget installed
  ```bash
  which wget
  ```

- [ ] tar installed
  ```bash
  which tar
  ```

- [ ] curl installed
  ```bash
  which curl
  ```

### OpenGauss Installation
- [ ] openGauss database is installed
  ```bash
  which gsql
  ```

- [ ] gs_dbmind command available
  ```bash
  which gs_dbmind
  ```

- [ ] gs_guc command available
  ```bash
  which gs_guc
  ```

- [ ] Database is running
  ```bash
  ps aux | grep gaussdb | grep -v grep
  ```

## ✅ Database Configuration Checklist

### Database Accessibility
- [ ] Know the database IP address
  
  **My database IP**: _______________

- [ ] Know the database port
  
  **My database port**: _______________

- [ ] Can connect to database as postgres user
  ```bash
  gsql -h <DB_IP> -p <DB_PORT> -U postgres -d postgres -c "SELECT 1;"
  ```

- [ ] Database is in password encryption mode
  ```bash
  gsql -h <DB_IP> -p <DB_PORT> -U postgres -d postgres -c "SHOW password_encryption_type;"
  # Should show 1 or 2
  ```

### User Permissions
- [ ] Have sudo/root access on the system
  ```bash
  sudo whoami  # Should print 'root'
  ```

- [ ] Can run systemctl commands
  ```bash
  sudo systemctl status systemd | head -1
  ```

## ✅ Configuration Planning Checklist

Before running the installation script, decide on these values:

### Port Numbers
- [ ] **Database Port**: _____________ (default: 26000)
- [ ] **DBMind Web Port**: _____________ (default: 8080)
- [ ] **Prometheus Port**: _____________ (default: 9090)

**Note**: Ensure these ports are not already in use:
```bash
sudo netstat -tlnp | grep -E '<port_number>'
```

### Backup Planning
- [ ] Plan location to backup configurations
- [ ] Have space for backups

## ✅ Files Verification Checklist

### Repository Files
Navigate to the installation directory:
```bash
cd /path/to/DBMind-installer
```

- [ ] install-dbmind.sh exists and is executable
  ```bash
  ls -la install-dbmind.sh
  ```

- [ ] uninstall-dbmind.sh exists and is executable
  ```bash
  ls -la uninstall-dbmind.sh
  ```

- [ ] manage-services.sh exists and is executable
  ```bash
  ls -la manage-services.sh
  ```

- [ ] validate-config.sh exists and is executable
  ```bash
  ls -la validate-config.sh
  ```

- [ ] prometheus.yml exists
  ```bash
  ls -la prometheus.yml
  ```

- [ ] dbmind.conf exists
  ```bash
  ls -la dbmind.conf
  ```

- [ ] README_INSTALLER.md exists
  ```bash
  ls -la README_INSTALLER.md
  ```

- [ ] QUICK_START.md exists
  ```bash
  ls -la QUICK_START.md
  ```

- [ ] DEPLOYMENT_GUIDE.md exists
  ```bash
  ls -la DEPLOYMENT_GUIDE.md
  ```

## ✅ Pre-Installation Testing Checklist

### Database Connectivity Test
```bash
# Test your database connection with actual values
gsql -h <YOUR_DB_IP> -p <YOUR_DB_PORT> -U postgres -d postgres -c "SELECT 1;"
```

- [ ] Connection successful

### Component Download Test
```bash
# Test if you can download components (example for x86_64)
wget --spider https://github.com/prometheus/prometheus/releases/download/v2.51.1/prometheus-2.51.1.linux-amd64.tar.gz
```

- [ ] Downloads are accessible

### Architecture Verification
```bash
# Verify your system architecture
uname -m
```

- [ ] Architecture is supported (x86_64 or aarch64)

## ✅ Optional Preparations

### Documentation Review
- [ ] Read QUICK_START.md (5 minutes)
- [ ] Skim DEPLOYMENT_GUIDE.md (optional, for reference)

### Configuration Validation
- [ ] Run validation script
  ```bash
  ./validate-config.sh
  ```

- [ ] All checks pass

### Backup Current State
```bash
# Create a backup directory
mkdir -p ~/dbmind-backup-$(date +%Y%m%d)

# If databases/configs already exist, backup them
# (Only if upgrading existing installation)
```

- [ ] Backups created (if applicable)

## ✅ Pre-Installation Safety Checklist

### Security
- [ ] Running on a system where you have admin rights
- [ ] Database credentials are secure
- [ ] Network is properly configured
- [ ] Firewall rules are understood

### Backup
- [ ] Have a backup of any existing database
- [ ] Know how to restore if needed

### Documentation
- [ ] Troubleshooting guide saved: DEPLOYMENT_GUIDE.md
- [ ] Know how to reach support resources

## ✅ Final Readiness Checklist

**All required items:**
- [ ] System meets hardware requirements
- [ ] All software prerequisites installed
- [ ] Can access database with test connection
- [ ] All repository files present
- [ ] Port numbers decided
- [ ] Backup plan in place

**I am ready to proceed:** ☐ YES ☐ NO

## 🚀 Ready to Install?

If you've checked everything above, you're ready to proceed!

### Step 1: Optional - Validate Configuration
```bash
./validate-config.sh
```

### Step 2: Run Installation
```bash
./install-dbmind.sh
```

### Step 3: Follow the Prompts
- Enter database IP
- Enter database port
- Enter DBMind web port
- Enter Prometheus port

### Step 4: Monitor Installation
Installation typically takes 5-15 minutes. The script will:
- Download components
- Configure services
- Start all components
- Verify everything works

### Step 5: Verify Installation
```bash
./manage-services.sh status
./manage-services.sh health
```

## 📊 Installation Parameters Reference

When you run the installation script, have these ready:

| Parameter | Example Value | Notes |
|-----------|---------------|-------|
| Database IP | 192.168.10.153 | Must be reachable and connectable |
| Database Port | 26000 | Default openGauss port |
| DBMind Port | 8080 | Web UI access port |
| Prometheus Port | 9090 | Metrics collection port |

## ❓ Troubleshooting Before Installation

### Issue: Can't Reach Database
```bash
# Verify connectivity
ping <database_ip>

# Check if database is running
ps aux | grep gaussdb

# Try direct connection
gsql -h <database_ip> -p <database_port> -U postgres -d postgres -c "SELECT 1;"
```

### Issue: Missing Required Tools
```bash
# Install wget
sudo apt-get install wget  # Ubuntu/Debian
sudo yum install wget      # CentOS/RHEL

# Install tar (usually pre-installed)
sudo apt-get install tar

# Install curl
sudo apt-get install curl
```

### Issue: Insufficient Disk Space
```bash
# Check current disk usage
df -h

# Free up space if needed
sudo apt-get clean  # Clean package cache
```

### Issue: Network Connectivity
```bash
# Test internet connection
ping 8.8.8.8

# Test GitHub access
curl https://github.com

# Test OpenGauss repository
curl https://opengauss.obs.cn-south-1.myhuaweicloud.com
```

## 📝 Notes Section

Use this space to record your specific configuration:

```
Database IP Address: ___________________________
Database Port: ___________________________
DBMind Web Port: ___________________________
Prometheus Port: ___________________________

Installation Date/Time: ___________________________
Installed By: ___________________________
Notes: 
________________________________________________________________________
________________________________________________________________________
________________________________________________________________________
```

## ✅ Sign-Off

- [ ] All prerequisites verified
- [ ] All files in place
- [ ] Database connectivity tested
- [ ] Ready to proceed with installation

**Date**: _______________
**User**: _______________

---

**Next Step**: Run `./install-dbmind.sh`

For detailed help, see:
- Quick Start: [QUICK_START.md](QUICK_START.md)
- Full Guide: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- File Reference: [FILE_REFERENCE.md](FILE_REFERENCE.md)
