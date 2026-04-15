#!/usr/bin/env bash
# ============================================================
#
#   CHECKERCREDS — Automated Default Credentials Checker
#
#   Ferramenta:  Checkercreds
#   Autor:       Renzi
#   Versão:      1.1
#
#   Descrição:
#     Verifica credenciais padrão (default) em múltiplos hosts
#     via protocolo SSH, Telnet e RDP utilizando o Hydra.
#     Indicada para auditorias de segurança em ambientes
#     próprios ou com autorização expressa.
#
#   Uso:
#     ./checkercreds.sh -i <arquivo_hosts> [opções]
#
#   Opções:
#     -i <arquivo>   Arquivo com hosts alvo (um por linha) [obrigatório]
#     -o <dir>       Diretório de saída dos resultados
#     -t <n>         Tasks paralelas do hydra (padrão: 4)
#     -S             Pular verificação SSH
#     -T             Pular verificação Telnet
#     -R             Pular verificação RDP
#     -h             Exibe esta ajuda
#
#   Exemplos:
#     ./checkercreds.sh -i hosts.txt
#     ./checkercreds.sh -i hosts.txt -o /tmp/resultado -t 8
#     ./checkercreds.sh -i hosts.txt -S -T   # somente RDP
#
#   Dependências:
#     hydra  (apt install hydra)
#
#   ⚠  USE SOMENTE EM SISTEMAS PRÓPRIOS OU COM AUTORIZAÇÃO  ⚠
#
# ============================================================
set -euo pipefail

RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

HOSTS_FILE=""
OUTPUT_DIR=""
TASKS=4
SKIP_SSH=false
SKIP_TELNET=false
SKIP_RDP=false
START_TS=$(date +%Y%m%d_%H%M%S)

# ── Centraliza uma string no terminal ────────────────────────────────────────
center_text() {
  local text="$1"
  local color="${2:-}"
  # Largura do terminal (fallback 100)
  local cols
  cols=$(tput cols 2>/dev/null || echo 100)
  # Comprimento real do texto (sem escapes ANSI)
  local visible
  visible=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
  local len=${#visible}
  local pad=$(( (cols - len) / 2 ))
  [[ $pad -lt 0 ]] && pad=0
  printf "%${pad}s" ""
  echo -e "${color}${text}${RESET}"
}

banner() {
  local cols
  cols=$(tput cols 2>/dev/null || echo 100)

  # Largura do ASCII art: 100 chars
  local art_width=100
  local pad=$(( (cols - art_width) / 2 ))
  [[ $pad -lt 0 ]] && pad=0
  local indent
  indent=$(printf "%${pad}s" "")

  echo -e "${CYAN}${BOLD}"
  echo "${indent} ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗  ██████╗██████╗ ███████╗██████╗ ███████╗"
  echo "${indent}██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝"
  echo "${indent}██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝██║     ██████╔╝█████╗  ██║  ██║███████╗"
  echo "${indent}██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗██║     ██╔══██╗██╔══╝  ██║  ██║╚════██║"
  echo "${indent}╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║╚██████╗██║  ██║███████╗██████╔╝███████║"
  echo "${indent} ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝"
  echo -e "${RESET}"
  center_text "Default Credentials Checker — Hydra" "${BLUE}"
  center_text "Author: Renzi  |  Use somente em sistemas próprios ou com autorização" "${YELLOW}"
  center_text "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "${CYAN}"
  echo ""
}

usage() {
  banner
  echo -e "  ${BOLD}Uso:${RESET} ./checkercreds.sh ${CYAN}-i${RESET} <arquivo> [opções]"
  echo ""
  echo -e "  ${CYAN}-i${RESET} <arquivo>   Hosts alvo (um por linha)  ${BOLD}(obrigatório)${RESET}"
  echo -e "  ${CYAN}-o${RESET} <dir>       Diretório de saída"
  echo -e "  ${CYAN}-t${RESET} <n>         Tasks paralelas hydra (padrão: 4)"
  echo -e "  ${CYAN}-S${RESET}             Pular SSH"
  echo -e "  ${CYAN}-T${RESET}             Pular Telnet"
  echo -e "  ${CYAN}-R${RESET}             Pular RDP"
  echo -e "  ${CYAN}-h${RESET}             Exibe esta ajuda"
  echo ""
  echo -e "  ${BOLD}Exemplos:${RESET}"
  echo -e "    ./checkercreds.sh ${CYAN}-i${RESET} hosts.txt"
  echo -e "    ./checkercreds.sh ${CYAN}-i${RESET} hosts.txt ${CYAN}-o${RESET} /tmp/resultado ${CYAN}-t${RESET} 8"
  echo -e "    ./checkercreds.sh ${CYAN}-i${RESET} hosts.txt ${CYAN}-S -T${RESET}   # somente RDP"
  echo ""
  exit 0
}

info()     { echo -e "${GREEN}[+]${RESET} $(date '+%H:%M:%S') $*"; }
warn()     { echo -e "${YELLOW}[!]${RESET} $(date '+%H:%M:%S') $*"; }
error()    { echo -e "${RED}[-]${RESET} $(date '+%H:%M:%S') $*" >&2; }
step()     { echo -e "\n${BLUE}${BOLD}┌─[ $* ]${RESET}\n"; }
done_step(){ echo -e "${GREEN}${BOLD}└─[ DONE ]${RESET} $*\n"; }
die()      { error "$*"; exit 1; }

count_lines() { [[ -f "$1" ]] && wc -l < "$1" | tr -d '[:space:]' || echo 0; }

# Conta linhas com "login:" — trata exit 1 do grep quando não há match
count_hits() {
  if [[ -f "$1" ]]; then
    local n
    n=$(grep -c "login:" "$1" 2>/dev/null) || n=0
    # Remove caracteres não numéricos (whitespace residual, etc.)
    echo "${n//[^0-9]/}"
  else
    echo "0"
  fi
}

show_hits() {
  [[ -f "$1" ]] && grep "login:" "$1" 2>/dev/null || true
}

# ── Parse de argumentos ───────────────────────────────────────────────────────
while getopts ":i:o:t:STRh" opt; do
  case $opt in
    i) HOSTS_FILE="$OPTARG"  ;;
    o) OUTPUT_DIR="$OPTARG"  ;;
    t) TASKS="$OPTARG"       ;;
    S) SKIP_SSH=true         ;;
    T) SKIP_TELNET=true      ;;
    R) SKIP_RDP=true         ;;
    h) usage                 ;;
    :) die "Opção -$OPTARG requer argumento." ;;
    \?) die "Opção inválida: -$OPTARG" ;;
  esac
done

banner

[[ -z "$HOSTS_FILE" ]] && { error "Arquivo de hosts obrigatório. Use -i <arquivo>"; echo ""; exit 1; }
[[ -f "$HOSTS_FILE" ]] || die "Arquivo não encontrado: $HOSTS_FILE"
[[ -s "$HOSTS_FILE" ]] || die "Arquivo vazio: $HOSTS_FILE"
command -v hydra &>/dev/null || die "hydra não encontrado. Instale com: apt install hydra"

OUTPUT_DIR="${OUTPUT_DIR:-./output_default_creds_${START_TS}}"
mkdir -p "$OUTPUT_DIR"/{ssh,telnet,rdp,logs}

USERS_FILE="$OUTPUT_DIR/users.txt"
PASS_FILE="$OUTPUT_DIR/passwords.txt"

# =============================================================================
#  Credenciais default conhecidas
# =============================================================================
step "Gerando listas de credenciais default"

cat > "$USERS_FILE" << 'EOF'
admin
administrator
root
user
guest
test
support
operator
manager
service
ubnt
pi
cisco
oracle
postgres
mysql
ftp
anonymous
EOF

info "$(count_lines "$USERS_FILE") usernames default gerados"

cat > "$PASS_FILE" << 'EOF'
admin
administrator
root
password
password123
123456
12345678
1234
test
guest
blank
default
changeme
letmein
welcome
qwerty
abc123
pass
support
service
EOF

info "$(count_lines "$PASS_FILE") senhas default geradas"

# =============================================================================
#  Exibe resultado de cada protocolo
# =============================================================================
show_protocol_result() {
  local out_file="$1"
  local proto="$2"
  local found
  found=$(count_hits "$out_file")
  found=$(( 10#${found:-0} ))   # força base-10, elimina zeros à esquerda

  if (( found > 0 )); then
    echo -e "${GREEN}[+]${RESET} $(date '+%H:%M:%S') ${RED}${BOLD}${found} credencial(is) default encontrada(s) em ${proto}:${RESET}"
    show_hits "$out_file" | while IFS= read -r line; do
      echo -e "    ${RED}•${RESET} $line"
    done
  else
    info "Nenhuma credencial default encontrada em ${proto}."
  fi
}

# =============================================================================
#  Etapa 1 — SSH (porta 22)
# =============================================================================
if [[ "$SKIP_SSH" == false ]]; then
  step "Etapa 1/3 — SSH (porta 22)"
  SSH_OUT="$OUTPUT_DIR/ssh/results.txt"

  info "Executando hydra SSH em $(count_lines "$HOSTS_FILE") host(s)..."
  hydra \
    -L "$USERS_FILE" \
    -P "$PASS_FILE" \
    -M "$HOSTS_FILE" \
    -t "$TASKS" \
    -T 32 \
    -f \
    -o "$SSH_OUT" \
    ssh \
    2>>"$OUTPUT_DIR/logs/ssh.log" || true

  show_protocol_result "$SSH_OUT" "SSH"
  done_step "SSH concluído"
else
  warn "SSH ignorado (-S)."
fi

# =============================================================================
#  Etapa 2 — Telnet (porta 23)
# =============================================================================
if [[ "$SKIP_TELNET" == false ]]; then
  step "Etapa 2/3 — Telnet (porta 23)"
  TELNET_OUT="$OUTPUT_DIR/telnet/results.txt"

  info "Executando hydra Telnet em $(count_lines "$HOSTS_FILE") host(s)..."
  hydra \
    -L "$USERS_FILE" \
    -P "$PASS_FILE" \
    -M "$HOSTS_FILE" \
    -t "$TASKS" \
    -T 32 \
    -f \
    -o "$TELNET_OUT" \
    telnet \
    2>>"$OUTPUT_DIR/logs/telnet.log" || true

  show_protocol_result "$TELNET_OUT" "Telnet"
  done_step "Telnet concluído"
else
  warn "Telnet ignorado (-T)."
fi

# =============================================================================
#  Etapa 3 — RDP (porta 3389)
# =============================================================================
if [[ "$SKIP_RDP" == false ]]; then
  step "Etapa 3/3 — RDP (porta 3389)"
  RDP_OUT="$OUTPUT_DIR/rdp/results.txt"

  info "Executando hydra RDP em $(count_lines "$HOSTS_FILE") host(s)..."
  hydra \
    -L "$USERS_FILE" \
    -P "$PASS_FILE" \
    -M "$HOSTS_FILE" \
    -t 1 \
    -T 32 \
    -f \
    -o "$RDP_OUT" \
    rdp \
    2>>"$OUTPUT_DIR/logs/rdp.log" || true

  show_protocol_result "$RDP_OUT" "RDP"
  done_step "RDP concluído"
else
  warn "RDP ignorado (-R)."
fi

# =============================================================================
#  Relatório Final
# =============================================================================
step "Relatório Final"

COMBINED="$OUTPUT_DIR/all_results.txt"
for f in "$OUTPUT_DIR/ssh/results.txt" \
         "$OUTPUT_DIR/telnet/results.txt" \
         "$OUTPUT_DIR/rdp/results.txt"; do
  [[ -f "$f" ]] && grep "login:" "$f" >> "$COMBINED" 2>/dev/null || true
done
[[ -f "$COMBINED" ]] && sort -u "$COMBINED" -o "$COMBINED" || true

TOTAL_HITS=$(count_hits "$COMBINED")
TOTAL_HITS=$(( 10#${TOTAL_HITS:-0} ))

echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║           RESUMO — CREDENCIAIS DEFAULT       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
printf "  %-30s %s\n" "Hosts verificados:"    "$(count_lines "$HOSTS_FILE")"
printf "  %-30s %s\n" "Protocolos testados:"  "SSH / Telnet / RDP"
printf "  %-30s %s\n" "Total de hits:"        "$TOTAL_HITS"
echo ""

if (( TOTAL_HITS > 0 )); then
  echo -e "  ${BOLD}${RED}Credenciais default encontradas:${RESET}"
  show_hits "$COMBINED" | while IFS= read -r line; do
    echo -e "    ${RED}•${RESET} $line"
  done
  echo ""
else
  echo -e "  ${GREEN}Nenhuma credencial default encontrada.${RESET}"
  echo ""
fi

printf "  %-30s %s\n" "Resultados completos:" "$OUTPUT_DIR"
echo ""
echo -e "${GREEN}${BOLD}  Verificação concluída! $(date)${RESET}"
echo ""
