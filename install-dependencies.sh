#!/bin/bash

################################################################################
# Install Prometheus and Node Exporter dependencies for DBMind.
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/software"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DBMIND_URL_X86="https://opengauss.obs.cn-south-1.myhuaweicloud.com/5.0.0/dbmind/x86/dbmind-installer-x86_64-python3.10.sh.tar.gz"
DBMIND_URL_ARM="https://opengauss.obs.cn-south-1.myhuaweicloud.com/5.0.0/dbmind/arm/dbmind-installer-aarch64-python3.10.sh.tar.gz"
PROMETHEUS_VERSION="2.51.1"
NODE_EXPORTER_VERSION="1.7.0"
PROMETHEUS_URL_X86="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
PROMETHEUS_URL_ARM="https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-arm64.tar.gz"
NODE_EXPORTER_URL_X86="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
NODE_EXPORTER_URL_ARM="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    local missing_tools=()
    for tool in wget tar; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    if [ ${#missing_tools[@]} -gt 0 ]; then
        exit_with_error "Missing required tools: ${missing_tools[*]}. Install them and rerun this script."
    fi
    log_success "All prerequisites satisfied"
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

install_prometheus() {
    log_info "Installing Prometheus..."
    if [ "$ARCH" = "x86_64" ]; then
        PROMETHEUS_URL="$PROMETHEUS_URL_X86"
        PROMETHEUS_DIR="prometheus-${PROMETHEUS_VERSION}.linux-amd64"
    else
        PROMETHEUS_URL="$PROMETHEUS_URL_ARM"
        PROMETHEUS_DIR="prometheus-${PROMETHEUS_VERSION}.linux-arm64"
    fi

    cd /tmp
    PROMETHEUS_TAR="$(basename "$PROMETHEUS_URL")"
    log_info "Downloading Prometheus from $PROMETHEUS_URL"
    if ! wget -q --show-progress -O "$PROMETHEUS_TAR" "$PROMETHEUS_URL"; then
        exit_with_error "Failed to download Prometheus"
    fi
    mkdir -p "$INSTALL_DIR"
    if ! tar -zxf "$PROMETHEUS_TAR" -C "$INSTALL_DIR"; then
        exit_with_error "Failed to extract Prometheus"
    fi
    log_success "Prometheus installed to $INSTALL_DIR/$PROMETHEUS_DIR"
}

install_node_exporter() {
    log_info "Installing Node Exporter..."
    if [ "$ARCH" = "x86_64" ]; then
        NODE_EXPORTER_URL="$NODE_EXPORTER_URL_X86"
        NODE_EXPORTER_DIR="node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"
    else
        NODE_EXPORTER_URL="$NODE_EXPORTER_URL_ARM"
        NODE_EXPORTER_DIR="node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64"
    fi

    cd /tmp
    NODE_EXPORTER_TAR="$(basename "$NODE_EXPORTER_URL")"
    log_info "Downloading Node Exporter from $NODE_EXPORTER_URL"
    if ! wget -q --show-progress -O "$NODE_EXPORTER_TAR" "$NODE_EXPORTER_URL"; then
        exit_with_error "Failed to download Node Exporter"
    fi
    mkdir -p "$INSTALL_DIR"
    if ! tar -zxf "$NODE_EXPORTER_TAR" -C "$INSTALL_DIR"; then
        exit_with_error "Failed to extract Node Exporter"
    fi
    log_success "Node Exporter installed to $INSTALL_DIR/$NODE_EXPORTER_DIR"
}

main() {
    echo "=================================="
    echo "DBMind Dependency Installer"
    echo "=================================="
    echo ""

    detect_architecture
    check_prerequisites
    install_prometheus
    install_node_exporter

    echo ""
    echo "=================================="
    echo "Dependencies installed successfully."
    echo "Next step: ./configure-dbmind.sh"
    echo "=================================="
    echo ""
}

main "$@"
