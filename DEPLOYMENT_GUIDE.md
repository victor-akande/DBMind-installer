# DBMind One-Click Installation Guide

## Overview

This guide provides step-by-step instructions for deploying openGauss DBMind using an automated installation script. The script handles architecture detection, component download, configuration, and service management.

## Prerequisites

### System Requirements
- **Supported Architectures**: x86_64 (AMD64) or aarch64 (ARM64)
- **Linux Distribution**: Ubuntu 20.04+ or CentOS 8+
- **Disk Space**: At least 5GB free space in `/opt/software/`
- **Memory**: Minimum 4GB RAM recommended

### Required Software
Before running the installation script, ensure the following are installed:
- **openGauss Database**: Already installed and running
- **git**: For version control
- **wget**: For downloading components
- **tar**: For extracting archives

### Verification of Prerequisites

```bash
# Check if openGauss tools are available
which gsql gs_dbmind gs_guc

# Check system architecture
uname -m

# Verify disk space
df -h /opt/software/
```

## Preparation Steps

### 1. Gather Required Information

Before starting the installation, collect the following information:
- **Database IP Address**: The IP address where openGauss is running
- **Database Port**: The port openGauss listens on (default: 26000)
- **DBMind Port**: Port for the DBMind web interface (default: 8080)
- **Prometheus Port**: Port for Prometheus server (default: 9090)

### 2. Verify Database Connectivity

Test that your database is accessible:

```bash
# Replace with your actual IP and port
gsql -h 192.168.10.153 -p 26000 -U postgres -d postgres -c "SELECT 1;"
```

### 3. Prepare Configuration Files

Ensure the following files are in the same directory as the installation script:
- `install-dbmind.sh` - Main installation script
- `prometheus.yml` - Prometheus configuration template
- `dbmind.conf` - DBMind configuration template

## Installation Steps

### 1. Clone or Download the Repository

```bash
# Navigate to the installation directory
cd /path/to/DBMind-installer
```

### 2. Run the Installation Script

```bash
# Make script executable (if not already)
chmod +x install-dbmind.sh

# Run the installation script
./install-dbmind.sh
```

### 3. Interactive Configuration

The script will prompt you for the following information:

```
Enter the IP address of your openGauss database: 192.168.10.153
Enter the port number of your openGauss database (default: 26000): 26000
Enter the port number for DBMind web service (default: 8080): 8080
Enter the port number for Prometheus (default: 9090): 9090
```

### 4. Automatic Installation Process

The script will automatically:

1. **Detect System Architecture** - Determines if system is x86_64 or aarch64
2. **Check Prerequisites** - Verifies required tools are installed
3. **Verify Database** - Tests connection to openGauss
4. **Download Components**:
   - DBMind Installer
   - Prometheus Server
   - Node Exporter
5. **Install Components** - Extracts and installs all components
6. **Install Python Dependencies**:
   - Configures pip with Aliyun mirror for reliability
   - Installs requirements from architecture-specific requirements file
   - Installs additional packages (python-multipart)
   - Handles failures gracefully with retry logic
7. **Configure Database** - Creates DBMind user and metadata database
8. **Update Configurations** - Updates config files with user-provided values
9. **Create Systemd Services** - Sets up services for:
   - node-exporter
   - prometheus
   - dbmind
10. **Initialize Components** - Starts exporters and DBMind service
11. **Health Checks** - Verifies all components are running

## Service Management

After installation, manage services using systemctl:

### Check Service Status

```bash
# Check all DBMind-related services
sudo systemctl status node-exporter
sudo systemctl status prometheus
sudo systemctl status dbmind

# View all services at once
sudo systemctl status {node-exporter,prometheus,dbmind}
```

### Start/Stop Services

```bash
# Start a service
sudo systemctl start <service-name>

# Stop a service
sudo systemctl stop <service-name>

# Restart a service
sudo systemctl restart <service-name>
```

### View Service Logs

```bash
# Follow logs in real-time
sudo journalctl -u <service-name> -f

# View last 100 lines
sudo journalctl -u <service-name> -n 100

# View logs for a specific time period
sudo journalctl -u <service-name> --since "2 hours ago"
```

## Accessing Services

After successful installation, access the services at:

| Service | URL | Default Port |
|---------|-----|--------------|
| Prometheus | http://localhost:9090 | 9090 |
| DBMind Web UI | http://localhost:8080 | 8080 |
| Node Exporter | http://localhost:9100 | 9100 |
| Cmd Exporter | http://localhost:9180 | 9180 |
| OpenGauss Exporter | http://localhost:9187 | 9187 |
| Reprocessing Exporter | http://localhost:8181 | 8181 |

## Configuration Files

### Prometheus Configuration
**Location**: `/opt/software/prometheus-VERSION.linux-ARCH/prometheus.yml`

Contains scrape configurations for all exporters and services.

### DBMind Configuration
**Location**: `$HOME/openGauss-DBMind/dbmindconf/dbmind.conf`

Key sections:
- **[TSDB]**: Time-series database configuration
- **[METADATABASE]**: Metadata database configuration
- **[WORKER]**: Worker process configuration
- **[AGENT]**: Database agent configuration
- **[WEB-SERVICE]**: Web service configuration
- **[TIMED_TASK]**: Scheduled tasks configuration

## Troubleshooting

### Issue: Architecture Detection Failed

**Symptoms**: Script exits with "Unsupported architecture"

**Solution**:
```bash
# Check your system architecture
uname -m

# Only x86_64 and aarch64 are supported
```

### Issue: Database Connection Failed

**Symptoms**: "Cannot connect to database at X.X.X.X:XXXX"

**Solutions**:
1. Verify the IP address and port are correct
2. Check if openGauss is running:
   ```bash
   ps aux | grep gaussdb
   ```
3. Test connectivity manually:
   ```bash
   gsql -h <DB_IP> -p <DB_PORT> -U postgres -d postgres -c "SELECT 1;"
   ```
4. Check firewall rules allow access to the database port

### Issue: Download Failed

**Symptoms**: "Failed to download [component]"

**Solutions**:
1. Check internet connectivity:
   ```bash
   ping github.com
   ping opengauss.obs.cn-south-1.myhuaweicloud.com
   ```
2. Try downloading manually to verify URLs are accessible:
   ```bash
   wget -v <URL>
   ```
3. Check available disk space:
   ```bash
   df -h /tmp
   ```

### Issue: Service Won't Start

**Symptoms**: `systemctl start dbmind` fails

**Solutions**:
1. Check service status and logs:
   ```bash
   sudo systemctl status dbmind
   sudo journalctl -u dbmind -n 50
   ```
2. Verify DBMind was properly initialized:
   ```bash
   gs_dbmind service setup --initialize -c ~/openGauss-DBMind/dbmindconf
   ```
3. Check configuration file syntax:
   ```bash
   cat ~/openGauss-DBMind/dbmindconf/dbmind.conf
   ```

### Issue: Health Check Failed

**Symptoms**: "Installation completed but some health checks failed"

**Solutions**:
1. Wait for services to fully start (they may take 5-10 seconds):
   ```bash
   sleep 10
   ```
2. Check individual service status:
   ```bash
   curl http://localhost:9100/metrics  # Node Exporter
   curl http://localhost:9090/-/healthy  # Prometheus
   curl http://localhost:8080/  # DBMind
   ```
3. Check service logs for specific errors:
   ```bash
   sudo journalctl -u node-exporter -f
   sudo journalctl -u prometheus -f
   sudo journalctl -u dbmind -f
   ```

### Issue: Port Already in Use

**Symptoms**: Service fails to start, "Address already in use"

**Solutions**:
1. Find what process is using the port:
   ```bash
   sudo lsof -i :<port_number>
   ```
2. Either stop the conflicting service or use a different port:
   ```bash
   # When re-running script, enter a different port number
   ```
3. Modify systemd service file:
   ```bash
   sudo nano /etc/systemd/system/<service-name>.service
   # Update the port in ExecStart line
   sudo systemctl daemon-reload
   sudo systemctl restart <service-name>
   ```

## Uninstallation

To remove DBMind and related services:

```bash
# Stop all services
sudo systemctl stop node-exporter prometheus dbmind

# Disable services from auto-start
sudo systemctl disable node-exporter prometheus dbmind

# Remove systemd service files
sudo rm /etc/systemd/system/{node-exporter,prometheus,dbmind}.service

# Reload systemd
sudo systemctl daemon-reload

# Remove installation files
sudo rm -rf /opt/software/prometheus-*
sudo rm -rf /opt/software/node_exporter-*

# Remove DBMind installation (if needed)
rm -rf ~/openGauss-DBMind/

# Remove logs
rm -rf ~/openGauss-DBMind/logs/
```

## Advanced Configuration

### Modifying Service Behavior

Edit systemd service files to customize behavior:

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Common modifications:
- Change retention time: `--storage.tsdb.retention.time=7d`
- Change listen address: `--web.listen-address=0.0.0.0:9090`
- Enable query logging: Add `--query.max-concurrency=20`

After modification:
```bash
sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

### Backup Configuration

```bash
# Backup Prometheus configuration
cp /opt/software/prometheus-*/prometheus.yml ~/prometheus.yml.backup

# Backup DBMind configuration
cp ~/openGauss-DBMind/dbmindconf/dbmind.conf ~/dbmind.conf.backup
```

### Restore Configuration

```bash
# Restore Prometheus configuration
cp ~/prometheus.yml.backup /opt/software/prometheus-*/prometheus.yml
sudo systemctl restart prometheus

# Restore DBMind configuration
cp ~/dbmind.conf.backup ~/openGauss-DBMind/dbmindconf/dbmind.conf
sudo systemctl restart dbmind
```

## Performance Tuning

### For High Load Environments

1. Increase Prometheus retention time:
   ```bash
   sudo systemctl edit prometheus
   # Add: --storage.tsdb.retention.time=30d
   ```

2. Increase DBMind worker processes:
   ```bash
   nano ~/openGauss-DBMind/dbmindconf/dbmind.conf
   # Modify: process_num = 4  (increase as needed)
   ```

3. Adjust scrape intervals:
   ```bash
   nano /opt/software/prometheus-*/prometheus.yml
   # Modify: scrape_interval: 30s  (increase from 15s)
   ```

## Support and Documentation

For additional support:
- openGauss Documentation: https://opengauss.org/
- Prometheus Documentation: https://prometheus.io/docs/
- Node Exporter: https://github.com/prometheus/node_exporter
- DBMind GitHub: https://github.com/opengauss/openGauss-DBMind

## Version Information

- DBMind Version: 5.0.0
- Prometheus Version: 2.51.1
- Node Exporter Version: 1.7.0
- Python: 3.10
- OpenGauss: 5.0.0

## Changelog

### Version 1.0 (Initial Release)
- Automated architecture detection (x86_64/aarch64)
- Automatic component download and installation
- Database connectivity verification
- Systemd service management
- Comprehensive health checks
- Interactive configuration
- Detailed error reporting
