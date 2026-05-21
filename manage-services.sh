#!/bin/bash

################################################################################
# DBMind Service Management Utility
# Quick commands for managing DBMind-related services
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

# Check if running with sudo for commands that need it
check_sudo() {
    if [ "$1" != "status" ] && [ "$1" != "logs" ] && [ "$1" != "list" ]; then
        if [ "$EUID" -ne 0 ]; then
            log_error "This command requires sudo privileges"
            exit 1
        fi
    fi
}

# Status command
show_status() {
    log_info "Checking service status..."
    echo ""
    
    for service in node-exporter prometheus dbmind; do
        if sudo systemctl is-active --quiet "$service"; then
            echo -e "  ${GREEN}✓${NC} $service: $(sudo systemctl status $service | grep Active | sed 's/^[[:space:]]*//')"
        else
            echo -e "  ${RED}✗${NC} $service: Not running"
        fi
    done
}

# Logs command
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Please specify a service: node-exporter, prometheus, or dbmind"
        exit 1
    fi
    
    log_info "Showing logs for $service (Ctrl+C to exit)..."
    sudo journalctl -u "$service" -f
}

# List command
list_services() {
    log_info "Available services:"
    echo "  - node-exporter (Port 9100)"
    echo "  - prometheus (Port 9090)"
    echo "  - dbmind (Port 8080)"
}

# Start command
start_service() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Please specify a service: node-exporter, prometheus, or dbmind"
        exit 1
    fi
    
    log_info "Starting $service..."
    sudo systemctl start "$service"
    sleep 2
    
    if sudo systemctl is-active --quiet "$service"; then
        log_success "$service started successfully"
    else
        log_error "$service failed to start"
        sudo journalctl -u "$service" -n 20
        exit 1
    fi
}

# Stop command
stop_service() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Please specify a service: node-exporter, prometheus, or dbmind"
        exit 1
    fi
    
    log_info "Stopping $service..."
    sudo systemctl stop "$service"
    log_success "$service stopped"
}

# Restart command
restart_service() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Please specify a service: node-exporter, prometheus, or dbmind"
        exit 1
    fi
    
    log_info "Restarting $service..."
    sudo systemctl restart "$service"
    sleep 2
    
    if sudo systemctl is-active --quiet "$service"; then
        log_success "$service restarted successfully"
    else
        log_error "$service failed to restart"
        sudo journalctl -u "$service" -n 20
        exit 1
    fi
}

# Health check command
health_check() {
    log_info "Performing health checks..."
    echo ""
    
    local all_healthy=true
    
    # Check Node Exporter
    log_info "Checking Node Exporter..."
    if curl -s http://localhost:9100/metrics > /dev/null 2>&1; then
        log_success "Node Exporter is responding"
    else
        log_error "Node Exporter is not responding"
        all_healthy=false
    fi
    
    # Check Prometheus
    log_info "Checking Prometheus..."
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        log_success "Prometheus is responding"
    else
        log_error "Prometheus is not responding"
        all_healthy=false
    fi
    
    # Check DBMind
    log_info "Checking DBMind..."
    if curl -s http://localhost:8080/ > /dev/null 2>&1; then
        log_success "DBMind is responding"
    else
        log_error "DBMind is not responding"
        all_healthy=false
    fi
    
    echo ""
    if [ "$all_healthy" = true ]; then
        log_success "All services are healthy"
        return 0
    else
        log_error "Some services are not responding"
        return 1
    fi
}

# Show usage
show_usage() {
    cat <<EOF
Usage: $(basename $0) <command> [arguments]

Commands:
  status              Show status of all services
  start <service>     Start a specific service
  stop <service>      Stop a specific service
  restart <service>   Restart a specific service
  logs <service>      Show real-time logs for a service
  health              Run health checks on all services
  list                List available services
  help                Show this help message

Services:
  - node-exporter
  - prometheus
  - dbmind

Examples:
  $(basename $0) status
  $(basename $0) start prometheus
  $(basename $0) restart dbmind
  $(basename $0) logs node-exporter
  $(basename $0) health

EOF
}

# Main entry point
main() {
    local command=$1
    
    case "$command" in
        status)
            show_status
            ;;
        start)
            check_sudo "$command"
            start_service "$2"
            ;;
        stop)
            check_sudo "$command"
            stop_service "$2"
            ;;
        restart)
            check_sudo "$command"
            restart_service "$2"
            ;;
        logs)
            logs_service "$2"
            show_logs "$2"
            ;;
        health)
            health_check
            ;;
        list)
            list_services
            ;;
        help|"")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
