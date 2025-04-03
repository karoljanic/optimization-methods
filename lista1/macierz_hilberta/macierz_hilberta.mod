# Problem programowania liniowego z macierzą Hilberta - model
# Karol Janic

# rozmiar problemu
param n, integer, >= 1;                                                 

# macierz Hilberta A
param A{i in {1..n}, j in {1..n}} := 1.0 / (i+j-1);

# wektor prawych stron b
param b{i in {1..n}} := sum{j in {1..n}} A[i,j];

# wektor kosztów c
param c{i in {1..n}} := sum{j in {1..n}} A[j,i];

# zmienne decyzyjne x - wektor rozwiązań
var x{i in {1..n}} >= 0;                                                                       

# funkcja celu - minimalizacja sumy składowych wektora c^Tx
minimize koszt_calkowity: sum{i in {1..n}} c[i] * x[i];

# ograniczenie - spełnienie układu równań liniowych Ax = b
subject to uklad_rownan{i in {1..n}}: sum{j in {1..n}} A[i,j] * x[j] = b[i];

solve;

# oczekiwane rozwiązanie
param rozwiazanie_oczekiwane{i in {1..n}} := 1.0;

# błąd względny
param blad_wzgledny := sqrt(sum{i in {1..n}} (rozwiazanie_oczekiwane[i] - x[i])^2) / sqrt(sum{i in {1..n}} rozwiazanie_oczekiwane[i]^2);

printf "x = ";
for {i in {1..n}} {
    printf "%f ", x[i];
}
printf "\n";

printf "Koszt całkowity: %f\n", koszt_calkowity;

printf "Błąd względny: %.2e\n", blad_wzgledny;


end;
