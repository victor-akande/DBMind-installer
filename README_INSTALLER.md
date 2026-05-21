# DBMind Installer - One-Click Deployment Suite

Complete, automated installation and deployment suite for openGauss DBMind monitoring and optimization platform.

## 🎯 Overview

This repository contains a comprehensive automated deployment solution for openGauss DBMind, including:

- **Automated Installation Script** - Single command deployment for all components
- **Configuration Validator** - Pre-installation validation and verification
- **Service Manager** - Easy management of all deployed services
- **Complete Documentation** - Quick start guide and detailed deployment guide
- **Architecture Detection** - Automatic x86_64/aarch64 support
- **Systemd Integration** - Professional service management
- **Health Monitoring** - Built-in health checks and verification

## ✨ Features

### 🔧 Installation Features
- ✅ Automatic architecture detection (x86_64 and aarch64)
- ✅ Automatic component download and extraction
- ✅ Database connectivity verification before installation
- ✅ Python dependency installation and configuration
- ✅ Automatic configuration file updates based on user input
- ✅ Systemd service creation and management
- ✅ Health checks and verification
- ✅ Comprehensive error handling and reporting
- ✅ Interactive user prompts for configuration

### 🎛️ Component Management
- Node Exporter (system monitoring)
- Prometheus (metrics collection)
- OpenGauss Exporter (database metrics)
- DBMind (database optimization and diagnosis)

### 📊 Monitoring & Management
- Service status monitoring
- Real-time log viewing
- Health check capabilities
- Automatic service restart
- Auto-start on system reboot

## 📋 Prerequisites

### System Requirements
- **OS**: Linux (Ubuntu 20.04+, CentOS 8+)
- **Architectures Supported**: x86_64, aarch64
- **Disk Space**: 5GB minimum in `/opt/software/`
- **Memory**: 4GB RAM recommended
- **Internet**: Required for component downloads

### Required Software
- `openGauss` database (pre-installed and running)
- `wget` (for downloads)
- `tar` (for extraction)
- `curl` (for verification)

### Check Prerequisites
```bash
# Check system architecture
uname -m

# Verify required tools
which wget tar curl

# Check openGauss tools
which gsql gs_dbmind gs_guc
```

## 🚀 Quick Start

### 1. Clone or Download

```bash
cd /path/to/DBMind-installer
```

### 2. Validate Configuration (Optional)

```bash
./validate-config.sh
```

### 3. Run Installation

```bash
./install-dbmind.sh
```

### 4. Follow Interactive Prompts

The script will ask for:
- Database IP address
- Database port (default: 26000)
- DBMind web service port (default: 8080)
- Prometheus port (default: 9090)

### 5. Wait for Completion

Installation takes approximately 5-15 minutes depending on internet speed.

## 📁 Directory Structure

```
DBMind-installer/
├── install-dbmind.sh          # Main installation script
├── manage-services.sh         # Service management utility
├── validate-config.sh         # Configuration validator
├── dbmind.conf               # DBMind configuration template
├── prometheus.yml            # Prometheus configuration template
├── README.md                 # This file
├── QUICK_START.md            # Quick start guide
└── DEPLOYMENT_GUIDE.md       # Detailed deployment guide
```

## 📖 Documentation

### For Quick Start
👉 **[QUICK_START.md](QUICK_START.md)** - 5-minute guide to get up and running

### For Detailed Setup
👉 **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment guide with troubleshooting

## 🛠️ Available Scripts

### Main Installation Script
```bash
./install-dbmind.sh [options]

Features:
- Architecture detection
- Automatic downloads
- Configuration management
- Service setup
- Health verification
```

### Service Manager
```bash
./manage-services.sh <command> [service]

Commands:
  status              - Show all service status
  start <service>     - Start a service
  stop <service>      - Stop a service
  restart <service>   - Restart a service
  logs <service>      - Show real-time logs
  health              - Run health checks
  list                - List available services
```

### Configuration Validator
```bash
./validate-config.sh [options]

Checks:
- System architecture support
- Required tools installation
- Disk space availability
- Internet connectivity
- Configuration file format
```

## 📊 Accessing Deployed Services

After successful installation:

| Service | URL | Port |
|---------|-----|------|
| Prometheus | http://localhost:9090 | 9090 |
| DBMind Web UI | http://localhost:8080 | 8080 |
| Node Exporter | http://localhost:9100 | 9100 |
| OpenGauss Exporter | http://localhost:9187 | 9187 |
| Cmd Exporter | http://localhost:9180 | 9180 |
| Reprocessing Exporter | http://localhost:8181 | 8181 |

## 🔍 Configuration Details

### Database User
- **Username**: `dbmind_monitor`
- **Password**: `openEuler@1234` (encrypted in config)

### Installed Versions
- **DBMind**: 5.0.0
- **Prometheus**: 2.51.1
- **Node Exporter**: 1.7.0
- **Python**: 3.10

## 📝 Usage Examples

### Complete Fresh Installation

```bash
# 1. Validate everything is ready
./validate-config.sh

# 2. Run installation (answer prompts with your database details)
./install-dbmind.sh

# 3. Verify installation
./manage-services.sh health

# 4. Check service status
./manage-services.sh status
```

### Managing Services

```bash
# View status of all services
./manage-services.sh status

# Start Prometheus
./manage-services.sh start prometheus

# Restart DBMind service
./manage-services.sh restart dbmind

# View DBMind logs
./manage-services.sh logs dbmind

# Run health checks
./manage-services.sh health
```

### System Administration

```bash
# Stop all services
sudo systemctl stop node-exporter prometheus dbmind

# Start all services
sudo systemctl start node-exporter prometheus dbmind

# Enable auto-start on boot
sudo systemctl enable node-exporter prometheus dbmind

# Check service files
ls -la /etc/systemd/system/{node-exporter,prometheus,dbmind}.service
```

## ⚠️ Troubleshooting

### Installation Fails
1. Run the validator: `./validate-config.sh`
2. Check internet connectivity
3. Verify database is running and accessible
4. Check logs: `tail -f /var/log/syslog`

### Service Won't Start
1. Check status: `sudo systemctl status <service-name>`
2. View logs: `sudo journalctl -u <service-name> -n 50`
3. Verify ports aren't in use: `sudo netstat -tlnp`

### Database Connection Issues
```bash
# Test connectivity
gsql -h <DB_IP> -p <DB_PORT> -U postgres -d postgres -c "SELECT 1;"

# Check if database is running
ps aux | grep gaussdb

# Check network connectivity
ping <DB_IP>
```

For more detailed troubleshooting, see [DEPLOYMENT_GUIDE.md - Troubleshooting Section](DEPLOYMENT_GUIDE.md#troubleshooting)

## 🔄 Configuration Changes

### Modify Port Numbers

```bash
# Edit the systemd service
sudo nano /etc/systemd/system/prometheus.service

# Update ports in ExecStart line, then:
sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

### Update Database Settings

```bash
# Edit DBMind configuration
nano ~/openGauss-DBMind/dbmindconf/dbmind.conf

# Restart DBMind service
sudo systemctl restart dbmind
```

## 🗑️ Uninstallation

To remove all components:

```bash
# Stop services
sudo systemctl stop node-exporter prometheus dbmind

# Disable auto-start
sudo systemctl disable node-exporter prometheus dbmind

# Remove service files
sudo rm /etc/systemd/system/{node-exporter,prometheus,dbmind}.service
sudo systemctl daemon-reload

# Remove installed files
sudo rm -rf /opt/software/prometheus-*
sudo rm -rf /opt/software/node_exporter-*
rm -rf ~/openGauss-DBMind/
```

## 📚 Additional Resources

- **openGauss Official**: https://opengauss.org/
- **Prometheus Documentation**: https://prometheus.io/docs/
- **Node Exporter**: https://github.com/prometheus/node_exporter
- **DBMind GitHub**: https://github.com/opengauss/openGauss-DBMind

## 💡 Best Practices

1. **Always validate before installation**: `./validate-config.sh`
2. **Use firewall to restrict access** to monitoring ports
3. **Backup configurations** before modifications
4. **Monitor service logs** regularly for issues
5. **Keep database credentials secure**
6. **Update components** periodically

## 🆘 Support

### Check Logs
```bash
# Application logs
sudo journalctl -u dbmind -f

# System messages
tail -f /var/log/syslog

# DBMind-specific logs
ls -la ~/openGauss-DBMind/logs/
```

### Verify Installation
```bash
# Check ports
sudo netstat -tlnp | grep -E '9090|8080|9100'

# Check processes
ps aux | grep -E 'prometheus|dbmind|node_exporter'

# Check services
sudo systemctl status {node-exporter,prometheus,dbmind}
```

## ✅ Verification Checklist

After installation, verify:

- [ ] All services are running: `./manage-services.sh status`
- [ ] Health checks pass: `./manage-services.sh health`
- [ ] Prometheus accessible: `curl http://localhost:9090`
- [ ] DBMind accessible: `curl http://localhost:8080`
- [ ] Exporters responding: `curl http://localhost:9187/metrics`
- [ ] Database connected: `gsql -h <IP> -p <PORT> -U postgres -d postgres -c "SELECT 1;"`
- [ ] Services auto-start enabled: `sudo systemctl is-enabled prometheus`

## 📌 Important Notes

1. **First Run**: Installation creates systemd services that auto-start on reboot
2. **Configuration Updates**: Config files in `/opt/software/` and `~/openGauss-DBMind/` can be edited manually
3. **Ports**: Default ports are 9090 (Prometheus), 8080 (DBMind), 9100 (Node Exporter)
4. **Database User**: Default user `dbmind_monitor` is created with encrypted password
5. **Logs**: Check systemd journal for all service logs

## 📜 License

This installation suite follows the same license as openGauss (Mulan PSL v2).

## 🤝 Contributing

Improvements and feedback are welcome! Please ensure:
- Scripts are tested on both x86_64 and aarch64
- Error messages are clear and helpful
- Changes maintain backward compatibility

---

**Ready to deploy?** Start with the [QUICK_START.md](QUICK_START.md) guide!

For detailed information, see the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).
