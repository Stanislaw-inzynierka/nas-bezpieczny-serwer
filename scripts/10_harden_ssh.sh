#!/usr/bin/env bash
# 10_harden_ssh.sh - utwardzenie usługi SSH na hoście.
#
# Wyłącza logowanie hasłem oraz bezpośrednie logowanie na konto root,
# wymuszając uwierzytelnianie kluczem publicznym. UWAGA: przed uruchomieniem
# upewnij się, że logowanie kluczem DZIAŁA - inaczej odetniesz sobie dostęp.
#
# Konfiguracja zapisywana jest w osobnym pliku drop-in, co jest czytelniejsze
# i bezpieczniejsze niż edycja głównego sshd_config.

source "$(dirname "$(readlink -f "$0")")/lib_common.sh"
require_root

DROPIN="/etc/ssh/sshd_config.d/99-hardening.conf"

log "Zapisuję utwardzoną konfigurację SSH do ${DROPIN}"
backup_file "$DROPIN"
cat > "$DROPIN" <<'EOF'
# Utwardzenie SSH - plik generowany przez 10_harden_ssh.sh
PasswordAuthentication no
PermitRootLogin no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
EOF

log "Sprawdzam poprawność konfiguracji (sshd -t)"
sshd -t || die "Konfiguracja SSH jest niepoprawna - nie restartuję usługi."

log "Restartuję usługę SSH"
systemctl restart ssh 2>/dev/null || systemctl restart sshd
log "SSH utwardzony: logowanie wyłącznie kluczem, root przez SSH zablokowany."
