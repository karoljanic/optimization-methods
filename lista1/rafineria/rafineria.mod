# Problem proporcji w procesie rafinacji ropy naftowej - model
# Karol Janic

# zbiór typów ropy naftowej
set rodzaje_ropy;

# zbiór etapów procesu rafinacji
set etapy_produkcji;

# zbiór rodzajów produktów
set rodzaje_produktow;

# zbiór produktów
set produkty;

# suma zbiorów ropy i produktów
set ropa_i_produkty := rodzaje_ropy union produkty;

param wejscia_ropy {etapy_produkcji, rodzaje_ropy} binary;

# ceny ropy naftowej w dolarach za tonę
param cena_ropy{rodzaje_ropy} >= 0;

# zapotrzebowanie na dane produkty w tonach
param zapotrzebowanie{rodzaje_produktow} >= 0;

# opis przepływu ropy naftowej między etapami produkcji
param przeplyw_produkcji{etapy_produkcji, etapy_produkcji, ropa_i_produkty} binary;

# wydajność produkcji na danym etapie
param wydajnosc_produkcji{etapy_produkcji, produkty} >= 0;

# koszt produkcji na danym etapie
param koszty_produkcji{etapy_produkcji} >= 0;

# zbiorniki na produkty końcowe
param przeplyw_do_zbiornikow{etapy_produkcji, rodzaje_produktow, ropa_i_produkty} binary;

param limit_siarki_olejow_opalowych >= 0 <= 1;
param zawartosc_siarki_destylacji{rodzaje_ropy} >= 0 <= 1;
param zawartosc_siarki_krakingu{rodzaje_ropy} >= 0 <= 1;

# zmienne decyzyjne - ilości niezbędnej ropy danego typu
var zuzycie_ropy{rodzaje_ropy} >= 0;

# zmienne decyzyjne - ilości produktów na wejściu i wyjściu z etapów produkcji
var wejscia_etapow{etapy_produkcji, rodzaje_ropy, ropa_i_produkty} >= 0;
var wyjscia_etapow{etapy_produkcji, rodzaje_ropy, ropa_i_produkty} >= 0;

# zmienne decyzyjne - ilości produktów zostających w instalacji
var zostaje_w_instalacji{etapy_produkcji, etapy_produkcji, rodzaje_ropy, ropa_i_produkty} >= 0;
var idzie_do_zbiornika{etapy_produkcji, rodzaje_produktow, rodzaje_ropy, ropa_i_produkty} >= 0;

# zmienne decyzyjne - ilości produktów w zbiornikach
var zawartosc_zbiornikow{rodzaje_produktow} >= 0;

# funkcja celu - minimalizacja kosztów produkcji
minimize calkowity_koszt_produkcji:
    sum{rr in rodzaje_ropy} (zuzycie_ropy[rr] * cena_ropy[rr]) +
    sum{ep in etapy_produkcji, rr in rodzaje_ropy, rip in ropa_i_produkty} (wejscia_etapow[ep, rr, rip] * koszty_produkcji[ep]);

# ograniczenie - ustawienie ropy na wejściu etapów produkcji
subject to ograniczenie_wejscia_rop1{ep in etapy_produkcji, rr in rodzaje_ropy, rip in ropa_i_produkty: rr = rip}:
    zuzycie_ropy[rr] = sum{e in etapy_produkcji}(wejscia_etapow[e, rr, rip] * wejscia_ropy[e, rr]);

# ograniczenie - ustawienie produktów na wejściu etapów produkcji
subject to ograniczenie_wejscia_rop2{ep in etapy_produkcji, rr in rodzaje_ropy, rip in ropa_i_produkty: rr != rip or wejscia_ropy[ep, rr] = 0}:
    wejscia_etapow[ep, rr, rip] = sum{e in etapy_produkcji}(zostaje_w_instalacji[e, ep, rr, rip] * przeplyw_produkcji[e, ep, rip]);

# ograniczenie - zachowanie przepływu ropy naftowej
subject to plynnosc{ep in etapy_produkcji, rr in rodzaje_ropy, pp in produkty}:
    wyjscia_etapow[ep, rr, pp] = sum{rip in ropa_i_produkty}(wejscia_etapow[ep, rr, rip]) * wydajnosc_produkcji[ep, pp];

# ograniczenie - podział produktów na etapach produkcji
subject to podzial_produktow{ep in etapy_produkcji, rr in rodzaje_ropy, pp in produkty}:
    wyjscia_etapow[ep, rr, pp] = sum{rp in rodzaje_produktow}idzie_do_zbiornika[ep, rp, rr, pp] + sum{e in etapy_produkcji}zostaje_w_instalacji[ep, e, rr, pp];

# ograniczenie - przepływ produktów do zbiorników
subject to przeplyw_produktow_do_zbiornikow{rp in rodzaje_produktow}: 
    zawartosc_zbiornikow[rp] = sum{ep in etapy_produkcji, rr in rodzaje_ropy, pp in produkty} (przeplyw_do_zbiornikow[ep, rp, pp] * idzie_do_zbiornika[ep, rp, rr, pp]);

# ograniczenie - limit siarki w olejach opalowych
subject to limit_siarki:
    sum {rr in rodzaje_ropy} (wyjscia_etapow['kraking', rr, 'olej'] * zawartosc_siarki_krakingu[rr] + wyjscia_etapow['destylacja1', rr, 'olej'] * zawartosc_siarki_destylacji[rr] + wyjscia_etapow['destylacja2', rr, 'olej'] * zawartosc_siarki_destylacji[rr]) <= limit_siarki_olejow_opalowych * zawartosc_zbiornikow["paliwoDomowe"];

# ograniczenie - spełnienie zapotrzebowania na produkty
subject to zapotrzebowanie_na_produkty{rp in rodzaje_produktow}:
    zawartosc_zbiornikow[rp] >= zapotrzebowanie[rp];

solve;

printf "Zużycie ropy naftowej:\n";
for {rr in rodzaje_ropy} {
    printf "%s: %f\n", rr, zuzycie_ropy[rr];
}
printf "\n";

printf "Ilość wyprodukowanych paliw:\n";
for {rp in rodzaje_produktow} {
    printf "%s: %f\n", rp, zawartosc_zbiornikow[rp];
}
printf "\n";

printf "Koszt produkcji: %f\n", calkowity_koszt_produkcji;

printf "\n\n";

printf "Wejścia i wyjścia etapów produkcji:\n";
for {ep in etapy_produkcji, rr in rodzaje_ropy} {
    printf "Etap: %s, Ropa: %s\n", ep, rr;
    for {rip in ropa_i_produkty: wejscia_etapow[ep, rr, rip] > 0} {
        printf "in:  %s: %f\n", rip, wejscia_etapow[ep, rr, rip];
    }
    for {rip in ropa_i_produkty: wyjscia_etapow[ep, rr, rip] > 0} {
        printf "out:  %s: %f\n", rip, wyjscia_etapow[ep, rr, rip];
    }
}

printf "\n\n";

printf "Zostaje w instalacji:\n";
for {ep in etapy_produkcji, rr in rodzaje_ropy} {
    printf "Etap: %s, Ropa: %s\n", ep, rr;
    for {e in etapy_produkcji, rip in ropa_i_produkty: zostaje_w_instalacji[ep, e, rr, rip] > 0} {
        printf "in:  %s: %f\n", rip, zostaje_w_instalacji[ep, e, rr, rip];
    }
}

printf "\n\n";

printf "Idzie do zbiornikow:\n";
for {ep in etapy_produkcji, rr in rodzaje_ropy} {
    printf "Etap: %s, Ropa: %s\n", ep, rr;
    for {rp in rodzaje_produktow, rip in ropa_i_produkty: idzie_do_zbiornika[ep, rp, rr, rip] > 0} {
        printf "out:  %s: %f\n", rp, idzie_do_zbiornika[ep, rp, rr, rip];
    }
}

end;
