#!/usr/bin/env bash
# lib_common.sh - wspólne funkcje pomocnicze dla skryptów konfiguracyjnych.
# Dołączany przez pozostałe skrypty poleceniem:  source "$(dirname "$0")/lib_common.sh"
#
# Zawiera: kolorowe logowanie, przerwanie przy błędzie, sprawdzenie uprawnień
# roota oraz tworzenie kopii zapasowej pliku przed jego modyfikacją.

set -euo pipefail

# --- Logowanie -------------------------------------------------------------
_c_green='\033[0;32m'; _c_yellow='\033[0;33m'; _c_red='\033[0;31m'; _c_off='\033[0m'

log()  { printf "${_c_green}[+]${_c_off} %s\n" "$*"; }
warn() { printf "${_c_yellow}[!]${_c_off} %s\n" "$*" >&2; }
err()  { printf "${_c_red}[x]${_c_off} %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }

# --- Sprawdzenia środowiska ------------------------------------------------
require_root() {
    [ "$(id -u)" -eq 0 ] || die "Ten skrypt wymaga uprawnień roota (uruchom przez sudo)."
}

# Sprawdza, czy polecenie jest dostępne; jeśli nie - instaluje podany pakiet.
ensure_pkg() {
    local cmd="$1" pkg="${2:-$1}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "Instaluję pakiet '$pkg' (brak polecenia '$cmd')..."
        apt-get update -qq && apt-get install -y "$pkg"
    fi
}

# --- Bezpieczna modyfikacja plików ----------------------------------------
# Tworzy kopię zapasową pliku z sufiksem daty, zanim zostanie zmieniony.
backup_file() {
    local f="$1"
    if [ -f "$f" ]; then
        local bak="${f}.bak.$(date +%Y%m%d-%H%M%S)"
        cp -a "$f" "$bak"
        log "Kopia zapasowa: $bak"
    fi
}
