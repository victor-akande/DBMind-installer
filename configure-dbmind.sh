#!/bin/bash

################################################################################
# Configure DBMind, Prometheus, and systemd services.
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/software"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROMETHEUS_VERSION="2.51.1"
NODE_EXPORTER_VERSION="1.7.0"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

exit_with_error() {
    log_error "$@"
    exit 1
}

validate_ip() {
    local ip=$1
    [[ $ip =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]
}

validate_port() {
    local port=$1
    [[ $port =~ ^[0-9]+$ ]] && [ "$port" -gt 0 ] && [ "$port" -lt 65536 ]
}

detect_architecture() {
    log_info "Detecting system architecture..."
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            ARCH="x86_64"
            log_success "Detected x86_64 architecture"
            ;;
        aarch64)
            ARCH="aarch64"
            log_success "Detected aarch64 architecture"
            ;;
        *)
            exit_with_error "Unsupported architecture: $arch. Only x86_64 and aarch64 are supported."
            ;;
    esac
}

collect_user_input() {
    log_info "Collecting configuration values..."

    while true; do
        read -p "Enter the IP address of your openGauss database: " DB_IP
        if validate_ip "$DB_IP"; then
            break
        fi
        log_error "Invalid IP address format. Please try again."
    done

    while true; do
        read -p "Enter the port number of your openGauss database (default: 26000): " DB_PORT
        DB_PORT=${DB_PORT:-26000}
        if validate_port "$DB_PORT"; then
            break
        fi
        log_error "Invalid port number. Please enter a value between 1 and 65535."
    done

    while true; do
        read -p "Enter the DBMind installation directory (default: $HOME/openGauss-DBMind): " DBMIND_INSTALL_DIR
        DBMIND_INSTALL_DIR=${DBMIND_INSTALL_DIR:-$HOME/openGauss-DBMind}
        if [ -n "$DBMIND_INSTALL_DIR" ]; then
            break
        fi
        log_error "Installation directory cannot be empty."
    done

    while true; do
        read -p "Enter the DBMind web service port (default: 8080): " DBMIND_PORT
        DBMIND_PORT=${DBMIND_PORT:-8080}
        if validate_port "$DBMIND_PORT"; then
            break
        fi
        log_error "Invalid port number. Please enter a value between 1 and 65535."
    done

    while true; do
        read -p "Enter the Prometheus port (default: 9090): " PROMETHEUS_PORT
        PROMETHEUS_PORT=${PROMETHEUS_PORT:-9090}
        if validate_port "$PROMETHEUS_PORT"; then
            break
        fi
        log_error "Invalid port number. Please enter a value between 1 and 65535."
    done

    DBMIND_CONFIG_DIR="$DBMIND_INSTALL_DIR/dbmindconf"
    mkdir -p "$DBMIND_CONFIG_DIR"

    echo ""
    echo "Configuration summary:"
    echo "  Database IP: $DB_IP"
    echo "  Database Port: $DB_PORT"
    echo "  DBMind install dir: $DBMIND_INSTALL_DIR"
    echo "  DBMind port: $DBMIND_PORT"
    echo "  Prometheus port: $PROMETHEUS_PORT"
    echo ""
}

update_prometheus_config() {
    log_info "Updating Prometheus configuration..."
    if [ "$ARCH" = "x86_64" ]; then
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-amd64"
    else
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-arm64"
    fi

    if [ ! -d "$PROMETHEUS_DIR" ]; then
        exit_with_error "Prometheus directory not found: $PROMETHEUS_DIR. Run ./install-dependencies.sh first."
    fi

    if [ -f "$SCRIPT_DIR/prometheus.yml" ]; then
        cp "$SCRIPT_DIR/prometheus.yml" "$PROMETHEUS_DIR/prometheus.yml"
        sed -i "s/192\.168\.10\.153/$DB_IP/g" "$PROMETHEUS_DIR/prometheus.yml"
        sed -i "s/:15400/:$DB_PORT/g" "$PROMETHEUS_DIR/prometheus.yml"
        sed -i "s/:9090/:$PROMETHEUS_PORT/g" "$PROMETHEUS_DIR/prometheus.yml"
        log_success "Prometheus configuration updated"
    else
        log_warn "prometheus.yml not found in installer directory. Skipping Prometheus configuration update."
    fi
}

update_dbmind_config() {
    log_info "Updating DBMind configuration..."
    if [ -f "$SCRIPT_DIR/dbmind.conf" ]; then
        cp "$SCRIPT_DIR/dbmind.conf" "$DBMIND_CONFIG_DIR/dbmind.conf"
        sed -i "s/192\.168\.10\.153/$DB_IP/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
        sed -i "s/:15400/:$DB_PORT/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
        sed -i "s/port = 8080/port = $DBMIND_PORT/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
        sed -i "s/port = 9090/port = $PROMETHEUS_PORT/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
        log_success "DBMind configuration updated"
    else
        exit_with_error "dbmind.conf not found in installer directory"
    fi
}

create_systemd_services() {
    log_info "Creating systemd service files..."

    if [ "$ARCH" = "x86_64" ]; then
        NODE_EXPORTER_PATH="$INSTALL_DIR/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter"
        PROMETHEUS_PATH="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus"
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-amd64"
    else
        NODE_EXPORTER_PATH="$INSTALL_DIR/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64/node_exporter"
        PROMETHEUS_PATH="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-arm64/prometheus"
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-arm64"
    fi

    if [ ! -x "$NODE_EXPORTER_PATH" ]; then
        exit_with_error "Node exporter not found at $NODE_EXPORTER_PATH. Run ./install-dependencies.sh first."
    fi
    if [ ! -x "$PROMETHEUS_PATH" ]; then
        exit_with_error "Prometheus binary not found at $PROMETHEUS_PATH. Run ./install-dependencies.sh first."
    fi

    sudo tee /etc/systemd/system/node-exporter.service > /dev/null <<SERVICE
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(dirname "$NODE_EXPORTER_PATH")
ExecStart=$NODE_EXPORTER_PATH
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

    sudo tee /etc/systemd/system/prometheus.service > /dev/null <<SERVICE
[Unit]
Description=Prometheus Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROMETHEUS_DIR
ExecStart=$PROMETHEUS_PATH --web.enable-admin-api --web.enable-lifecycle --storage.tsdb.retention.time=1w
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

    DBMIND_CONFIG_DIR_ESCAPED=$(printf '%s' "$DBMIND_CONFIG_DIR" | sed 's/\//\\\//g')
    DBMIND_EXEC="$(which gs_dbmind || true)"
    if [ -z "$DBMIND_EXEC" ]; then
        exit_with_error "gs_dbmind binary not found in PATH. Ensure DBMind is installed and gs_dbmind is available."
    fi

    sudo tee /etc/systemd/system/dbmind.service > /dev/null <<SERVICE
[Unit]
Description=openGauss DBMind Service
After=network.target prometheus.service
Requires=prometheus.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$DBMIND_CONFIG_DIR
ExecStart=$DBMIND_EXEC service start -c $DBMIND_CONFIG_DIR
ExecStop=$DBMIND_EXEC service stop -c $DBMIND_CONFIG_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

    sudo systemctl daemon-reload
    log_success "Systemd services created successfully"
}

main() {
    echo "=================================="
    echo "DBMind Configuration"
    echo "=================================="
    echo ""

    detect_architecture
    collect_user_input
    update_prometheus_config
    update_dbmind_config
    create_systemd_services

    echo ""
    echo "=================================="
    echo "Configuration completed successfully."
    echo "Next step: ./connect-db.sh"
    echo "=================================="
    echo ""
}

main "$@"
