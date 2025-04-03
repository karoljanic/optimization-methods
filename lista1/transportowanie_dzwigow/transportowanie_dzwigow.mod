# Problem transportowania dźwigów - model
# Karol Janic

# zbiór miast
set miasta;

# typy dźwigów
set typy;

# odległości między miastami w kilometrach
param odleglosci{miasta, miasta} >= 0;

# koszt transportu dźwigu typu za 1 kilometr
param koszty{typy} >= 0;

# liczba brakujących i nadmiarowych dźwigów dla każdego miasta i typu
param nadmiar{miasta, typy} >= 0;
param brak{miasta, typy} >= 0;

# zmienne decyzyjne - liczba dźwigów danego typu transportowanych między miastami
var transport{typy, miasta, miasta} >= 0 integer;

# funkcja celu - minimalizacja kosztu transportu
minimize koszt_transportu: sum{t in typy, m1 in miasta, m2 in miasta} (koszty[t] * transport[t, m1,m2] * odleglosci[m1,m2]);

# całkowite zapotrzebowanie na dźwigi
subject to calkowite_zapotrzebowanie{t in typy, m in miasta}:
sum{k in typy: k >= t} (nadmiar[m, k] - brak[m, k] + (sum{m1 in miasta} transport[k, m1, m]) - (sum{m1 in miasta} transport[k, m, m1])) >= 0;

solve;

printf "Koszt transportu: %f\n", koszt_transportu;

for {t in typy, m1 in miasta, m2 in miasta: transport[t, m1, m2] > 0}: {
    printf "Liczba dźwigów typu %s transportowanych z %s do %s: %d\n", t, m1, m2, transport[t, m1, m2];
}


end;
