#!/usr/bin/env python3
"""Analiza kosztu całkowitego (TCO) i poboru mocy serwera NAS.

Narzędzie oblicza i porównuje koszt pięcioletni własnego serwera NAS
(ze sprzętu odzyskanego oraz kupionego) z abonamentem chmurowym, a także
roczną emisję CO2 związaną z pracą serwera. Wszystkie dane wejściowe są
parametrami - po zmianie np. ceny energii wystarczy uruchomić skrypt
ponownie, by przeliczyć wartości i wygenerować wykres (Rysunek 4.1 pracy).

Logika obliczeń (compute_costs) jest oddzielona od generowania wykresu,
dzięki czemu można ją pokryć testami jednostkowymi (zob. tests/).

Uruchomienie:  python3 gen_tco.py
"""
from __future__ import annotations

# --- Dane wejściowe (parametry modelu) -------------------------------------
# Pobór mocy zmierzono wbudowanym miernikiem akumulatora laptopa (na baterii,
# prąd x napięcie): spoczynek z wygaszonym ekranem ~4,9 W, pełne obciążenie
# CPU ~24 W. Do obliczeń przyjęto 7 W jako wartość reprezentatywną dla pracy
# ciągłej (spoczynek dominuje; margines na obciążenie i straty zasilacza).
POWER_W     = 7.0       # reprezentatywny pobór mocy serwera [W]
PRICE_KWH   = 1.26      # cena energii brutto [zł/kWh] (taryfa G11)
CLOUD_MONTH = 46.99     # Google One Premium 2 TB, płatność miesięczna [zł]
CLOUD_YEAR  = 469.99    # Google One Premium 2 TB, płatność roczna [zł]
HW_COST     = 1200.0    # orientacyjny koszt używanego laptopa tej klasy [zł]
EMISSION    = 0.553     # wskaźnik emisyjności energii [kg CO2/kWh], KOBiZE 2025
AVOIDED_CO2 = 107.0     # uniknięta emisja z produkcji nowego laptopa [kg CO2]
YEARS       = 5         # horyzont analizy [lata]


def compute_costs(power_w=POWER_W, price_kwh=PRICE_KWH, cloud_month=CLOUD_MONTH,
                  cloud_year=CLOUD_YEAR, hw_cost=HW_COST, emission=EMISSION,
                  avoided_co2=AVOIDED_CO2, years=YEARS):
    """Zwraca słownik z wyliczonymi wskaźnikami kosztowymi i środowiskowymi.

    Funkcja jest czysta (bez efektów ubocznych), co umożliwia jej testowanie.
    """
    kwh_year  = power_w * 24 * 365 / 1000          # roczne zużycie energii [kWh]
    energy_yr = kwh_year * price_kwh               # roczny koszt energii [zł]
    cloud_m_yr = cloud_month * 12                  # roczny koszt chmury (mies.) [zł]

    nas_reuse_total = energy_yr * years            # NAS odzyskany (tylko energia)
    nas_buy_total   = hw_cost + energy_yr * years  # NAS kupiony (sprzęt + energia)

    return {
        "kwh_year": kwh_year,
        "energy_yr": energy_yr,
        "energy_total": energy_yr * years,
        "cloud_year_total": cloud_year * years,
        "cloud_month_total": cloud_m_yr * years,
        "nas_reuse_total": nas_reuse_total,
        "nas_buy_total": nas_buy_total,
        # próg opłacalności zakupu sprzętu względem chmury (lata)
        "breakeven_vs_year": hw_cost / (cloud_year - energy_yr),
        "breakeven_vs_month": hw_cost / (cloud_m_yr - energy_yr),
        # ile razy NAS odzyskany jest tańszy od chmury rocznej
        "ratio_reuse_vs_year": (cloud_year * years) / nas_reuse_total,
        # emisja roczna i liczba lat odpowiadająca unikniętej emisji produkcji
        "emission_year": kwh_year * emission,
        "payback_emission_years": avoided_co2 / (kwh_year * emission),
    }


def _fmt_zl(x: float) -> str:
    """Formatuje kwotę w złotych ze spacją jako separatorem tysięcy."""
    return f"{x:,.0f}".replace(",", " ") + " zł"


def build_chart(res, path_full, path_small=None,
                price_kwh=PRICE_KWH, cloud_month=CLOUD_MONTH, cloud_year=CLOUD_YEAR,
                hw_cost=HW_COST, years=YEARS):
    """Generuje wykres kosztu skumulowanego (Rysunek 4.1) i zapisuje do pliku."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from PIL import Image

    energy_yr = res["energy_yr"]
    cloud_m_yr = cloud_month * 12
    xs = list(range(years + 1))
    cloud_m = [cloud_m_yr * x for x in xs]
    cloud_y = [cloud_year * x for x in xs]
    nas_buy = [hw_cost + energy_yr * x for x in xs]
    nas_reu = [energy_yr * x for x in xs]
    be = res["breakeven_vs_year"]

    plt.rcParams.update({"font.size": 13})
    fig, ax = plt.subplots(figsize=(13, 7.2), dpi=100)
    ax.plot(xs, cloud_m, color="#c0392b", lw=2, ls="--", marker="o", ms=6, alpha=0.55,
            label="Chmura - Google One 2 TB, płatność miesięczna ("
                  + f"{cloud_month:.2f}".replace(".", ",") + " zł/mies.)")
    ax.plot(xs, cloud_y, color="#c0392b", lw=3.2, marker="o", ms=9,
            label="Chmura - Google One 2 TB, płatność roczna ("
                  + f"{cloud_year:.2f}".replace(".", ",") + " zł/rok)")
    ax.plot(xs, nas_buy, color="#1f6fb2", lw=3.2, marker="s", ms=9,
            label=f"NAS - sprzęt kupiony używany (ok. {hw_cost:.0f} zł) + energia")
    ax.plot(xs, nas_reu, color="#2e8b57", lw=3.2, marker="^", ms=10,
            label=f"NAS - sprzęt odzyskany (tylko energia ~{energy_yr:.0f} zł/rok)")
    ax.axvline(be, color="gray", ls="--", lw=1.8)
    ax.text(be + 0.07, max(cloud_m) * 0.28,
            f"próg opłacalności\n(sprzęt kupiony vs\nchmura roczna) ≈ {be:.1f} roku".replace(".", ","),
            color="#555", fontsize=12)
    for series in (cloud_m, cloud_y, nas_buy, nas_reu):
        ax.annotate(_fmt_zl(series[-1]), (years, series[-1]), textcoords="offset points",
                    xytext=(-8, 8), ha="right", fontsize=12, fontweight="bold", color="black")
    ax.set_xlim(0, years)
    ax.set_ylim(0, max(cloud_m) * 1.08)
    ax.set_xlabel("Okres użytkowania [lata]", fontsize=15)
    ax.set_ylabel("Koszt skumulowany [zł]", fontsize=15)
    ax.set_title(f"Porównanie kosztu całkowitego (TCO) w okresie {years} lat",
                 fontsize=16, fontweight="bold")
    ax.grid(True, ls=":", alpha=0.6)
    ax.legend(loc="upper left", fontsize=11.5, framealpha=0.95)
    fig.tight_layout()
    fig.savefig(path_full)
    if path_small:
        im = Image.open(path_full)
        im.thumbnail((1400, 1400))
        im.save(path_small)


def main():
    res = compute_costs()
    labels = {
        "kwh_year": "zużycie energii [kWh/rok]",
        "energy_yr": "koszt energii [zł/rok]",
        "energy_total": f"koszt energii [{YEARS} lat, zł]",
        "cloud_year_total": f"chmura, płatność roczna [{YEARS} lat, zł]",
        "cloud_month_total": f"chmura, płatność miesięczna [{YEARS} lat, zł]",
        "nas_buy_total": f"NAS kupiony [{YEARS} lat, zł]",
        "nas_reuse_total": f"NAS odzyskany [{YEARS} lat, zł]",
        "breakeven_vs_year": "próg opłacalności vs chmura roczna [lata]",
        "breakeven_vs_month": "próg opłacalności vs chmura mies. [lata]",
        "ratio_reuse_vs_year": "ile razy NAS odzyskany tańszy od chmury rocznej",
        "emission_year": "emisja [kg CO2/rok]",
        "payback_emission_years": "lata odpowiadające unikniętej emisji produkcji",
    }
    for key, label in labels.items():
        print(f"{label:48s} {res[key]:10.2f}")

    import os
    out_dir = os.path.join(os.path.dirname(__file__), "..", "figures")
    os.makedirs(out_dir, exist_ok=True)
    build_chart(res, os.path.join(out_dir, "tco.png"), os.path.join(out_dir, "tco_s.png"))
    print("wykres zapisany w katalogu figures/")


if __name__ == "__main__":
    main()
