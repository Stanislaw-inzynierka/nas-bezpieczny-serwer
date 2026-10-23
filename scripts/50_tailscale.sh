#!/usr/bin/env bash
# 50_tailscale.sh - instalacja i uruchomienie Tailscale jako routera podsieci.
#
# Zapewnia bezpieczny dostęp zdalny bez otwierania portów na routerze
# (działa metodą NAT traversal, odporną na CGNAT operatora). Host udostępnia
# całą podsieć lokalną uprawnionym urządzeniom w tailnecie.
#
# Podsieć można nadpisać:  SUBNET=192.168.1.0/24 ./50_tailscale.sh
# Po uruchomieniu należy zatwierdzić trasę w panelu admina Tailscale oraz
# zalogować się linkiem autoryzacyjnym wypisanym przez 'tailscale up'.

source "$(dirname "$(readlink -f "$0")")/lib_common.sh"
require_root

SUBNET="${SUBNET:-192.168.1.0/24}"

if ! command -v tailscale >/dev/null 2>&1; then
    log "Instaluję Tailscale (oficjalny skrypt instalacyjny)"
    # Uwaga: na Proxmoksie instalator bywa przerywany przez błąd 401 repozytorium
    # enterprise; w razie potrzeby dokończyć: apt-get install -y tailscale
    curl -fsSL https://tailscale.com/install.sh | sh \
        || { warn "Instalator przerwany - próbuję 'apt-get install -y tailscale'"; \
             apt-get install -y tailscale; }
fi

log "Uruchamiam Tailscale jako router podsieci dla ${SUBNET}"
tailscale up --advertise-routes="${SUBNET}"

warn "Zatwierdź udostępnioną trasę (${SUBNET}) w panelu: Admin console -> Machines -> Routes."
log "Dostęp zdalny przez Tailscale skonfigurowany (bez otwierania portów na routerze)."
