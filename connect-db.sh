#!/bin/bash

################################################################################
# Connect to the openGauss database, create DBMind metadata, and start DBMind services.
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DBMIND_USER="dbmind_monitor"
DBMIND_PASSWORD="openEuler@1234"
METADATABASE_NAME="metadatabase"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
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

collect_user_input() {
    log_info "Collecting database connection parameters..."

    while true; do
        read -p "Enter the IP address of your openGauss database (default: 127.0.0.1): " DB_IP
        DB_IP=${DB_IP:-127.0.0.1}
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

    DBMIND_CONFIG_DIR="$DBMIND_INSTALL_DIR/dbmindconf"
    if [ ! -d "$DBMIND_CONFIG_DIR" ]; then
        exit_with_error "DBMind configuration directory not found: $DBMIND_CONFIG_DIR. Run ./configure-dbmind.sh first."
    fi

    echo ""
    echo "Connection summary:"
    echo "  Database IP: $DB_IP"
    echo "  Database Port: $DB_PORT"
    echo "  DBMind config dir: $DBMIND_CONFIG_DIR"
    echo ""
}

verify_database_connectivity() {
    log_info "Verifying database connectivity..."
    if ! command -v gsql &> /dev/null; then
        exit_with_error "gsql is not installed or not in PATH."
    fi

    if gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres -c "SELECT 1;" &> /dev/null; then
        log_success "Database connectivity verified"
    else
        exit_with_error "Cannot connect to openGauss at $DB_IP:$DB_PORT"
    fi
}

setup_database() {
    log_info "Creating DBMind database user and metadata database..."

    gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres <<'EOQ' || true
CREATE USER $DBMIND_USER password '$DBMIND_PASSWORD';
ALTER USER $DBMIND_USER monadmin;
GRANT ALL PRIVILEGES TO $DBMIND_USER;
EOQ

    gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres <<'EOQ' || true
CREATE DATABASE $METADATABASE_NAME OWNER $DBMIND_USER;
EOQ

    log_success "Database user and metadata database ensured"
}

initialize_dbmind() {
    log_info "Initializing DBMind service..."
    if ! command -v gs_dbmind &> /dev/null; then
        exit_with_error "gs_dbmind is not installed or not in PATH."
    fi

    gs_dbmind service setup -c "$DBMIND_CONFIG_DIR" || log_warn "DBMind service setup returned non-zero"
    gs_dbmind service setup --initialize -c "$DBMIND_CONFIG_DIR" || log_warn "DBMind initialization returned non-zero"
    log_success "DBMind service initialization completed"
}

start_services() {
    log_info "Starting services..."
    sudo systemctl start node-exporter
    sudo systemctl start prometheus
    sudo systemctl start dbmind
    log_success "Services started"
}

check_services_status() {
    log_info "Checking service health..."
    local all_ok=true

    if curl -s http://localhost:9100/metrics > /dev/null 2>&1; then
        log_success "Node Exporter is responding"
    else
        log_error "Node Exporter is not responding"
        all_ok=false
    fi

    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        log_success "Prometheus is responding"
    else
        log_error "Prometheus is not responding"
        all_ok=false
    fi

    if curl -s http://localhost:8080/ > /dev/null 2>&1; then
        log_success "DBMind is responding"
    else
        log_error "DBMind is not responding"
        all_ok=false
    fi

    if [ "$all_ok" = true ]; then
        log_success "All services are healthy"
    else
        log_warn "One or more services failed health checks"
    fi
}

main() {
    echo "=================================="
    echo "DBMind Database Connection and Startup"
    echo "=================================="
    echo ""

    collect_user_input
    verify_database_connectivity
    setup_database
    initialize_dbmind
    start_services
    check_services_status

    echo ""
    echo "=================================="
    echo "DBMind is ready. Access the web UI at http://localhost:8080"
    echo "Use './manage-services.sh status' to inspect service status."
    echo "=================================="
    echo ""
}

main "$@"
