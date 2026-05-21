#!/bin/bash

################################################################################
# DBMind One-Click Installation Script
# Automated setup and deployment for openGauss DBMind tool
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/software"
DBMIND_USER="dbmind_monitor"
DBMIND_PASSWORD="openEuler@1234"
METADATABASE_NAME="metadatabase"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Component versions
DBMIND_VERSION="5.0.0"
PROMETHEUS_VERSION="2.51.1"
NODE_EXPORTER_VERSION="1.7.0"

# Download URLs templates
DBMIND_URL_X86="https://opengauss.obs.cn-south-1.myhuaweicloud.com/5.0.0/dbmind/x86/dbmind-installer-x86_64-python3.10.sh.tar.gz"
DBMIND_URL_ARM="https://opengauss.obs.cn-south-1.myhuaweicloud.com/5.0.0/dbmind/arm/dbmind-installer-aarch64-python3.10.sh.tar.gz"
PROMETHEUS_URL_X86="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
PROMETHEUS_URL_ARM="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-arm64.tar.gz"
NODE_EXPORTER_URL_X86="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
NODE_EXPORTER_URL_ARM="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz"

################################################################################
# Utility Functions
################################################################################

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

################################################################################
# Architecture Detection
################################################################################

detect_architecture() {
    log_info "Detecting system architecture..."
    local arch=$(uname -m)
    
    case $arch in
        x86_64)
            ARCH="x86_64"
            ARCH_NAME="amd64"
            log_success "Detected x86_64 architecture"
            ;;
        aarch64)
            ARCH="aarch64"
            ARCH_NAME="arm64"
            log_success "Detected aarch64 architecture"
            ;;
        *)
            exit_with_error "Unsupported architecture: $arch. Only x86_64 and aarch64 are supported."
            ;;
    esac
}

################################################################################
# Prerequisite Checks
################################################################################

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    for tool in wget tar gsql gs_dbmind gs_guc; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        exit_with_error "Missing required tools: ${missing_tools[*]}\nPlease install openGauss and required utilities."
    fi
    
    log_success "All prerequisites satisfied"
}

################################################################################
# User Input Collection
################################################################################

collect_user_input() {
    log_info "Collecting configuration details..."
    
    # Get database IP
    while true; do
        read -p "Enter the IP address of your openGauss database: " DB_IP
        if [[ $DB_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            break
        else
            log_error "Invalid IP address format. Please try again."
        fi
    done
    
    # Get database port
    while true; do
        read -p "Enter the port number of your openGauss database (default: 26000): " DB_PORT
        DB_PORT=${DB_PORT:-26000}
        if [[ $DB_PORT =~ ^[0-9]+$ ]] && [ $DB_PORT -gt 0 ] && [ $DB_PORT -lt 65536 ]; then
            break
        else
            log_error "Invalid port number. Please enter a value between 1 and 65535."
        fi
    done
    
    # Get DBMind service port
    while true; do
        read -p "Enter the port number for DBMind web service (default: 8080): " DBMIND_PORT
        DBMIND_PORT=${DBMIND_PORT:-8080}
        if [[ $DBMIND_PORT =~ ^[0-9]+$ ]] && [ $DBMIND_PORT -gt 0 ] && [ $DBMIND_PORT -lt 65536 ]; then
            break
        else
            log_error "Invalid port number. Please enter a value between 1 and 65535."
        fi
    done
    
    # Get Prometheus port
    while true; do
        read -p "Enter the port number for Prometheus (default: 9090): " PROMETHEUS_PORT
        PROMETHEUS_PORT=${PROMETHEUS_PORT:-9090}
        if [[ $PROMETHEUS_PORT =~ ^[0-9]+$ ]] && [ $PROMETHEUS_PORT -gt 0 ] && [ $PROMETHEUS_PORT -lt 65536 ]; then
            break
        else
            log_error "Invalid port number. Please enter a value between 1 and 65535."
        fi
    done
    
    log_success "Configuration collected successfully"
    echo ""
    echo "Configuration Summary:"
    echo "  Database IP: $DB_IP"
    echo "  Database Port: $DB_PORT"
    echo "  DBMind Port: $DBMIND_PORT"
    echo "  Prometheus Port: $PROMETHEUS_PORT"
    echo ""
}

################################################################################
# Database Connectivity Verification
################################################################################

verify_database_connectivity() {
    log_info "Verifying database connectivity..."
    
    # Test connection to PostgreSQL/openGauss
    if gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres -c "SELECT 1;" &> /dev/null; then
        log_success "Database connectivity verified"
    else
        exit_with_error "Cannot connect to database at $DB_IP:$DB_PORT. Please verify the IP and port are correct."
    fi
}

################################################################################
# Download and Extract Functions
################################################################################

download_file() {
    local url=$1
    local output=$2
    local description=$3
    
    log_info "Downloading $description..."
    
    if ! wget -q --show-progress -O "$output" "$url"; then
        exit_with_error "Failed to download $description from $url"
    fi
    
    log_success "$description downloaded successfully"
}

extract_tar() {
    local file=$1
    local dest=$2
    local description=$3
    
    log_info "Extracting $description..."
    
    if ! tar -zxf "$file" -C "$dest"; then
        exit_with_error "Failed to extract $description"
    fi
    
    log_success "$description extracted successfully"
}

################################################################################
# Component Installation
################################################################################

install_dbmind() {
    log_info "Installing DBMind..."
    
    # Select appropriate URL based on architecture
    if [ "$ARCH" = "x86_64" ]; then
        DBMIND_URL="$DBMIND_URL_X86"
        DBMIND_INSTALLER="dbmind-installer-x86_64-python3.10.sh"
    else
        DBMIND_URL="$DBMIND_URL_ARM"
        DBMIND_INSTALLER="dbmind-installer-aarch64-python3.10.sh"
    fi
    
    cd /tmp
    DBMIND_TAR="$(basename $DBMIND_URL)"
    
    download_file "$DBMIND_URL" "$DBMIND_TAR" "DBMind Installer"
    extract_tar "$DBMIND_TAR" "/tmp" "DBMind Installer"
    
    # Prompt for DBMind installer target directory
    while true; do
        read -p "Enter the DBMind installation directory (default: $HOME/openGauss-DBMind): " DBMIND_INSTALL_DIR
        DBMIND_INSTALL_DIR=${DBMIND_INSTALL_DIR:-$HOME/openGauss-DBMind}
        if [ -n "$DBMIND_INSTALL_DIR" ]; then
            break
        fi
        log_error "Installation directory cannot be empty. Please try again."
    done
    
    log_info "Running DBMind installer..."
    if ! printf '%s\ny\n' "$DBMIND_INSTALL_DIR" | sh "$DBMIND_INSTALLER"; then
        exit_with_error "DBMind installation failed"
    fi
    
    log_success "DBMind installed successfully"
    
    # Source bashrc to update PATH
    source ~/.bashrc
}

install_prometheus() {
    log_info "Installing Prometheus..."
    
    # Select appropriate URL based on architecture
    if [ "$ARCH" = "x86_64" ]; then
        PROMETHEUS_URL="$PROMETHEUS_URL_X86"
        PROMETHEUS_DIR="prometheus-${PROMETHEUS_VERSION}.linux-amd64"
    else
        PROMETHEUS_URL="$PROMETHEUS_URL_ARM"
        PROMETHEUS_DIR="prometheus-${PROMETHEUS_VERSION}.linux-arm64"
    fi
    
    cd /tmp
    PROMETHEUS_TAR="$(basename $PROMETHEUS_URL)"
    
    download_file "$PROMETHEUS_URL" "$PROMETHEUS_TAR" "Prometheus"
    
    mkdir -p "$INSTALL_DIR"
    extract_tar "$PROMETHEUS_TAR" "$INSTALL_DIR" "Prometheus"
    
    log_success "Prometheus installed successfully"
}

install_node_exporter() {
    log_info "Installing Node Exporter..."
    
    # Select appropriate URL based on architecture
    if [ "$ARCH" = "x86_64" ]; then
        NODE_EXPORTER_URL="$NODE_EXPORTER_URL_X86"
        NODE_EXPORTER_DIR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
    else
        NODE_EXPORTER_URL="$NODE_EXPORTER_URL_ARM"
        NODE_EXPORTER_DIR="node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64"
    fi
    
    cd /tmp
    NODE_EXPORTER_TAR="$(basename $NODE_EXPORTER_URL)"
    
    download_file "$NODE_EXPORTER_URL" "$NODE_EXPORTER_TAR" "Node Exporter"
    
    mkdir -p "$INSTALL_DIR"
    extract_tar "$NODE_EXPORTER_TAR" "$INSTALL_DIR" "Node Exporter"
    
    log_success "Node Exporter installed successfully"
}

################################################################################
# Database Configuration
################################################################################

setup_database() {
    log_info "Setting up database for DBMind..."
    
    # Create DBMind user and database
    log_info "Creating DBMind monitor user..."
    
    if ! gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres << EOF
CREATE USER $DBMIND_USER password "$DBMIND_PASSWORD";
ALTER USER $DBMIND_USER monadmin;
GRANT ALL PRIVILEGES TO $DBMIND_USER;
EOF
    then
        log_warn "DBMind user might already exist or creation failed. Continuing..."
    fi
    
    if ! gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres << EOF
CREATE DATABASE $METADATABASE_NAME OWNER $DBMIND_USER;
EOF
    then
        log_warn "Metadata database might already exist. Continuing..."
    fi
    
    log_success "Database configuration completed"
}

################################################################################
# Configuration File Updates
################################################################################

update_prometheus_config() {
    log_info "Updating Prometheus configuration..."
    
    # Select Prometheus directory based on architecture
    if [ "$ARCH" = "x86_64" ]; then
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-amd64"
    else
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-arm64"
    fi
    
    # Copy and update prometheus.yml
    if [ -f "$SCRIPT_DIR/prometheus.yml" ]; then
        cp "$SCRIPT_DIR/prometheus.yml" "$PROMETHEUS_DIR/prometheus.yml"
        
        # Update IP and ports in prometheus.yml
        sed -i "s/192\.168\.10\.153/$DB_IP/g" "$PROMETHEUS_DIR/prometheus.yml"
        sed -i "s/:15400/:$DB_PORT/g" "$PROMETHEUS_DIR/prometheus.yml"
        sed -i "s/:9090/:$PROMETHEUS_PORT/g" "$PROMETHEUS_DIR/prometheus.yml"
        
        log_success "Prometheus configuration updated"
    else
        log_warn "prometheus.yml not found in script directory. Skipping update."
    fi
}

update_dbmind_config() {
    log_info "Updating DBMind configuration..."
    
    # Find DBMind config directory
    DBMIND_CONFIG_DIR="$HOME/openGauss-DBMind/dbmindconf"
    
    if [ ! -d "$DBMIND_CONFIG_DIR" ]; then
        mkdir -p "$DBMIND_CONFIG_DIR"
    fi
    
    if [ -f "$SCRIPT_DIR/dbmind.conf" ]; then
        cp "$SCRIPT_DIR/dbmind.conf" "$DBMIND_CONFIG_DIR/dbmind.conf"
    else
        exit_with_error "dbmind.conf not found in script directory"
    fi
    
    # Update configuration values
    sed -i "s/192\.168\.10\.153/$DB_IP/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
    sed -i "s/:15400/:$DB_PORT/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
    sed -i "s/port = 8080/port = $DBMIND_PORT/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
    sed -i "s/port = 9090/port = $PROMETHEUS_PORT/g" "$DBMIND_CONFIG_DIR/dbmind.conf"
    
    log_success "DBMind configuration updated"
}

################################################################################
# Systemd Service Setup
################################################################################

create_systemd_services() {
    log_info "Creating systemd services..."
    
    # Node Exporter service
    log_info "Creating node-exporter service..."
    if [ "$ARCH" = "x86_64" ]; then
        NODE_EXPORTER_PATH="$INSTALL_DIR/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter"
    else
        NODE_EXPORTER_PATH="$INSTALL_DIR/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64/node_exporter"
    fi
    
    sudo tee /etc/systemd/system/node-exporter.service > /dev/null <<EOF
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
EOF
    
    # Prometheus service
    log_info "Creating prometheus service..."
    if [ "$ARCH" = "x86_64" ]; then
        PROMETHEUS_PATH="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus"
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-amd64"
    else
        PROMETHEUS_PATH="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-arm64/prometheus"
        PROMETHEUS_DIR="$INSTALL_DIR/prometheus-${PROMETHEUS_VERSION}.linux-arm64"
    fi
    
    sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
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
EOF
    
    # DBMind service
    log_info "Creating dbmind service..."
    DBMIND_CONFIG_DIR="$HOME/openGauss-DBMind/dbmindconf"
    
    sudo tee /etc/systemd/system/dbmind.service > /dev/null <<EOF
[Unit]
Description=openGauss DBMind Service
After=network.target prometheus.service
Requires=prometheus.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$DBMIND_CONFIG_DIR
ExecStart=$(which gs_dbmind) service start -c $DBMIND_CONFIG_DIR
ExecStop=$(which gs_dbmind) service stop -c $DBMIND_CONFIG_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd daemon
    sudo systemctl daemon-reload
    log_success "Systemd services created successfully"
}

################################################################################
# Python Dependency Installation
################################################################################

install_python_dependencies() {
    log_info "Installing Python dependencies..."
    
    # Determine requirements file based on architecture
    if [ "$ARCH" = "x86_64" ]; then
        REQUIREMENTS_FILE="$HOME/openGauss-DBMind/requirements-x86_64.txt"
    else
        REQUIREMENTS_FILE="$HOME/openGauss-DBMind/requirements-aarch64.txt"
    fi
    
    # Get Python path from DBMind installation
    PYTHON_BIN="$HOME/openGauss-DBMind/python/bin/python"
    
    if [ ! -f "$PYTHON_BIN" ]; then
        log_warn "Python executable not found at $PYTHON_BIN. Skipping dependency installation."
        return 0
    fi
    
    # Create pip configuration directory
    log_info "Configuring pip..."
    mkdir -p ~/.pip
    
    # Create pip configuration file to use Aliyun mirror (for better reliability in China)
    cat > ~/.pip/pip.conf <<'PIPCONF'
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
PIPCONF
    
    log_success "Pip configuration created"
    
    # Install Python dependencies from requirements file
    if [ ! -f "$REQUIREMENTS_FILE" ]; then
        log_warn "Requirements file not found at $REQUIREMENTS_FILE. Skipping dependency installation."
        return 0
    fi
    
    log_info "Installing dependencies from $REQUIREMENTS_FILE..."
    
    # Try installing with default settings first
    if ! "$PYTHON_BIN" -m pip install -r "$REQUIREMENTS_FILE" > /dev/null 2>&1; then
        log_warn "Initial pip install failed. Retrying with trusted host..."
        
        # Retry with trusted host specified
        if ! "$PYTHON_BIN" -m pip install -r "$REQUIREMENTS_FILE" --trusted-host mirrors.aliyun.com; then
            log_warn "Failed to install requirements from $REQUIREMENTS_FILE. Continuing anyway..."
        else
            log_success "Requirements installed successfully"
        fi
    else
        log_success "Requirements installed successfully"
    fi
    
    # Install additional required packages
    log_info "Installing additional Python packages..."
    
    # Try installing python-multipart with default settings
    if ! "$PYTHON_BIN" -m pip install python-multipart > /dev/null 2>&1; then
        log_warn "Failed to install python-multipart with default settings. Retrying with trusted host..."
        
        # Retry with trusted host specified
        if ! "$PYTHON_BIN" -m pip install python-multipart --trusted-host mirrors.aliyun.com; then
            log_warn "Failed to install python-multipart. Continuing anyway..."
        else
            log_success "python-multipart installed successfully"
        fi
    else
        log_success "python-multipart installed successfully"
    fi
    
    log_success "Python dependencies installation completed"
}

################################################################################
# Component Initialization
################################################################################

initialize_components() {
    log_info "Initializing DBMind components..."
    
    # Start cmd_exporter
    log_info "Starting cmd_exporter..."
    if ! gs_dbmind component cmd_exporter --web.listen-address 0.0.0.0 --web.listen-port 9180 --disable-https > /dev/null 2>&1 &
    then
        log_warn "cmd_exporter failed to start"
    fi
    sleep 2
    
    # Start opengauss_exporter
    log_info "Starting opengauss_exporter..."
    if ! gs_dbmind component opengauss_exporter \
        --url "postgresql://$DBMIND_USER:openEuler%401234@$DB_IP:$DB_PORT/postgres" \
        --web.listen-address 0.0.0.0 --web.listen-port 9187 --log.level info --disable-https > /dev/null 2>&1 &
    then
        log_warn "opengauss_exporter failed to start"
    fi
    sleep 2
    
    # Start reprocessing_exporter
    log_info "Starting reprocessing_exporter..."
    if ! gs_dbmind component reprocessing_exporter "$DB_IP" "$PROMETHEUS_PORT" \
        --web.listen-address 0.0.0.0 --web.listen-port 8181 --disable-https > /dev/null 2>&1 &
    then
        log_warn "reprocessing_exporter failed to start"
    fi
    sleep 2
    
    log_success "Components initialized"
}

initialize_dbmind_service() {
    log_info "Initializing DBMind service..."
    
    DBMIND_CONFIG_DIR="$HOME/openGauss-DBMind/dbmindconf"
    
    # Setup DBMind
    if ! gs_dbmind service setup -c "$DBMIND_CONFIG_DIR"; then
        exit_with_error "DBMind service setup failed"
    fi
    
    # Initialize DBMind (with --initialize flag)
    if ! gs_dbmind service setup --initialize -c "$DBMIND_CONFIG_DIR"; then
        exit_with_error "DBMind service initialization failed"
    fi
    
    log_success "DBMind service initialized"
}

################################################################################
# Service Start
################################################################################

start_services() {
    log_info "Starting services..."
    
    log_info "Starting node-exporter..."
    if ! sudo systemctl start node-exporter; then
        log_error "Failed to start node-exporter"
        return 1
    fi
    
    log_info "Starting prometheus..."
    if ! sudo systemctl start prometheus; then
        log_error "Failed to start prometheus"
        return 1
    fi
    
    # Give Prometheus time to start
    sleep 5
    
    log_info "Starting dbmind..."
    if ! sudo systemctl start dbmind; then
        log_error "Failed to start dbmind"
        return 1
    fi
    
    log_success "All services started successfully"
}

enable_services() {
    log_info "Enabling services for auto-start..."
    
    sudo systemctl enable node-exporter
    sudo systemctl enable prometheus
    sudo systemctl enable dbmind
    
    log_success "Services enabled for auto-start"
}

################################################################################
# Health Check
################################################################################

health_check() {
    log_info "Performing health checks..."
    
    local all_healthy=true
    
    # Check Node Exporter
    if curl -s http://localhost:9100/metrics > /dev/null 2>&1; then
        log_success "Node Exporter is healthy"
    else
        log_error "Node Exporter is not responding"
        all_healthy=false
    fi
    
    # Check Prometheus
    if curl -s http://localhost:$PROMETHEUS_PORT/-/healthy > /dev/null 2>&1; then
        log_success "Prometheus is healthy"
    else
        log_error "Prometheus is not responding"
        all_healthy=false
    fi
    
    # Check DBMind
    if curl -s http://localhost:$DBMIND_PORT/ > /dev/null 2>&1; then
        log_success "DBMind is healthy"
    else
        log_error "DBMind is not responding"
        all_healthy=false
    fi
    
    if [ "$all_healthy" = true ]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Main Execution Flow
################################################################################

main() {
    echo "=================================="
    echo "DBMind One-Click Installation"
    echo "=================================="
    echo ""
    
    # Detect architecture
    detect_architecture
    
    # Check prerequisites
    check_prerequisites
    
    # Collect user input
    collect_user_input
    
    # Verify database connectivity
    verify_database_connectivity
    
    # Install components
    install_dbmind
    install_prometheus
    install_node_exporter
    
    # Install Python dependencies
    install_python_dependencies
    
    # Setup database
    setup_database
    
    # Update configurations
    update_prometheus_config
    update_dbmind_config
    
    # Create systemd services
    create_systemd_services
    
    # Initialize components
    initialize_components
    initialize_dbmind_service
    
    # Start services
    start_services
    enable_services
    
    # Health check
    sleep 5
    if health_check; then
        echo ""
        echo "=================================="
        echo -e "${GREEN}Installation completed successfully!${NC}"
        echo "=================================="
        echo ""
        echo "Service Details:"
        echo "  Node Exporter: http://localhost:9100"
        echo "  Prometheus: http://localhost:$PROMETHEUS_PORT"
        echo "  DBMind Web UI: http://localhost:$DBMIND_PORT"
        echo ""
        echo "Service Management:"
        echo "  Status: sudo systemctl status {node-exporter,prometheus,dbmind}"
        echo "  Stop: sudo systemctl stop {node-exporter,prometheus,dbmind}"
        echo "  Start: sudo systemctl start {node-exporter,prometheus,dbmind}"
        echo "  Restart: sudo systemctl restart {node-exporter,prometheus,dbmind}"
        echo ""
    else
        log_error "Installation completed but some health checks failed. Please review the logs."
        exit 1
    fi
}

# Run main function
main "$@"
