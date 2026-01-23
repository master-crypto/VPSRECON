#!/bin/bash
#
# install.sh - Instalacao rapida de Go e ferramentas ProjectDiscovery
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
# CONFIG
# =========================
GO_VERSION="${GO_VERSION:-1.22.4}"
GO_ARCH="linux-amd64"

# =========================
# FUNCOES
# =========================
log_info() { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[-]${NC} $1" >&2; }

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Executando como root - ferramentas Go serao instaladas em /root/go/bin"
    fi
}

install_dependencies() {
    log_info "Instalando dependencias do sistema..."

    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        git \
        wget \
        curl \
        unzip \
        build-essential \
        jq \
        libpcap-dev \
        >/dev/null 2>&1

    log_success "Dependencias instaladas"
}

install_go() {
    log_info "Verificando instalacao do Go..."

    # Verifica se Go ja esta instalado e na versao correta
    if command -v go &>/dev/null; then
        local current_version
        current_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_warn "Go $current_version ja esta instalado"

        read -r -p "Deseja reinstalar Go $GO_VERSION? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    log_info "Instalando Go $GO_VERSION..."

    local go_tar="go${GO_VERSION}.${GO_ARCH}.tar.gz"
    local go_url="https://go.dev/dl/${go_tar}"

    cd /tmp
    wget -q "$go_url" -O "$go_tar"

    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$go_tar"
    rm -f "$go_tar"

    # Configura PATH
    local shell_rc="$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && shell_rc="$HOME/.zshrc"

    local go_path='export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin'

    if ! grep -qF "/usr/local/go/bin" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Go" >> "$shell_rc"
        echo "$go_path" >> "$shell_rc"
    fi

    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

    log_success "Go $GO_VERSION instalado"
}

install_go_tool() {
    local tool="$1"
    local name
    name=$(basename "$tool" | cut -d'@' -f1)

    if command -v "$name" &>/dev/null; then
        log_warn "$name ja instalado, pulando..."
        return 0
    fi

    log_info "Instalando $name..."
    if go install -v "$tool" 2>/dev/null; then
        log_success "$name instalado"
    else
        log_error "Falha ao instalar $name"
    fi
}

install_projectdiscovery_tools() {
    log_info "Instalando ferramentas ProjectDiscovery..."

    local tools=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "github.com/projectdiscovery/katana/cmd/katana@latest"
        "github.com/projectdiscovery/uncover/cmd/uncover@latest"
        "github.com/projectdiscovery/tldfinder/cmd/tldfinder@latest"
        "github.com/projectdiscovery/chaos-client/cmd/chaos@latest"
        "github.com/projectdiscovery/notify/cmd/notify@latest"
        "github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
    )

    for tool in "${tools[@]}"; do
        install_go_tool "$tool"
    done
}

update_nuclei_templates() {
    log_info "Atualizando templates do Nuclei..."

    if command -v nuclei &>/dev/null; then
        nuclei -update-templates -silent 2>/dev/null || true
        log_success "Templates atualizados"
    else
        log_warn "Nuclei nao encontrado, pulando atualizacao de templates"
    fi
}

show_summary() {
    echo ""
    echo "=============================="
    echo -e "${GREEN} Instalacao Concluida ${NC}"
    echo "=============================="
    echo ""

    log_info "Ferramentas instaladas em: $HOME/go/bin"
    echo ""

    log_info "Ferramentas disponiveis:"
    local tools=(subfinder httpx nuclei naabu dnsx katana)
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${GREEN}+${NC} $tool"
        else
            echo -e "  ${RED}-${NC} $tool (nao encontrado)"
        fi
    done

    echo ""
    log_warn "Execute para atualizar o PATH: source ~/.bashrc"
    echo ""
}

# =========================
# MAIN
# =========================
main() {
    echo "=============================="
    echo -e "${BLUE} VPSRecon - Quick Install ${NC}"
    echo "=============================="
    echo ""

    check_root
    install_dependencies
    install_go
    install_projectdiscovery_tools
    update_nuclei_templates
    show_summary
}

main "$@"