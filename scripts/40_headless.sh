#!/usr/bin/env bash
# 40_headless.sh - przystosowanie laptopa do pracy jako serwer (headless).
#
# 1) Wyłącza usypianie przy zamknięciu pokrywy (praca z zamkniętą klapą,
#    niższy pobór mocy - wygaszony wyświetlacz).
# 2) Włącza przekazywanie pakietów IPv4/IPv6, wymagane przez router podsieci
#    Tailscale (podrozdział 3.5 pracy).

source "$(dirname "$(readlink -f "$0")")/lib_common.sh"
require_root

# --- 1. Praca z zamkniętą pokrywą -----------------------------------------
LOGIND="/etc/systemd/logind.conf"
log "Wyłączam usypianie przy zamknięciu pokrywy (${LOGIND})"
backup_file "$LOGIND"
for key in HandleLidSwitch HandleLidSwitchExternalPower HandleLidSwitchDocked; do
    if grep -qE "^#?${key}=" "$LOGIND"; then
        sed -i "s/^#*${key}=.*/${key}=ignore/" "$LOGIND"
    else
        echo "${key}=ignore" >> "$LOGIND"
    fi
done
systemctl restart systemd-logind
log "Serwer może pracować z zamkniętą pokrywą (bez usypiania)."

# --- 2. Przekazywanie pakietów (dla routera podsieci Tailscale) ------------
SYSCTL="/etc/sysctl.d/99-nas-forwarding.conf"
log "Włączam przekazywanie pakietów (${SYSCTL})"
cat > "$SYSCTL" <<'EOF'
# Przekazywanie pakietów - wymagane przez router podsieci Tailscale
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p "$SYSCTL"
log "Przekazywanie pakietów IPv4/IPv6 włączone."
