#!/bin/bash

################################################################################
# DBMind Configuration Validator
# Validates configuration files before installation
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
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $*"
}

# Validate IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate port number
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -gt 0 ] && [ "$port" -lt 65536 ]; then
        return 0
    else
        return 1
    fi
}

# Validate prometheus.yml file
validate_prometheus_config() {
    log_info "Validating Prometheus configuration..."
    
    local config_file="${1:-.}/prometheus.yml"
    
    if [ ! -f "$config_file" ]; then
        log_error "Prometheus configuration file not found: $config_file"
        return 1
    fi
    
    log_success "prometheus.yml file exists"
    
    # Check for required sections
    if grep -q "^global:" "$config_file"; then
        log_success "Global configuration section found"
    else
        log_error "Global configuration section not found"
        return 1
    fi
    
    if grep -q "^scrape_configs:" "$config_file"; then
        log_success "Scrape configs section found"
    else
        log_error "Scrape configs section not found"
        return 1
    fi
    
    # Check for required job names
    local required_jobs=("prometheus" "opengauss_exporter" "node_exporter" "reprocessing_exporter" "cmd_exporter")
    
    for job in "${required_jobs[@]}"; do
        if grep -q "job_name: \"$job\"" "$config_file"; then
            log_success "Job '$job' found"
        else
            log_warn "Job '$job' not found"
        fi
    done
    
    return 0
}

# Validate dbmind.conf file
validate_dbmind_config() {
    log_info "Validating DBMind configuration..."
    
    local config_file="${1:-.}/dbmind.conf"
    
    if [ ! -f "$config_file" ]; then
        log_error "DBMind configuration file not found: $config_file"
        return 1
    fi
    
    log_success "dbmind.conf file exists"
    
    # Check for required sections
    local required_sections=("TSDB" "METADATABASE" "WORKER" "AGENT" "TIMED_TASK" "WEB-SERVICE" "LOG")
    
    for section in "${required_sections[@]}"; do
        if grep -q "^\[$section\]" "$config_file"; then
            log_success "Section [$section] found"
        else
            log_error "Section [$section] not found"
            return 1
        fi
    done
    
    # Check for required TSDB parameters
    if grep -q "^name = " "$config_file"; then
        log_success "TSDB name parameter found"
    else
        log_error "TSDB name parameter not found"
        return 1
    fi
    
    if grep -q "^host = " "$config_file"; then
        log_success "TSDB host parameter found"
    else
        log_error "TSDB host parameter not found"
        return 1
    fi
    
    if grep -q "^port = " "$config_file"; then
        log_success "TSDB port parameter found"
    else
        log_error "TSDB port parameter not found"
        return 1
    fi
    
    return 0
}

# Check system prerequisites
check_prerequisites() {
    log_info "Checking system prerequisites..."
    
    local missing_tools=()
    
    for tool in wget tar curl; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is installed"
        else
            log_error "$tool is not installed"
            missing_tools+=("$tool")
        fi
    done
    
    # Check for openGauss tools (optional, may not be in PATH yet)
    for tool in gsql gs_dbmind; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is installed"
        else
            log_warn "$tool not found in PATH (will be installed by script)"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Please install missing tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Check system architecture
check_architecture() {
    log_info "Checking system architecture..."
    
    local arch=$(uname -m)
    
    case $arch in
        x86_64)
            log_success "Supported architecture: x86_64 (AMD64)"
            ;;
        aarch64)
            log_success "Supported architecture: aarch64 (ARM64)"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    return 0
}

# Check disk space
check_disk_space() {
    log_info "Checking disk space..."
    
    local required_space=5000000  # 5GB in KB
    local available_space=$(df /opt/software 2>/dev/null | tail -1 | awk '{print $4}')
    
    if [ -z "$available_space" ]; then
        # /opt/software might not exist, check /opt
        available_space=$(df /opt 2>/dev/null | tail -1 | awk '{print $4}')
    fi
    
    if [ -z "$available_space" ]; then
        # Fall back to root filesystem
        available_space=$(df / 2>/dev/null | tail -1 | awk '{print $4}')
    fi
    
    if [ "$available_space" -gt "$required_space" ]; then
        log_success "Sufficient disk space available ($(numfmt --to=iec-i --suffix=B $((available_space * 1024)) 2>/dev/null || echo $((available_space))KB))"
        return 0
    else
        log_error "Insufficient disk space (need 5GB, have $(numfmt --to=iec-i --suffix=B $((available_space * 1024)) 2>/dev/null || echo $((available_space))KB))"
        return 1
    fi
}

# Validate internet connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        log_success "GitHub is reachable"
    else
        log_warn "Cannot reach GitHub (may affect component download)"
    fi
    
    if curl -s --connect-timeout 5 https://opengauss.obs.cn-south-1.myhuaweicloud.com > /dev/null 2>&1; then
        log_success "openGauss repository is reachable"
    else
        log_warn "Cannot reach openGauss repository (may affect component download)"
    fi
}

# Display configuration summary
display_summary() {
    local prometheus_config="${1:-.}/prometheus.yml"
    local dbmind_config="${1:-.}/dbmind.conf"
    
    log_info "Configuration summary:"
    echo ""
    echo "  Configuration Files:"
    echo "    - prometheus.yml: $([ -f "$prometheus_config" ] && echo "✓ Found" || echo "✗ Not Found")"
    echo "    - dbmind.conf: $([ -f "$dbmind_config" ] && echo "✓ Found" || echo "✗ Not Found")"
    echo ""
    
    if [ -f "$dbmind_config" ]; then
        echo "  DBMind Configuration Values (from dbmind.conf):"
        echo "    - TSDB Host: $(grep "^host = " "$dbmind_config" | head -1 | awk -F'=' '{print $2}' | xargs)"
        echo "    - TSDB Port: $(grep "^port = " "$dbmind_config" | head -1 | awk -F'=' '{print $2}' | xargs)"
        echo "    - MetaDB Host: $(grep "\[METADATABASE\]" -A 2 "$dbmind_config" | grep "^host = " | awk -F'=' '{print $2}' | xargs)"
        echo "    - MetaDB Port: $(grep "\[METADATABASE\]" -A 3 "$dbmind_config" | grep "^port = " | awk -F'=' '{print $2}' | xargs)"
        echo "    - Web Service Port: $(grep "\[WEB-SERVICE\]" -A 2 "$dbmind_config" | grep "^port = " | awk -F'=' '{print $2}' | xargs)"
        echo ""
    fi
}

# Show usage
show_usage() {
    cat <<EOF
Usage: $(basename $0) [options]

Options:
  -c, --config-dir DIR    Directory containing configuration files (default: current directory)
  -p, --prometheus FILE   Path to prometheus.yml file
  -d, --dbmind FILE       Path to dbmind.conf file
  -h, --help             Show this help message

Examples:
  $(basename $0)
  $(basename $0) -c /path/to/configs
  $(basename $0) -p ./prometheus.yml -d ./dbmind.conf

EOF
}

# Main execution
main() {
    echo "=================================="
    echo "DBMind Configuration Validator"
    echo "=================================="
    echo ""
    
    local config_dir="."
    local prometheus_config=""
    local dbmind_config=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config-dir)
                config_dir="$2"
                shift 2
                ;;
            -p|--prometheus)
                prometheus_config="$2"
                shift 2
                ;;
            -d|--dbmind)
                dbmind_config="$2"
                shift 2
                ;;
            -h|--help)
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
    
    # Set default paths if not specified
    prometheus_config=${prometheus_config:-"$config_dir/prometheus.yml"}
    dbmind_config=${dbmind_config:-"$config_dir/dbmind.conf"}
    
    # Run all checks
    local all_passed=true
    
    echo "1. System Checks"
    echo "=================="
    check_architecture || all_passed=false
    echo ""
    
    check_prerequisites || all_passed=false
    echo ""
    
    check_disk_space || all_passed=false
    echo ""
    
    echo "2. Connectivity Checks"
    echo "======================"
    check_internet
    echo ""
    
    echo "3. Configuration Validation"
    echo "============================"
    validate_prometheus_config "$prometheus_config" || all_passed=false
    echo ""
    
    validate_dbmind_config "$dbmind_config" || all_passed=false
    echo ""
    
    echo "4. Configuration Summary"
    echo "========================"
    display_summary "$config_dir"
    
    if [ "$all_passed" = true ]; then
        echo ""
        log_success "All validation checks passed!"
        echo "You can now run: ./install-dbmind.sh"
        exit 0
    else
        echo ""
        log_error "Some validation checks failed!"
        echo "Please fix the issues above and run the validator again."
        exit 1
    fi
}

main "$@"
