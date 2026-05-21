# DBMind Installation - Quick Start Guide

## 30-Second Summary

Deploy openGauss DBMind with one command:

```bash
./install-dbmind.sh
```

The script will:
1. Detect your system architecture (x86_64 or aarch64)
2. Ask for database IP and port information
3. Download and install all components
4. Configure and start services automatically
5. Verify everything is working

---

## Step-by-Step Installation

### Prerequisites Checklist

Before you begin, ensure:
- [ ] openGauss database is installed and running
- [ ] You have the IP address and port of your database
- [ ] You have at least 5GB free disk space in `/opt/software/`
- [ ] You have internet connectivity (for downloading components)
- [ ] `wget`, `tar`, and `curl` are installed

### Installation Process

**1. Navigate to the installation directory:**
```bash
cd /path/to/DBMind-installer
```

**2. (Optional) Validate configuration files:**
```bash
./validate-config.sh
```

**3. Run the installation script:**
```bash
./install-dbmind.sh
```

**4. Answer the prompts:**
```
Enter the IP address of your openGauss database: 192.168.10.153
Enter the port number of your openGauss database (default: 26000): 26000
Enter the port number for DBMind web service (default: 8080): 8080
Enter the port number for Prometheus (default: 9090): 9090
```

**5. Monitor the installation** - The script will download components, configure, and start all services.

---

## After Installation

### Access Your Services

| Service | URL |
|---------|-----|
| **Prometheus** | http://localhost:9090 |
| **DBMind Web UI** | http://localhost:8080 |
| **Node Exporter** | http://localhost:9100/metrics |
| **OpenGauss Exporter** | http://localhost:9187/metrics |

### Quick Service Management

```bash
# Check status of all services
./manage-services.sh status

# Start/stop individual services
./manage-services.sh start prometheus
./manage-services.sh stop dbmind
./manage-services.sh restart node-exporter

# View live logs
./manage-services.sh logs prometheus

# Run health checks
./manage-services.sh health

# List available services
./manage-services.sh list
```

### Verify Installation

```bash
# Check if all services are running
sudo systemctl status node-exporter prometheus dbmind

# View recent logs
sudo journalctl -u dbmind -n 50

# Check ports are listening
netstat -anp | grep -E '9090|8080|9100|9187'
```

---

## Common Tasks

### Change Port Numbers

If you need to change a port after installation:

1. Edit the systemd service file:
   ```bash
   sudo nano /etc/systemd/system/<service-name>.service
   ```

2. Update the port in the `ExecStart` line

3. Reload and restart:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart <service-name>
   ```

### View Configuration Files

```bash
# Prometheus configuration
cat /opt/software/prometheus-*/prometheus.yml

# DBMind configuration
cat ~/openGauss-DBMind/dbmindconf/dbmind.conf
```

### Enable Auto-start on Boot

Services are automatically enabled for auto-start during installation. To verify:

```bash
sudo systemctl is-enabled node-exporter
sudo systemctl is-enabled prometheus
sudo systemctl is-enabled dbmind
```

---

## Troubleshooting

### Service Won't Start

```bash
# Check what's wrong
sudo systemctl status <service-name>

# View detailed logs
sudo journalctl -u <service-name> -n 100

# Common issues:
# 1. Port already in use
sudo lsof -i :<port_number>

# 2. Configuration error
cat ~/openGauss-DBMind/dbmindconf/dbmind.conf
```

### Can't Connect to Database

```bash
# Verify database is running
ps aux | grep gaussdb

# Test connection manually
gsql -h <DB_IP> -p <DB_PORT> -U postgres -d postgres -c "SELECT 1;"

# Check network connectivity
ping <DB_IP>
```

### Download Failures

```bash
# Check internet
ping github.com

# Check disk space
df -h /opt/software/

# Try manual download
wget https://github.com/prometheus/prometheus/releases/download/v2.51.1/prometheus-2.51.1.linux-amd64.tar.gz
```

For more detailed troubleshooting, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

---

## Uninstall

To remove DBMind completely:

```bash
# Stop all services
sudo systemctl stop node-exporter prometheus dbmind

# Disable auto-start
sudo systemctl disable node-exporter prometheus dbmind

# Remove service files
sudo rm /etc/systemd/system/{node-exporter,prometheus,dbmind}.service
sudo systemctl daemon-reload

# Remove installation files
sudo rm -rf /opt/software/prometheus-*
sudo rm -rf /opt/software/node_exporter-*
rm -rf ~/openGauss-DBMind/
```

---

## Configuration Reference

### Database Details Used in Installation

- **DBMind User**: `dbmind_monitor`
- **DBMind Password**: `openEuler@1234` (default)
- **Metadata Database**: `metadatabase`
- **Default Ports**:
  - Database: 26000
  - Prometheus: 9090
  - DBMind Web: 8080
  - Node Exporter: 9100
  - OpenGauss Exporter: 9187
  - Cmd Exporter: 9180
  - Reprocessing Exporter: 8181

### Component Versions

- DBMind: 5.0.0
- Prometheus: 2.51.1
- Node Exporter: 1.7.0
- Python: 3.10

---

## Getting Help

### Script Help

```bash
# Installation script
./install-dbmind.sh --help

# Manage services
./manage-services.sh help

# Validate config
./validate-config.sh --help
```

### Documentation

- [Full Deployment Guide](DEPLOYMENT_GUIDE.md)
- [openGauss Documentation](https://opengauss.org/)
- [Prometheus Documentation](https://prometheus.io/docs/)

### Need Support?

1. Check the [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed troubleshooting
2. Review service logs: `sudo journalctl -u <service-name> -n 100`
3. Verify configuration: `cat ~/openGauss-DBMind/dbmindconf/dbmind.conf`
4. Test connectivity: `gsql -h <DB_IP> -p <DB_PORT> -U postgres -d postgres -c "SELECT 1;"`

---

## Next Steps

After installation, you can:

1. **Configure Monitoring**
   - Add custom scrape targets in Prometheus configuration
   - Set up alerts and rules

2. **Explore DBMind Features**
   - Access the web UI at http://localhost:8080
   - Configure automated diagnosis and optimization tasks
   - Set up performance baselines

3. **Monitor Your Database**
   - View real-time metrics in Prometheus
   - Check database health in DBMind UI
   - Review performance recommendations

---

## Quick Reference Commands

```bash
# Check system architecture
uname -m

# Validate installation prerequisites
./validate-config.sh

# Start installation
./install-dbmind.sh

# View service status
./manage-services.sh status

# View service logs
./manage-services.sh logs <service-name>

# Restart a service
./manage-services.sh restart <service-name>

# Run health checks
./manage-services.sh health

# Access Prometheus
curl http://localhost:9090/api/v1/targets

# Access DBMind
curl http://localhost:8080/

# Check running processes
ps aux | grep -E 'prometheus|dbmind|node_exporter'

# Check listening ports
sudo netstat -tlnp | grep -E '9090|8080|9100'
```

---

**Enjoy your DBMind deployment!** 🚀
