# DBMind Installer - One-Click Deployment Suite

Complete, automated installation and deployment suite for openGauss DBMind monitoring and optimization platform.

This repository contains scripts to install DBMind and its dependencies, configure the monitoring stack, and connect DBMind to an openGauss database.

## Scripts

- `install-dbmind.sh` - Install the DBMind application only.
- `install-dependencies.sh` - Download and install Prometheus and Node Exporter.
- `configure-dbmind.sh` - Configure `prometheus.yml`, `dbmind.conf`, and create systemd services.
- `connect-db.sh` - Verify database connectivity, create DBMind database objects, initialize DBMind, and start services.
- `manage-services.sh` - Manage node-exporter, prometheus, and dbmind services.
- `validate-config.sh` - Validate configuration templates.

## Usage

1. Install DBMind:

```bash
./install-dbmind.sh
```

2. Install monitoring dependencies:

```bash
./install-dependencies.sh
```

3. Configure DBMind and Prometheus:

```bash
./configure-dbmind.sh
```

4. Connect to openGauss and start services:

```bash
./connect-db.sh
```

## Directory Structure

```
DBMind-installer/
├── install-dbmind.sh          # DBMind application installer
├── install-dependencies.sh    # Prometheus and Node Exporter installer
├── configure-dbmind.sh        # DBMind and Prometheus configuration script
├── connect-db.sh              # Database connectivity and service startup
├── manage-services.sh         # Service management utility
├── validate-config.sh         # Configuration validator
├── dbmind.conf                # DBMind configuration template
├── prometheus.yml             # Prometheus configuration template
├── README.md                  # Main repository README
├── README_INSTALLER.md        # Installer-specific documentation
├── QUICK_START.md             # Quick start guide
└── DEPLOYMENT_GUIDE.md        # Detailed deployment guide
```
