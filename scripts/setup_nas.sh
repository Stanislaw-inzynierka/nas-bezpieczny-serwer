#!/usr/bin/env bash
# setup_nas.sh - orkiestrator konfiguracji bezpiecznego serwera NAS.
#
# Uruchamia po kolei moduły konfiguracyjne składające się na warstwę
# bezpieczeństwa i przystosowanie laptopa do roli serwera. Każdy moduł można
# też uruchomić osobno. Zakłada działający host Proxmox VE z zainstalowanym
# systemem bazowym (instalacja hiperwizora i maszyn wirtualnych odbywa się
# interaktywnie i nie jest objęta tym skryptem).
#
# Użycie:
#   sudo ./setup_nas.sh            # pełna konfiguracja (wszystkie moduły)
#   sudo ./setup_nas.sh 20 30      # tylko wybrane moduły (firewall, fail2ban)
#
# WAŻNE: przed modułem 10 (utwardzenie SSH) upewnij się, że logowanie kluczem
# działa, inaczej stracisz zdalny dostęp.

source "$(dirname "$(readlink -f "$0")")/lib_common.sh"
require_root

DIR="$(dirname "$(readlink -f "$0")")"

# Mapa modułów: numer -> skrypt
declare -A MODULES=(
    [10]="10_harden_ssh.sh"
    [20]="20_firewall.sh"
    [30]="30_fail2ban.sh"
    [40]="40_headless.sh"
    [50]="50_tailscale.sh"
)
ORDER=(10 20 30 40 50)

# Jeśli podano argumenty, uruchom tylko wskazane moduły (w podanej kolejności).
if [ "$#" -gt 0 ]; then
    ORDER=("$@")
fi

log "Rozpoczynam konfigurację serwera NAS (moduły: ${ORDER[*]})"
for num in "${ORDER[@]}"; do
    script="${MODULES[$num]:-}"
    [ -n "$script" ] || die "Nieznany moduł: $num"
    echo
    log "=== Moduł ${num}: ${script} ==="
    bash "${DIR}/${script}"
done

echo
log "Konfiguracja zakończona. Zweryfikuj: 'ufw status verbose', 'fail2ban-client status sshd', 'tailscale status'."
