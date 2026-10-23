#!/usr/bin/env python3
"""Testy jednostkowe modułu analizy kosztów (analysis/gen_tco.py).

Weryfikują poprawność obliczeń TCO i emisji dla znanych danych wejściowych
oraz odporność na skrajne przypadki. Uruchomienie:  pytest -q
"""
import os
import sys
import math

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "analysis"))

from gen_tco import compute_costs  # noqa: E402


def test_zuzycie_energii_dla_7w():
    """7 W przez całą dobę i rok to ok. 61,32 kWh."""
    res = compute_costs(power_w=7.0)
    assert math.isclose(res["kwh_year"], 7 * 24 * 365 / 1000, rel_tol=1e-9)
    assert math.isclose(res["kwh_year"], 61.32, abs_tol=0.01)


def test_koszt_energii_rosnie_liniowo_z_moca():
    """Dwukrotnie większy pobór mocy to dwukrotnie wyższy koszt energii."""
    a = compute_costs(power_w=6.0)
    b = compute_costs(power_w=12.0)
    assert math.isclose(b["energy_yr"], 2 * a["energy_yr"], rel_tol=1e-9)


def test_nas_odzyskany_tanszy_od_chmury():
    """W wariancie ze sprzętem odzyskanym NAS jest tańszy od chmury rocznej."""
    res = compute_costs()
    assert res["nas_reuse_total"] < res["cloud_year_total"]
    assert res["ratio_reuse_vs_year"] > 1


def test_prog_oplacalnosci_dodatni_i_sensowny():
    """Próg opłacalności zakupu sprzętu mieści się w rozsądnym zakresie lat."""
    res = compute_costs()
    assert 0 < res["breakeven_vs_year"] < YEARS_UPPER
    # względem droższej płatności miesięcznej próg jest krótszy
    assert res["breakeven_vs_month"] < res["breakeven_vs_year"]


def test_emisja_proporcjonalna_do_zuzycia():
    """Emisja roczna to iloczyn zużycia energii i wskaźnika emisyjności."""
    res = compute_costs(power_w=7.0, emission=0.553)
    assert math.isclose(res["emission_year"], res["kwh_year"] * 0.553, rel_tol=1e-9)


def test_wartosci_referencyjne_dla_pracy():
    """Wartości użyte w rozdziale 4 pracy (7 W, 1,26 zł/kWh)."""
    res = compute_costs()
    assert round(res["energy_total"]) == 386      # koszt energii 5 lat [zł]
    assert round(res["nas_buy_total"]) == 1586     # NAS kupiony 5 lat [zł]
    assert round(res["ratio_reuse_vs_year"]) == 6  # ok. 6x taniej
    assert round(res["emission_year"]) == 34       # emisja [kg CO2/rok]


YEARS_UPPER = 10


if __name__ == "__main__":
    import pytest
    raise SystemExit(pytest.main([__file__, "-q"]))
