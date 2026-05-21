#!/bin/bash

################################################################################
# DBMind Uninstallation Script
# Safely removes all DBMind components and services
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Confirmation prompt
confirm_action() {
    local prompt="$1"
    local response
    
    read -p "$prompt (yes/no): " response
    
    if [ "$response" = "yes" ]; then
        return 0
    else
        return 1
    fi
}

# Check if running with sudo for privileged operations
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This operation requires sudo privileges"
        exit 1
    fi
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    
    for service in dbmind prometheus node-exporter; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_info "Stopping $service..."
            systemctl stop "$service" 2>/dev/null || log_warn "Failed to stop $service"
        fi
    done
    
    sleep 2
    log_success "Services stopped"
}

# Disable services
disable_services() {
    log_info "Disabling services from auto-start..."
    
    for service in node-exporter prometheus dbmind; do
        if systemctl is-enabled "$service" 2>/dev/null; then
            systemctl disable "$service" 2>/dev/null || log_warn "Failed to disable $service"
        fi
    done
    
    log_success "Services disabled from auto-start"
}

# Remove systemd service files
remove_systemd_services() {
    log_info "Removing systemd service files..."
    
    for service in node-exporter prometheus dbmind; do
        local service_file="/etc/systemd/system/${service}.service"
        if [ -f "$service_file" ]; then
            rm "$service_file"
            log_success "Removed $service_file"
        fi
    done
    
    # Reload systemd
    systemctl daemon-reload
    log_success "Systemd daemon reloaded"
}

# Remove installed components
remove_components() {
    log_info "Removing installed components..."
    
    # Remove Prometheus
    if [ -d "/opt/software/prometheus-"* ]; then
        log_info "Removing Prometheus installation..."
        rm -rf /opt/software/prometheus-*
        log_success "Prometheus removed"
    fi
    
    # Remove Node Exporter
    if [ -d "/opt/software/node_exporter-"* ]; then
        log_info "Removing Node Exporter installation..."
        rm -rf /opt/software/node_exporter-*
        log_success "Node Exporter removed"
    fi
    
    # Clean up /opt/software if empty
    if [ -d "/opt/software" ] && [ -z "$(ls -A /opt/software 2>/dev/null)" ]; then
        rmdir /opt/software
        log_success "/opt/software directory removed (was empty)"
    fi
}

# Remove DBMind installation
remove_dbmind() {
    log_info "Removing DBMind installation..."
    
    local dbmind_dir="$HOME/openGauss-DBMind"
    
    if [ -d "$dbmind_dir" ]; then
        rm -rf "$dbmind_dir"
        log_success "DBMind installation removed"
    else
        log_warn "DBMind installation not found at $dbmind_dir"
    fi
}

# Remove DBMind user from database (optional)
remove_database_user() {
    log_info "Optionally removing DBMind database user..."
    
    if confirm_action "Remove 'dbmind_monitor' user from database?"; then
        read -p "Enter database IP address: " db_ip
        read -p "Enter database port (default: 26000): " db_port
        db_port=${db_port:-26000}
        
        log_info "Attempting to remove database user..."
        if gsql -h "$db_ip" -p "$db_port" -U postgres -d postgres << EOF 2>/dev/null
DROP USER IF EXISTS dbmind_monitor;
DROP DATABASE IF EXISTS metadatabase;
EOF
        then
            log_success "Database user and metadata database removed"
        else
            log_warn "Could not remove database user. You may need to do this manually."
        fi
    else
        log_info "Skipping database user removal"
    fi
}

# Clean up temporary files
cleanup_temp_files() {
    log_info "Cleaning up temporary files..."
    
    cd /tmp 2>/dev/null || return 0
    
    rm -f dbmind-installer*.tar.gz 2>/dev/null || true
    rm -f prometheus*.tar.gz 2>/dev/null || true
    rm -f node_exporter*.tar.gz 2>/dev/null || true
    
    log_success "Temporary files cleaned up"
}

# Show summary
show_uninstall_summary() {
    echo ""
    echo "=================================="
    log_success "Uninstallation Summary"
    echo "=================================="
    echo ""
    echo "Removed components:"
    echo "  - Systemd services (node-exporter, prometheus, dbmind)"
    echo "  - Prometheus installation"
    echo "  - Node Exporter installation"
    echo "  - DBMind installation"
    echo ""
    echo "Optionally removed:"
    echo "  - Database user (dbmind_monitor)"
    echo "  - Metadata database"
    echo ""
    echo "Manual cleanup recommendations:"
    echo "  - Check /opt/software/ for any remaining files"
    echo "  - Review systemd journal for any errors: sudo journalctl -n 100"
    echo "  - Remove any backup configuration files you created"
    echo ""
}

# Show usage
show_usage() {
    cat <<EOF
Usage: $(basename $0) [options]

Options:
  --force              Skip confirmation prompts
  --keep-db            Don't remove database user and metadata database
  --help               Show this help message

Examples:
  $(basename $0)                    # Interactive uninstallation
  $(basename $0) --force           # Automatic uninstallation without prompts
  $(basename $0) --keep-db         # Keep database user and metadata database

WARNING: This script will remove DBMind and all related components!

EOF
}

# Main execution
main() {
    echo "=================================="
    echo "DBMind Uninstallation Script"
    echo "=================================="
    echo ""
    
    local force_mode=false
    local keep_db=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_mode=true
                shift
                ;;
            --keep-db)
                keep_db=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Final confirmation
    if [ "$force_mode" = false ]; then
        echo "⚠️  WARNING: This will remove all DBMind components and services!"
        echo ""
        if ! confirm_action "Are you sure you want to proceed with uninstallation?"; then
            log_info "Uninstallation cancelled"
            exit 0
        fi
    fi
    
    # Check sudo privileges
    check_sudo
    
    # Execute uninstallation steps
    stop_services
    disable_services
    remove_systemd_services
    remove_components
    remove_dbmind
    cleanup_temp_files
    
    # Optional database cleanup
    if [ "$keep_db" = false ]; then
        remove_database_user
    fi
    
    # Show summary
    show_uninstall_summary
    
    log_success "Uninstallation completed!"
    echo ""
}

# Trap errors
trap 'log_error "Uninstallation failed"; exit 1' ERR

# Run main function
main "$@"
