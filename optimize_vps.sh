#!/bin/bash
#
# optimize_vps.sh - Otimizacao de VPS para recon
#
# Aplica configuracoes de performance e seguranca basica.
#

set -euo pipefail

# =========================
# CORES
# =========================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =========================
# FUNCOES
# =========================
log_info() { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[-]${NC} $1" >&2; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script precisa ser executado como root"
        log_error "Use: sudo $0"
        exit 1
    fi
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backup criado: ${file}.backup.*"
    fi
}

config_exists() {
    local file="$1"
    local config="$2"
    grep -q "^${config}" "$file" 2>/dev/null
}

add_config() {
    local file="$1"
    local config="$2"
    local value="$3"

    if config_exists "$file" "$config"; then
        log_warn "Configuracao ja existe: $config"
    else
        echo "$config = $value" >> "$file"
        log_success "Adicionado: $config = $value"
    fi
}

# =========================
# OTIMIZACOES
# =========================
optimize_tcp() {
    log_info "Configurando TCP BBR..."

    local sysctl_file="/etc/sysctl.conf"
    backup_file "$sysctl_file"

    # TCP BBR
    add_config "$sysctl_file" "net.core.default_qdisc" "fq"
    add_config "$sysctl_file" "net.ipv4.tcp_congestion_control" "bbr"

    # Buffers de rede
    add_config "$sysctl_file" "net.core.rmem_max" "16777216"
    add_config "$sysctl_file" "net.core.wmem_max" "16777216"
    add_config "$sysctl_file" "net.ipv4.tcp_rmem" "4096 87380 16777216"
    add_config "$sysctl_file" "net.ipv4.tcp_wmem" "4096 65536 16777216"

    # Conexoes simultaneas
    add_config "$sysctl_file" "net.core.somaxconn" "65535"
    add_config "$sysctl_file" "net.ipv4.tcp_max_syn_backlog" "65535"

    # Aplicar configuracoes
    sysctl -p >/dev/null 2>&1 || true
    log_success "Configuracoes TCP aplicadas"
}

optimize_limits() {
    log_info "Configurando limites de arquivos..."

    local limits_file="/etc/security/limits.conf"
    backup_file "$limits_file"

    local configs=(
        "* soft nofile 65535"
        "* hard nofile 65535"
        "* soft nproc 65535"
        "* hard nproc 65535"
        "root soft nofile 65535"
        "root hard nofile 65535"
    )

    for config in "${configs[@]}"; do
        if ! grep -qF "$config" "$limits_file" 2>/dev/null; then
            echo "$config" >> "$limits_file"
            log_success "Adicionado: $config"
        fi
    done

    # Configurar systemd
    local systemd_conf="/etc/systemd/system.conf"
    if [[ -f "$systemd_conf" ]]; then
        if ! grep -q "^DefaultLimitNOFILE" "$systemd_conf"; then
            backup_file "$systemd_conf"
            echo "DefaultLimitNOFILE=65535" >> "$systemd_conf"
            log_success "Limite systemd configurado"
        fi
    fi
}

disable_unused_services() {
    log_info "Desativando servicos nao utilizados..."

    local services=(
        "apache2"
        "nginx"
        "mysql"
        "postgresql"
        "cups"
        "avahi-daemon"
        "bluetooth"
    )

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            systemctl disable --now "$service" 2>/dev/null || true
            log_success "Desativado: $service"
        fi
    done
}

setup_firewall() {
    log_info "Configurando firewall..."

    if ! command -v ufw &>/dev/null; then
        apt-get install -y ufw >/dev/null 2>&1
    fi

    # Regras basicas
    ufw --force reset >/dev/null 2>&1
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow ssh >/dev/null 2>&1

    # Portas comuns para recon (ajuste conforme necessario)
    # ufw allow 80/tcp >/dev/null 2>&1
    # ufw allow 443/tcp >/dev/null 2>&1

    ufw --force enable >/dev/null 2>&1
    log_success "Firewall configurado (SSH permitido)"
}

optimize_swap() {
    log_info "Configurando swap..."

    local swappiness
    swappiness=$(cat /proc/sys/vm/swappiness)

    if [[ "$swappiness" -gt 10 ]]; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
        sysctl vm.swappiness=10 >/dev/null 2>&1
        log_success "Swappiness reduzido para 10"
    else
        log_warn "Swappiness ja esta otimizado: $swappiness"
    fi
}

show_summary() {
    echo ""
    echo "=============================="
    echo -e "${GREEN} VPS Otimizada ${NC}"
    echo "=============================="
    echo ""
    log_info "Configuracoes aplicadas:"
    echo "  - TCP BBR ativado"
    echo "  - Limites de arquivos aumentados"
    echo "  - Servicos desnecessarios desativados"
    echo "  - Firewall basico configurado"
    echo "  - Swap otimizado"
    echo ""
    log_warn "Recomendado: Reinicie a VPS para aplicar todas as mudancas"
    echo ""
}

# =========================
# MAIN
# =========================
main() {
    echo "=============================="
    echo -e "${BLUE} VPS Optimization ${NC}"
    echo "=============================="
    echo ""

    check_root

    optimize_tcp
    optimize_limits
    disable_unused_services
    setup_firewall
    optimize_swap

    show_summary
}

main "$@"