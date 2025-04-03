# Problem planowania zajęć - model
# Karol Janic

# robocze dni tygodnia
set dni;

# zbiór zajęć
set zajecia;

# zbiór grup
set grupy;

# dni zajęć
param dni_zajec{zajecia, grupy} >= 1, <= 5;

# godziny zajęć
param poczatki_zajec{zajecia, grupy} >= 0, <= 24;
param konce_zajec{zajecia, grupy} >= 0, <= 24;

# preferencje zajęć
param preferencje{zajecia, grupy} >= 0, <= 10;

# maksymalna liczba godzin zajęć w ciągu dnia
param maksymalna_dzienna_liczba_godzin >= 0, <= 24;

# czas możliwej przerwy obiadowej
param poczatek_przerwy_obiadowej >= 0, <= 24;
param koniec_przerwy_obiadowej >= 0, <= 24;

# czas przeznaczony na obiad
param dlugosc_obiadu >= 0, <= 24;

# zbiór treningów
set treningi;

# dni treningów
param dni_treningow{treningi} >= 1, <= 5;

# godziny treningów
param poczatki_treningow{treningi} >= 0, <= 24;
param konce_treningow{treningi} >= 0, <= 24;

param minimalna_liczba_treningow >= 0;

# zbior dni wolnych
set dni_wolne;

# minimalne preferencja zajęć
param minimalna_preferencja >= 0;

# zmienne decyzyjne - wybór grup zajęciowych
var zajecia_zapisy{zajecia, grupy} binary;

# zmienne decyzyjne - wybór treningów
var treningi_zapisy{treningi} binary;

# funkcja celu - maksymalizacja satysfakcji studenta - suma preferencji
maximize suma_preferencji: sum{z in zajecia, g in grupy} preferencje[z, g] * zajecia_zapisy[z, g];

# ograniczenie - została wybrana jedna grupa dla każdego zajęcia
subject to jedna_grupa_na_zajecie{z in zajecia}:
    sum{g in grupy} zajecia_zapisy[z, g] = 1;

# ograniczenie - maksymalna liczba godzin zajęć w ciągu dnia
subject to maksymalna_liczba_godzin_dziennie{d in dni}:
    sum{z in zajecia, g in grupy: dni_zajec[z, g] == d} ((konce_zajec[z, g] - poczatki_zajec[z, g]) * zajecia_zapisy[z, g]) <= maksymalna_dzienna_liczba_godzin;

# ograniczenie - minimalna liczba treningów
subject to odpowiednia_liczba_treningow:
    sum{t in treningi} treningi_zapisy[t] >= minimalna_liczba_treningow;

# ograniczenie zajęcia nie kolidują ze sobą
subject to zajecia_nie_koliduja{z1 in zajecia, z2 in zajecia, g1 in grupy, g2 in grupy: (z1 != z2 or g1 != g2) and dni_zajec[z1, g1] == dni_zajec[z2, g2] and poczatki_zajec[z1, g1] <= konce_zajec[z2, g2] and poczatki_zajec[z2, g2] <= konce_zajec[z1, g1]}:
    zajecia_zapisy[z1, g1] + zajecia_zapisy[z2, g2] <= 1;

# ograniczenie - treningi nie kolidują ze sobą
subject to treningi_nie_koliduja{t1 in treningi, t2 in treningi: t1 != t2 and dni_treningow[t1] == dni_treningow[t2] and poczatki_treningow[t1] <= konce_treningow[t2] and poczatki_treningow[t2] <= konce_treningow[t1]}:
    treningi_zapisy[t1] + treningi_zapisy[t2] <= 1;

# ograniczenie - zajęcia nie kolidują z treningami
subject to zajecia_nie_koliduja_z_treningami{z in zajecia, g in grupy, t in treningi: dni_zajec[z, g] == dni_treningow[t] and poczatki_zajec[z, g] <= konce_treningow[t] and poczatki_treningow[t] <= konce_zajec[z, g]}:
    zajecia_zapisy[z, g] + treningi_zapisy[t] <= 1;

# ograniczenie - zajęty czas przez zajęcia i treningi nie zabiera zbyt dużo czasu na obiad
subject to zajecia_i_treningi_nie_koliduja_z_obiadem{d in dni}:
    (
        sum{z in zajecia, g in grupy: dni_zajec[z, g] == d and poczatki_zajec[z, g] < koniec_przerwy_obiadowej and konce_zajec[z, g] > poczatek_przerwy_obiadowej} (min(konce_zajec[z, g], koniec_przerwy_obiadowej) - max(poczatki_zajec[z, g], poczatek_przerwy_obiadowej)) * zajecia_zapisy[z, g]
        + 
        sum{t in treningi: dni_treningow[t] == d and poczatki_treningow[t] < koniec_przerwy_obiadowej and konce_treningow[t] > poczatek_przerwy_obiadowej} (min(konce_treningow[t], koniec_przerwy_obiadowej) - max(poczatki_treningow[t], poczatek_przerwy_obiadowej)) * treningi_zapisy[t]
    ) 
    <= koniec_przerwy_obiadowej - poczatek_przerwy_obiadowej - dlugosc_obiadu;

# ograniczenie - zajęcia nie mają odbywać się w pewne dni
subject to zapewnienie_wolnych_dni{z in zajecia, g in grupy: dni_zajec[z, g] in dni_wolne}:
    zajecia_zapisy[z, g] = 0;

# ograniczenie - minimalna preferencja zajęć
subject to minimalna_preferencja_zajec{z in zajecia, g in grupy}:
    preferencje[z, g] >= minimalna_preferencja * zajecia_zapisy[z, g];

solve;

printf "Suma preferencji: %d\n", suma_preferencji;

for {z in zajecia, g in grupy: zajecia_zapisy[z, g] > 0}: {
    printf "Zajęcia %s zapisane do grupy %s\n", z, g;
}

for {t in treningi: treningi_zapisy[t] > 0}: {
    printf "Trening %s zapisany\n", t;
}

end;
