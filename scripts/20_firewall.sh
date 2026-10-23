#!/usr/bin/env bash
# 20_firewall.sh - zapora sieciowa (ufw) z polityką domyślnej odmowy.
#
# KOLEJNOŚĆ JEST KRYTYCZNA: reguły zezwalające dodawane są PRZED włączeniem
# zapory, aby nie utracić zdalnego dostępu do serwera. Domyślnie otwierane są
# tylko dwie usługi hosta: SSH oraz panel administracyjny Proxmox VE.
#
# Porty można nadpisać zmiennymi środowiskowymi, np.:
#   SSH_PORT=22 PANEL_PORT=8006 ./20_firewall.sh

source "$(dirname "$(readlink -f "$0")")/lib_common.sh"
require_root

SSH_PORT="${SSH_PORT:-22}"
PANEL_PORT="${PANEL_PORT:-8006}"

ensure_pkg ufw

log "Ustawiam politykę domyślną: deny (incoming), allow (outgoing)"
ufw default deny incoming
ufw default allow outgoing

log "Dodaję reguły zezwalające PRZED włączeniem zapory"
ufw allow "${SSH_PORT}/tcp"   comment 'SSH'
ufw allow "${PANEL_PORT}/tcp" comment 'Proxmox web UI'

log "Włączam zaporę"
ufw --force enable

ufw status verbose
log "Zapora aktywna. Otwarte porty: ${SSH_PORT}/tcp, ${PANEL_PORT}/tcp."
