#!/usr/bin/env bash
# 30_fail2ban.sh - ochrona przed atakami siłowymi na SSH (fail2ban).
#
# Po przekroczeniu zadanej liczby nieudanych prób logowania w oknie czasowym
# adres źródłowy jest automatycznie blokowany na określony czas. Parametry
# odpowiadają konfiguracji opisanej w pracy (maxretry=4, findtime=600,
# bantime=3600) i można je nadpisać zmiennymi środowiskowymi.

source "$(dirname "$(readlink -f "$0")")/lib_common.sh"
require_root

MAXRETRY="${MAXRETRY:-4}"
FINDTIME="${FINDTIME:-600}"
BANTIME="${BANTIME:-3600}"

ensure_pkg fail2ban

JAIL="/etc/fail2ban/jail.local"
log "Zapisuję konfigurację jaila SSH do ${JAIL}"
backup_file "$JAIL"
cat > "$JAIL" <<EOF
# Konfiguracja fail2ban - plik generowany przez 30_fail2ban.sh
[sshd]
enabled  = true
backend  = systemd
maxretry = ${MAXRETRY}
findtime = ${FINDTIME}
bantime  = ${BANTIME}
EOF

log "Uruchamiam i włączam usługę fail2ban"
systemctl enable --now fail2ban
systemctl restart fail2ban

sleep 1
fail2ban-client status sshd || warn "Nie udało się odczytać statusu jaila sshd."
log "fail2ban aktywny: ${MAXRETRY} prób / ${FINDTIME}s -> blokada na ${BANTIME}s."
