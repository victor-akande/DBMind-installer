#!/bin/bash

################################################################################
# DBMind Installer
# Install only the DBMind application and prepare for dependency/configuration steps.
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DBMIND_URL_X86="https://opengauss.obs.cn-south-1.myhuaweicloud.com/5.0.0/dbmind/x86/dbmind-installer-x86_64-python3.10.sh.tar.gz"
DBMIND_URL_ARM="https://opengauss.obs.cn-south-1.myhuaweicloud.com/5.0.0/dbmind/arm/dbmind-installer-aarch64-python3.10.sh.tar.gz"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

exit_with_error() {
    log_error "$@"
    exit 1
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

check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing_tools=()

    for tool in wget tar gsql gs_dbmind gs_guc; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        exit_with_error "Missing required tools: ${missing_tools[*]}. Please install openGauss and ensure these commands are available in PATH."
    fi

    log_success "All prerequisites satisfied"
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
    log_info "Collecting DBMind installation information..."

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

    log_success "DBMind installation configuration collected"
    echo ""
    echo "Configuration Summary:"
    echo "  Database IP: $DB_IP"
    echo "  Database Port: $DB_PORT"
    echo ""
}

verify_database_connectivity() {
    log_info "Verifying database connectivity..."
    if gsql -h "$DB_IP" -p "$DB_PORT" -U postgres -d postgres -c "SELECT 1;" &> /dev/null; then
        log_success "Database connectivity verified"
    else
        exit_with_error "Cannot connect to openGauss at $DB_IP:$DB_PORT. Please verify the database is running and reachable."
    fi
}

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

install_dbmind() {
    log_info "Installing DBMind..."

    if [ "$ARCH" = "x86_64" ]; then
        DBMIND_URL="$DBMIND_URL_X86"
        DBMIND_INSTALLER="dbmind-installer-x86_64-python3.10.sh"
    else
        DBMIND_URL="$DBMIND_URL_ARM"
        DBMIND_INSTALLER="dbmind-installer-aarch64-python3.10.sh"
    fi

    cd /tmp
    DBMIND_TAR="$(basename "$DBMIND_URL")"

    download_file "$DBMIND_URL" "$DBMIND_TAR" "DBMind Installer"
    extract_tar "$DBMIND_TAR" "/tmp" "DBMind Installer"

    log_info "The DBMind installer is interactive. You will be prompted for the installation directory and confirmation."
    log_info "Recommended directory: $HOME/openGauss-DBMind"
    echo ""
    read -p "Press Enter to start the DBMind installer and enter replies manually..."

    if ! sh "$DBMIND_INSTALLER"; then
        exit_with_error "DBMind installation failed"
    fi

    log_success "DBMind installation finished"
}

main() {
    echo "=================================="
    echo "DBMind Installer"
    echo "=================================="
    echo ""

    detect_architecture
    check_prerequisites
    collect_user_input
    verify_database_connectivity
    install_dbmind

    echo ""
    echo "=================================="
    echo "DBMind installation completed. Start the next steps:"
    echo "  1) ./install-dependencies.sh"
    echo "  2) ./configure-dbmind.sh"
    echo "  3) ./connect-db.sh"
    echo "=================================="
    echo ""
}

main "$@"
