# Planowanie produkcji na wielu maszynach z uwzględnieniem kolejności zadań
# Karol Janic

using JSON
using JuMP
using GLPK
using Plots


# Wczytanie danych z pliku JSON
if length(ARGS) != 1
    println("Użycie: julia model.jl <plik-danych.json>")
    exit(1)
else
    plik_danych = ARGS[1]
end

dane = JSON.parsefile(plik_danych)
liczba_maszyn::Int = dane["liczba-maszyn"]
zadania::Vector{Int} = [z["numer"] for z in dane["zadania"]]
czasy_zadan::Dict{Int, Int} = Dict(z["numer"] => z["czas"] for z in dane["zadania"])
poprzednicy_zadan::Dict{Int, Vector{Int}} = Dict(z["numer"] => z["poprzednicy"] for z in dane["zadania"])

println("Liczba maszyn: ", liczba_maszyn)
println("Zadania: ", zadania)
println("Czasy zadań: ", czasy_zadan)
println("Poprzednicy zadań: ", poprzednicy_zadan)

M::Int = sum(values(czasy_zadan)) + 1


# Modelowanie problemu
model = Model(GLPK.Optimizer)

# Zmienna decyzyjna - czas zakończenia wszystkich zadań
@variable(model, t >= 0)

# Zmiennie decyzyjne - przypisanie zadań do maszyn
@variable(model, a[m in 1:liczba_maszyn, z in zadania], Bin)

# Zmienna decyzyjna - czas rozpoczęcia każdego zadania
@variable(model, x[z in zadania] >= 0)

# Zmienne decyzyjne - kolejność zadań na każdej maszynie
@variable(model, y[m in 1:liczba_maszyn, z1 in zadania, z2 in zadania], Bin)

# Funkcja celu - minimalizacja maksymalnego czasu zakończenia wszystkich zadań
@objective(model, Min, t)

# Ograniczenie - każde zadanie musi być przypisane do jednej maszyny
for z in zadania
    @constraint(model, sum(a[m, z] for m in 1:liczba_maszyn) == 1)
end

# Ograniczenie - zadanie nie może być rozpoczęte przed zakończeniem jego poprzedników
for z in zadania
    for p in poprzednicy_zadan[z]
        @constraint(model, x[z] >= x[p] + czasy_zadan[p])
    end
end

# Ograniczenie - zakończenie każdego zadania musi być mniejsze lub równe maksymalnemu czasowi
for z in zadania
    @constraint(model, x[z] + czasy_zadan[z] <= t)
end

# Ograniczenie - zadania przypisane do tej samej maszyny nie mogą się nakładać
for m in 1:liczba_maszyn
    for z1 in zadania
        for z2 in zadania
            if z1 < z2
                @constraint(model, x[z1] + czasy_zadan[z1] <= x[z2] + M * (1 - y[m, z1, z2]) + M * (2 - a[m, z1] - a[m, z2]))
                @constraint(model, x[z2] + czasy_zadan[z2] <= x[z1] + M * y[m, z1, z2] + M * (2 - a[m, z1] - a[m, z2]))
            end
        end
    end
end


# Uruchomienie modelu
optimize!(model)

# Rozwiązanie
if termination_status(model) == MOI.OPTIMAL
    println("Znaleziono optymalne rozwiązanie.")
    println("Maksymalny czas zakończenia wszystkich zadań: ", objective_value(model))

    p = plot(xlabel="Czas", ylabel="", legend=false, title="Plan produkcji", xticks=0:1:maximum(value(t)), yticks=false)
    for m in 1:liczba_maszyn
        for z in zadania
            if value(a[m, z]) > 0
                xs = [value(x[z]), value(x[z]) + czasy_zadan[z], value(x[z]) + czasy_zadan[z], value(x[z]), value(x[z])]
                ys = [1.5 * m - 1.5, 1.5 * m - 1.5, 1.5 * m - 0.5, 1.5 * m - 0.5, 1.5 * m - 1.5]
                plot!(p, xs, ys, seriestype = :shape, fillalpha = 0.4)
                annotate!(p, value(x[z]) + czasy_zadan[z] / 2 , 1.5 * m - 1.0, text(z, :black, 15, :left))
            end
        end
    end
    savefig(p, "wynik.png")

else
    println("Nie znaleziono optymalnego rozwiązania.")
end
