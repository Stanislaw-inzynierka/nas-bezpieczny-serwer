# Bezpieczny serwer NAS z ponownie wykorzystanego komputera

Kod i narzędzia towarzyszące pracy inżynierskiej **„Projekt i implementacja
bezpiecznego serwera NAS z ponownie wykorzystanych komputerów jako alternatywy
dla komercyjnych usług chmurowych”**.

Repozytorium zawiera autorskie skrypty automatyzujące konfigurację warstwy
bezpieczeństwa serwera (budowanego na hiperwizorze Proxmox VE z systemem
OpenMediaVault) oraz narzędzie analityczne liczące koszt całkowity (TCO) i
emisję CO2, użyte do wygenerowania wyników z rozdziału 4 pracy.

## Struktura repozytorium

```
.
├── scripts/              # skrypty konfiguracyjne (bash)
│   ├── lib_common.sh     # wspólne funkcje (logowanie, kopie zapasowe, root)
│   ├── 10_harden_ssh.sh  # utwardzenie SSH (klucz-only, root off)
│   ├── 20_firewall.sh    # zapora ufw (polityka default deny)
│   ├── 30_fail2ban.sh    # ochrona przed atakami siłowymi na SSH
│   ├── 40_headless.sh    # praca z zamkniętą klapą + forwarding pakietów
│   ├── 50_tailscale.sh   # dostęp zdalny (router podsieci Tailscale)
│   └── setup_nas.sh      # orkiestrator uruchamiający moduły po kolei
├── analysis/
│   └── gen_tco.py        # analiza kosztów (TCO) i emisji + wykres
├── tests/
│   └── test_gen_tco.py   # testy jednostkowe modułu analizy
├── config/               # przykładowe pliki konfiguracyjne (wzorce)
└── figures/              # wygenerowane wykresy (tworzone przez gen_tco.py)
```

Podział na warstwy jest celowy: logika obliczeń (`analysis/`) jest oddzielona
od prezentacji (generowanie wykresu) i od testów (`tests/`), a każdy krok
konfiguracji serwera to osobny, samodzielny moduł w `scripts/`.

## Automatyzacja konfiguracji serwera

Skrypty odtwarzają warstwę bezpieczeństwa opisaną w rozdziale 3 pracy.
Przeznaczone są dla hosta Proxmox VE (Debian). Pełna konfiguracja:

```bash
sudo ./scripts/setup_nas.sh
```

Wybrane moduły (np. tylko zapora i fail2ban):

```bash
sudo ./scripts/setup_nas.sh 20 30
```

Parametry można nadpisać zmiennymi środowiskowymi, np.:

```bash
SSH_PORT=22 PANEL_PORT=8006 sudo -E ./scripts/20_firewall.sh
MAXRETRY=4 FINDTIME=600 BANTIME=3600 sudo -E ./scripts/30_fail2ban.sh
SUBNET=192.168.1.0/24 sudo -E ./scripts/50_tailscale.sh
```

> **Uwaga bezpieczeństwa.** Moduł `10_harden_ssh.sh` wyłącza logowanie hasłem.
> Uruchom go dopiero po potwierdzeniu, że logowanie kluczem SSH działa -
> inaczej stracisz zdalny dostęp do serwera. Skrypty tworzą kopie zapasowe
> modyfikowanych plików konfiguracyjnych i weryfikują poprawność konfiguracji
> SSH (`sshd -t`) przed restartem usługi.

Skrypty nie przechowują żadnych haseł ani kluczy prywatnych - uwierzytelnianie
opiera się na kluczach publicznych SSH oraz na koncie Tailscale użytkownika.

## Analiza kosztów i emisji

```bash
python3 analysis/gen_tco.py
```

Skrypt wypisuje wskaźniki kosztowe i środowiskowe oraz zapisuje wykres kosztu
skumulowanego (Rysunek 4.1 pracy) do katalogu `figures/`. Dane wejściowe
(pobór mocy, cena energii, ceny chmury) są parametrami na początku pliku -
po ich zmianie wystarczy uruchomić skrypt ponownie.

Pobór mocy serwera zmierzono wbudowanym miernikiem akumulatora laptopa
(spoczynek z wygaszonym ekranem ~4,9 W, pełne obciążenie ~24 W); do obliczeń
przyjęto 7 W jako wartość reprezentatywną dla pracy ciągłej.

## Testy

```bash
pip install pytest
pytest -q
```

Testy jednostkowe weryfikują poprawność obliczeń kosztów i emisji, w tym
wartości referencyjne użyte w rozdziale 4 pracy.

## Wymagania

- Host: Proxmox VE (Debian), dostęp roota.
- Narzędzia instalowane automatycznie przez skrypty: `ufw`, `fail2ban`,
  `tailscale`.
- Analiza: Python 3 z pakietami `matplotlib` i `Pillow` (oraz `pytest` do testów).

## Licencja

MIT - zob. plik [LICENSE](LICENSE).
