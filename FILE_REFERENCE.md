# DBMind Installer - Complete File Reference

This document provides a comprehensive reference for all files included in the DBMind installation suite.

## 📂 File Structure

```
DBMind-installer/
├── 📜 Installation & Deployment Documentation
│   ├── README.md                    # Original repository README
│   ├── README_INSTALLER.md          # Complete installer documentation
│   ├── QUICK_START.md               # 5-minute quick start guide
│   └── DEPLOYMENT_GUIDE.md          # Detailed deployment and troubleshooting
│
├── 🔧 Executable Scripts
│   ├── install-dbmind.sh            # Main installation script
│   ├── uninstall-dbmind.sh          # Uninstallation script
│   ├── manage-services.sh           # Service management utility
│   └── validate-config.sh           # Configuration validator
│
└── ⚙️ Configuration Templates
    ├── prometheus.yml              # Prometheus configuration
    └── dbmind.conf                 # DBMind configuration
```

## 📝 Documentation Files

### README.md
**Purpose**: Original repository documentation  
**Size**: ~0.5 KB  
**When to Read**: For original project information

### README_INSTALLER.md ⭐ START HERE
**Purpose**: Complete guide to the installation suite  
**Size**: ~10 KB  
**Contents**:
- Overview of all components
- Features and capabilities
- Directory structure
- Usage examples
- Troubleshooting guide
- Best practices

**When to Read**: 
- First reference for understanding the suite
- Before running any scripts
- When looking for overview documentation

### QUICK_START.md ⭐ FOR FIRST-TIME USERS
**Purpose**: Get up and running in 5 minutes  
**Size**: ~6.8 KB  
**Contents**:
- 30-second summary
- Step-by-step installation process
- Common tasks
- Quick reference commands
- After-installation verification

**When to Read**: 
- Before your first installation
- When you just want to get started quickly
- When you need quick reference commands

### DEPLOYMENT_GUIDE.md ⭐ COMPREHENSIVE REFERENCE
**Purpose**: Complete deployment and troubleshooting guide  
**Size**: ~11 KB  
**Contents**:
- Detailed prerequisites
- Step-by-step installation guide
- Service management instructions
- Configuration file details
- Comprehensive troubleshooting section
- Advanced configuration options
- Performance tuning tips
- Backup and restore procedures

**When to Read**:
- For detailed installation instructions
- When troubleshooting issues
- For advanced configuration
- For service management details
- For backup/restore procedures

## 🔧 Executable Scripts

### install-dbmind.sh ⭐ MAIN SCRIPT
**Purpose**: Automated installation of all DBMind components  
**Size**: ~21 KB  
**Make Executable**: Already done (`chmod +x`)

**What It Does**:
1. Detects system architecture (x86_64 or aarch64)
2. Checks prerequisites
3. Collects user input (database IP, ports)
4. Verifies database connectivity
5. Downloads components:
   - DBMind Installer
   - Prometheus
   - Node Exporter
6. Configures components
7. Updates configuration files
8. Creates systemd services
9. Initializes components
10. Starts services
11. Performs health checks

**Usage**:
```bash
./install-dbmind.sh
```

**Estimated Time**: 5-15 minutes

**Error Handling**:
- Exits on missing prerequisites
- Validates all inputs
- Verifies database connectivity
- Reports failures explicitly
- Provides recovery options

### uninstall-dbmind.sh
**Purpose**: Safely removes all DBMind components and services  
**Size**: ~7.5 KB  
**Make Executable**: Already done (`chmod +x`)

**What It Does**:
1. Stops all running services
2. Disables services from auto-start
3. Removes systemd service files
4. Removes installed components
5. Removes DBMind installation
6. Optionally removes database user
7. Cleans up temporary files
8. Provides summary

**Usage**:
```bash
# Interactive uninstallation (with prompts)
sudo ./uninstall-dbmind.sh

# Automatic uninstallation (no prompts)
sudo ./uninstall-dbmind.sh --force

# Keep database user and metadata
sudo ./uninstall-dbmind.sh --keep-db
```

**Options**:
- `--force`: Skip all confirmation prompts
- `--keep-db`: Don't remove database components
- `--help`: Show help message

### manage-services.sh
**Purpose**: Easy management of all deployed services  
**Size**: ~5.8 KB  
**Make Executable**: Already done (`chmod +x`)

**What It Does**:
- Shows status of services
- Starts/stops individual services
- Restarts services
- Shows real-time logs
- Performs health checks
- Lists available services

**Usage**:
```bash
./manage-services.sh status              # Check status
./manage-services.sh start prometheus    # Start a service
./manage-services.sh stop dbmind         # Stop a service
./manage-services.sh restart dbmind      # Restart a service
./manage-services.sh logs prometheus     # View logs
./manage-services.sh health              # Run health checks
./manage-services.sh list                # List services
```

**Services**:
- `node-exporter` (Port 9100)
- `prometheus` (Port 9090)
- `dbmind` (Port 8080)

### validate-config.sh
**Purpose**: Validate configuration before installation  
**Size**: ~11 KB  
**Make Executable**: Already done (`chmod +x`)

**What It Does**:
1. Checks system architecture support
2. Verifies required tools
3. Checks disk space (5GB minimum)
4. Validates internet connectivity
5. Verifies configuration files
6. Checks configuration sections
7. Provides validation summary

**Usage**:
```bash
./validate-config.sh                          # Validate current directory
./validate-config.sh -c /path/to/configs      # Validate specific directory
./validate-config.sh -p ./prometheus.yml      # Specify prometheus.yml
./validate-config.sh --help                   # Show help
```

**Checks Performed**:
- Architecture (x86_64/aarch64)
- Required tools (wget, tar, curl)
- Disk space availability
- Internet connectivity
- Prometheus configuration syntax
- DBMind configuration syntax
- Configuration values

## ⚙️ Configuration Templates

### prometheus.yml
**Purpose**: Prometheus server configuration template  
**Size**: ~1.6 KB  
**Format**: YAML

**Contains**:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["192.168.10.153:9090"]
  
  - job_name: "opengauss_exporter"
    static_configs:
      - targets: ["192.168.10.153:9187"]
  
  - job_name: "node_exporter"
    static_configs:
      - targets: ["192.168.10.153:9100"]
  
  - job_name: "reprocessing_exporter"
    static_configs:
      - targets: ["192.168.10.153:8181"]
  
  - job_name: "cmd_exporter"
    static_configs:
      - targets: ["192.168.10.153:9180"]
```

**Update Behavior**:
- Automatically updated by install script
- IP addresses replaced with user input
- Port numbers updated based on configuration
- Location: `/opt/software/prometheus-VERSION/prometheus.yml`

**Manual Edit**: After installation, can be edited and Prometheus restarted:
```bash
nano /opt/software/prometheus-*/prometheus.yml
sudo systemctl restart prometheus
```

### dbmind.conf
**Purpose**: DBMind server configuration template  
**Size**: ~5.9 KB  
**Format**: INI

**Main Sections**:

1. **[TSDB]** - Time Series Database (Prometheus)
   - name: prometheus
   - host: Database IP
   - port: Prometheus port
   - username/password for TSDB (usually empty)

2. **[METADATABASE]** - Metadata Database (OpenGauss)
   - dbtype: opengauss
   - host: Database IP
   - port: Database port
   - username: dbmind_monitor
   - password: Encrypted
   - database: metadatabase

3. **[WORKER]** - Worker Process Configuration
   - process_num: 2 (number of worker processes)

4. **[AGENT]** - Database Agent Configuration
   - master_url: Auto-discovery mode
   - username: dbmind_monitor
   - password: Encrypted
   - SSL options

5. **[TIMED_TASK]** - Scheduled Tasks
   - task: List of enabled tasks
   - Various task intervals (30 seconds default)

6. **[WEB-SERVICE]** - Web Service Configuration
   - host: 192.168.10.153 (bind address)
   - port: 8080 (web service port)
   - SSL options

7. **[LOG]** - Logging Configuration
   - maxbytes: 10MB per log file
   - backupcount: 1 backup file
   - level: INFO
   - log_directory: logs

**Update Behavior**:
- Automatically updated by install script
- IP addresses replaced with user input
- Port numbers updated based on configuration
- Location: `$HOME/openGauss-DBMind/dbmindconf/dbmind.conf`

**Manual Edit**: After installation, can be edited:
```bash
nano ~/openGauss-DBMind/dbmindconf/dbmind.conf
sudo systemctl restart dbmind
```

**Important Notes**:
- Passwords are encrypted after initialization
- Cannot edit plain-text passwords after setup (use `gs_dbmind` commands)
- Changes require DBMind service restart to take effect

## 📋 Quick Reference Table

| File | Type | Purpose | Executable |
|------|------|---------|-----------|
| install-dbmind.sh | Script | Main installation | ✅ Yes |
| uninstall-dbmind.sh | Script | Remove components | ✅ Yes |
| manage-services.sh | Script | Service management | ✅ Yes |
| validate-config.sh | Script | Config validation | ✅ Yes |
| prometheus.yml | Config | Prometheus settings | ❌ No |
| dbmind.conf | Config | DBMind settings | ❌ No |
| README_INSTALLER.md | Doc | Complete guide | ❌ No |
| QUICK_START.md | Doc | Quick reference | ❌ No |
| DEPLOYMENT_GUIDE.md | Doc | Detailed guide | ❌ No |

## 🚀 Getting Started Workflow

### First Time Installation

1. **Read Documentation**
   ```bash
   cat README_INSTALLER.md          # Overview
   cat QUICK_START.md               # Quick start
   ```

2. **Validate Configuration**
   ```bash
   ./validate-config.sh
   ```

3. **Run Installation**
   ```bash
   ./install-dbmind.sh
   ```

4. **Verify Installation**
   ```bash
   ./manage-services.sh status
   ./manage-services.sh health
   ```

5. **Access Services**
   - Prometheus: http://localhost:9090
   - DBMind: http://localhost:8080

### Ongoing Management

- **Check Status**: `./manage-services.sh status`
- **View Logs**: `./manage-services.sh logs <service>`
- **Restart Service**: `./manage-services.sh restart <service>`
- **Health Check**: `./manage-services.sh health`
- **Detailed Info**: See `DEPLOYMENT_GUIDE.md`

### Troubleshooting

1. **Check Logs**: `./manage-services.sh logs <service-name>`
2. **Run Health Checks**: `./manage-services.sh health`
3. **Review Guide**: `DEPLOYMENT_GUIDE.md` - Troubleshooting Section
4. **Validate Config**: `./validate-config.sh`

### Uninstallation

```bash
sudo ./uninstall-dbmind.sh
```

## 📞 Support Resources

### Documentation
- **README_INSTALLER.md** - Complete overview
- **QUICK_START.md** - Quick reference
- **DEPLOYMENT_GUIDE.md** - Detailed guide
- **This File** - File reference

### Built-in Help
```bash
./install-dbmind.sh --help
./manage-services.sh help
./validate-config.sh --help
./uninstall-dbmind.sh --help
```

### External Resources
- openGauss: https://opengauss.org/
- Prometheus: https://prometheus.io/
- GitHub: https://github.com/opengauss/openGauss-DBMind

## ✅ File Integrity Checklist

Before installation, verify:
- [ ] All `.sh` scripts are executable (`chmod +x *.sh`)
- [ ] Configuration templates (`.yml`, `.conf`) exist
- [ ] Documentation files (`.md`) are readable
- [ ] All files have correct permissions

Verify with:
```bash
ls -la *.sh          # Should show 'x' permissions
ls -la *.yml *.conf  # Should exist and be readable
ls -la *.md          # Should exist and be readable
```

---

**Start Here**: [README_INSTALLER.md](README_INSTALLER.md)  
**Quick Start**: [QUICK_START.md](QUICK_START.md)  
**Detailed Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
