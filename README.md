# VPSRecon

Framework de Reconhecimento Automatico para Bug Bounty e Pentest.

## Sobre o Projeto

O **VPSRecon** e uma estrutura modular projetada para automacao de tarefas de reconhecimento em seguranca ofensiva, bug bounty e pentest. Ele permite desde a enumeracao de subdominios ate varredura de portas, verificacao de servicos ativos, crawling e identificacao de vulnerabilidades.

Desenvolvido para rodar em VPS de alta performance, otimizando tempo e resultados.

## Estrutura de Diretorios

```
VPSRecon/
├── output/                  # Resultados das execucoes
│   ├── subdomains/          # Subdominios encontrados
│   ├── resolved/            # Subdominios resolvidos (DNS)
│   ├── alive/               # Hosts ativos (HTTP/HTTPS)
│   ├── ports/               # Varredura de portas
│   ├── crawl/               # Dados de crawling
│   ├── vulnerabilities/     # Relatorios de vulnerabilidades
│   └── screenshots/         # Capturas de tela dos hosts
├── config/                  # Arquivos de configuracao
│   └── webhook.json         # Webhooks (Discord, Slack, Telegram)
├── scripts/                 # Scripts e automacoes
│   └── recon.go             # Script principal em Go
├── install.sh               # Instalacao rapida (Go + ProjectDiscovery)
├── install_tools.sh         # Instalacao completa de ferramentas
├── optimize_vps.sh          # Otimizacao da VPS
└── README.md                # Documentacao do projeto
```

## Instalacao

### Pre-requisitos

- VPS com Ubuntu (recomendado 22.04 ou superior)
- Acesso root ou sudo

### Instalacao rapida

```bash
git clone https://github.com/master-crypto/VPSRECON.git
cd VPSRECON
chmod +x *.sh
./install.sh
```

### Instalacao completa (todas as ferramentas)

```bash
./install_tools.sh
```

### Otimizacao da VPS

```bash
sudo ./optimize_vps.sh
```

## Como Usar

### Executar Reconhecimento

```bash
cd scripts
go run recon.go alvo.com
```

Os resultados serao salvos automaticamente na pasta `output/`.

## Ferramentas Integradas

| Ferramenta | Descricao |
|------------|-----------|
| **Subfinder** | Enumeracao de subdominios |
| **Httpx** | Verificacao de hosts ativos |
| **Naabu** | Varredura de portas |
| **Nuclei** | Scans de vulnerabilidades |
| **Katana** | Web crawler |
| **Dnsx** | Resolucao DNS |
| **ffuf** | Fuzzing de diretorios |
| **Gowitness** | Captura de screenshots |

## Configuracao de Webhook

Edite o arquivo `config/webhook.json`:

```json
{
    "discord_webhook": "https://discord.com/api/webhooks/SEU_WEBHOOK",
    "slack_webhook": "https://hooks.slack.com/services/SEU_WEBHOOK",
    "telegram_bot_token": "BOT_TOKEN",
    "telegram_chat_id": "CHAT_ID"
}
```

## To-Do

- [ ] Integracao com APIs de ASN e Shodan
- [ ] Coleta de JS e analise de endpoints
- [ ] Identificacao de tokens e credenciais expostas
- [ ] Integracao com Burp Suite para scans automatizados
- [ ] Dashboard Web

## Contribuicoes

Contribuicoes sao bem-vindas! Sinta-se livre para abrir issues ou enviar pull requests.

## Licenca

Distribuido sob a Licenca MIT. Veja [LICENSE](LICENSE) para mais informacoes.

## Contato

LinkedIn: [Fernando Nunes Coutinho](https://www.linkedin.com/in/fernando-nunes-coutinho/)
