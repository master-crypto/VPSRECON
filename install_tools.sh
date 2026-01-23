#!/bin/bash
#
# install_tools.sh - Instalacao completa de ferramentas de recon
#
# Instala ferramentas Go, Python e repositorios para bug bounty/security research.
#

set -euo pipefail

# =========================
# CORES
# =========================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# =========================
# CONFIG
# =========================
GO_VERSION="${GO_VERSION:-1.22.4}"
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
LOG_FILE="/tmp/install_tools_$(date +%Y%m%d_%H%M%S).log"

# Contadores
INSTALLED=0
SKIPPED=0
FAILED=0

# =========================
# FUNCOES DE LOG
# =========================
log_info() { echo -e "${BLUE}[*]${NC} $1" | tee -a "$LOG_FILE"; }
log_success() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[-]${NC} $1" | tee -a "$LOG_FILE" >&2; }
log_section() { echo -e "\n${CYAN}=== $1 ===${NC}\n" | tee -a "$LOG_FILE"; }

# =========================
# FUNCOES AUXILIARES
# =========================
command_exists() {
    command -v "$1" &>/dev/null
}

install_go_tool() {
    local tool="$1"
    local name
    name=$(basename "$tool" | cut -d'@' -f1)

    if command_exists "$name"; then
        log_warn "$name ja instalado"
        ((SKIPPED++))
        return 0
    fi

    log_info "Instalando $name..."
    if go install -v "$tool" >>"$LOG_FILE" 2>&1; then
        log_success "$name instalado"
        ((INSTALLED++))
    else
        log_error "Falha: $name"
        ((FAILED++))
    fi
}

clone_repo() {
    local url="$1"
    local dest="$2"
    local name
    name=$(basename "$dest")

    if [[ -d "$dest" ]]; then
        log_warn "$name ja existe"
        ((SKIPPED++))
        return 0
    fi

    log_info "Clonando $name..."
    if git clone --depth 1 -q "$url" "$dest" >>"$LOG_FILE" 2>&1; then
        log_success "$name clonado"
        ((INSTALLED++))
    else
        log_error "Falha ao clonar: $name"
        ((FAILED++))
    fi
}

install_pip_requirements() {
    local req_file="$1"
    local name
    name=$(dirname "$req_file" | xargs basename)

    if [[ -f "$req_file" ]]; then
        log_info "Instalando dependencias de $name..."
        pip3 install -q -r "$req_file" >>"$LOG_FILE" 2>&1 || true
    fi
}

# =========================
# INSTALACAO
# =========================
install_system_packages() {
    log_section "Pacotes do Sistema"

    log_info "Atualizando repositorios..."
    sudo apt-get update -qq >>"$LOG_FILE" 2>&1

    local packages=(
        git curl wget unzip jq
        build-essential
        python3 python3-pip python3-venv
        libpcap-dev
        chromium-browser
        dnsutils
        nmap
    )

    log_info "Instalando pacotes..."
    sudo apt-get install -y -qq "${packages[@]}" >>"$LOG_FILE" 2>&1
    log_success "Pacotes do sistema instalados"
}

install_go() {
    log_section "Go Language"

    if command_exists go; then
        local current
        current=$(go version | awk '{print $3}')
        log_warn "Go ja instalado: $current"
        export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
        return 0
    fi

    log_info "Instalando Go $GO_VERSION..."

    local go_tar="go${GO_VERSION}.linux-amd64.tar.gz"
    wget -q "https://go.dev/dl/${go_tar}" -O "/tmp/${go_tar}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "/tmp/${go_tar}"
    rm -f "/tmp/${go_tar}"

    # Configurar PATH
    local shell_rc="$HOME/.bashrc"
    if ! grep -qF "/usr/local/go/bin" "$shell_rc" 2>/dev/null; then
        {
            echo ""
            echo "# Go"
            echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin'
        } >> "$shell_rc"
    fi

    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    log_success "Go $GO_VERSION instalado"
}

install_go_tools() {
    log_section "Ferramentas Go"

    # ProjectDiscovery
    local pd_tools=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/projectdiscovery/uncover/cmd/uncover@latest"
        "github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
        "github.com/projectdiscovery/notify/cmd/notify@latest"
        "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
        "github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest"
        "github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest"
        "github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
    )

    log_info "Instalando ferramentas ProjectDiscovery..."
    for tool in "${pd_tools[@]}"; do
        install_go_tool "$tool"
    done

    # TomNomNom
    local tomnomnom_tools=(
        "github.com/tomnomnom/assetfinder@latest"
        "github.com/tomnomnom/anew@latest"
        "github.com/tomnomnom/unfurl@latest"
        "github.com/tomnomnom/gf@latest"
        "github.com/tomnomnom/waybackurls@latest"
        "github.com/tomnomnom/httprobe@latest"
        "github.com/tomnomnom/meg@latest"
        "github.com/tomnomnom/qsreplace@latest"
    )

    log_info "Instalando ferramentas TomNomNom..."
    for tool in "${tomnomnom_tools[@]}"; do
        install_go_tool "$tool"
    done

    # Outras ferramentas Go
    local other_tools=(
        "github.com/ffuf/ffuf/v2@latest"
        "github.com/lc/gau/v2/cmd/gau@latest"
        "github.com/hakluke/hakrawler@latest"
        "github.com/hahwul/dalfox/v2@latest"
        "github.com/sensepost/gowitness@latest"
        "github.com/jaeles-project/gospider@latest"
        "github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest"
        "github.com/KathanP19/Gxss@latest"
        "github.com/bp0lr/gauplus@latest"
        "github.com/d3mondev/puredns/v2@latest"
    )

    log_info "Instalando outras ferramentas Go..."
    for tool in "${other_tools[@]}"; do
        install_go_tool "$tool"
    done
}

install_python_tools() {
    log_section "Ferramentas Python"

    mkdir -p "$TOOLS_DIR"

    # Repositorios Python
    local repos=(
        "https://github.com/devanshbatham/paramspider.git"
        "https://github.com/GerbenJavado/LinkFinder.git"
        "https://github.com/s0md3v/XSStrike.git"
        "https://github.com/sqlmapproject/sqlmap.git"
        "https://github.com/aboul3la/Sublist3r.git"
        "https://github.com/m4ll0k/SecretFinder.git"
        "https://github.com/commixproject/commix.git"
    )

    for repo in "${repos[@]}"; do
        local name
        name=$(basename "$repo" .git)
        clone_repo "$repo" "$TOOLS_DIR/$name"

        # Instala requirements se existir
        if [[ -f "$TOOLS_DIR/$name/requirements.txt" ]]; then
            install_pip_requirements "$TOOLS_DIR/$name/requirements.txt"
        fi
    done

    # Ferramentas pip
    log_info "Instalando ferramentas via pip..."
    pip3 install -q --user \
        arjun \
        dirsearch \
        uro \
        >>"$LOG_FILE" 2>&1 || true
}

install_wordlists() {
    log_section "Wordlists"

    local wordlists_dir="$TOOLS_DIR/wordlists"
    mkdir -p "$wordlists_dir"

    if [[ ! -d "$wordlists_dir/SecLists" ]]; then
        log_info "Clonando SecLists (pode demorar)..."
        git clone --depth 1 -q \
            https://github.com/danielmiessler/SecLists.git \
            "$wordlists_dir/SecLists" >>"$LOG_FILE" 2>&1 || true
        log_success "SecLists instalada"
    else
        log_warn "SecLists ja existe"
    fi
}

update_nuclei_templates() {
    log_section "Nuclei Templates"

    if command_exists nuclei; then
        log_info "Atualizando templates..."
        nuclei -update-templates -silent >>"$LOG_FILE" 2>&1 || true
        log_success "Templates atualizados"
    fi
}

setup_gf_patterns() {
    log_section "GF Patterns"

    local gf_dir="$HOME/.gf"
    mkdir -p "$gf_dir"

    if [[ ! -f "$gf_dir/xss.json" ]]; then
        log_info "Instalando GF patterns..."
        git clone --depth 1 -q \
            https://github.com/1ndianl33t/Gf-Patterns.git \
            /tmp/gf-patterns >>"$LOG_FILE" 2>&1 || true

        cp /tmp/gf-patterns/*.json "$gf_dir/" 2>/dev/null || true
        rm -rf /tmp/gf-patterns
        log_success "GF patterns instalados"
    else
        log_warn "GF patterns ja existem"
    fi
}

# =========================
# SUMARIO
# =========================
show_summary() {
    echo ""
    echo "=============================="
    echo -e "${GREEN} Instalacao Concluida ${NC}"
    echo "=============================="
    echo ""
    echo -e "  ${GREEN}Instalados:${NC} $INSTALLED"
    echo -e "  ${YELLOW}Pulados:${NC}    $SKIPPED"
    echo -e "  ${RED}Falhas:${NC}     $FAILED"
    echo ""
    log_info "Log completo: $LOG_FILE"
    log_info "Ferramentas em: $TOOLS_DIR"
    echo ""

    log_info "Ferramentas Go disponiveis:"
    local check_tools=(subfinder httpx nuclei naabu ffuf katana)
    for tool in "${check_tools[@]}"; do
        if command_exists "$tool"; then
            echo -e "  ${GREEN}+${NC} $tool"
        else
            echo -e "  ${RED}-${NC} $tool"
        fi
    done

    echo ""
    log_warn "Execute: source ~/.bashrc"
    echo ""
}

# =========================
# MAIN
# =========================
main() {
    echo "=============================="
    echo -e "${BLUE} VPSRecon - Full Install ${NC}"
    echo "=============================="
    echo ""
    log_info "Log: $LOG_FILE"
    echo ""

    install_system_packages
    install_go
    install_go_tools
    install_python_tools
    install_wordlists
    update_nuclei_templates
    setup_gf_patterns
    show_summary
}

main "$@"
