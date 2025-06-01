# Planowanie procesu z rodzielaniem zasobów oraz ograniczeniami kolejności
# Karol Janic

using JSON
using JuMP
using HiGHS
using Plots


# Wczytanie danych z pliku JSON
if length(ARGS) != 1
    println("Użycie: julia model.jl <plik-danych.json>")
    exit(1)
else
    plik_danych = ARGS[1]
end

dane = JSON.parsefile(plik_danych)
zasoby::Vector{Int} = [z["typ"] for z in dane["zasoby"]]
limity_zasobow::Dict{Int, Int} = Dict(z["typ"] => z["limit"] for z in dane["zasoby"])
zadania::Vector{Int} = [z["numer"] for z in dane["zadania"]]
czasy_zadan::Dict{Int, Int} = Dict(z["numer"] => z["czas"] for z in dane["zadania"])
zapotrzebowania_zadan::Dict{Int, Dict{Int, Int}} = Dict(z["numer"] => Dict(zs["zasob"] => zs["ilosc"] for zs in z["zapotrzebowanie"]) for z in dane["zadania"])
poprzednicy_zadan::Dict{Int, Vector{Int}} = Dict(z["numer"] => z["poprzednicy"] for z in dane["zadania"])

liczba_zadan::Int = length(zadania)
liczba_zasobow::Int = length(zasoby)

println("Typy zasobów: ", zasoby)
println("Limity zasobów: ", limity_zasobow)
println("Zadania: ", zadania)
println("Czasy zadań: ", czasy_zadan)
println("Zapotrzebowanie zadań: ", zapotrzebowania_zadan)
println("Poprzednicy zadań: ", poprzednicy_zadan)
println("Liczba zadań: ", liczba_zadan)
println("Liczba zasobów: ", liczba_zasobow)

M::Int = sum(values(czasy_zadan)) + 1
println("M: ", M)

eventy = 1:liczba_zadan

#model = Model(GLPK.Optimizer)
model = Model(HiGHS.Optimizer)
set_optimizer_attribute(model, "mip_feasibility_tolerance", 1e-10)

# Czas rozpoczęcia danego zadania
@variable(model, x[1:liczba_zadan]>=0)

# y[i,j] = 1, gdy i jest aktywne w momencie x[j]
@variable(model, y[1:liczba_zadan,1:liczba_zadan], Bin)

# Pomocnicze zmienne
@variable(model, a[1:liczba_zadan,1:liczba_zadan], Bin)
@variable(model, b[1:liczba_zadan,1:liczba_zadan], Bin)

@variable(model, c)

@objective(model, Min, c)
@constraint(model, [i in 1:liczba_zadan], x[i] + czasy_zadan[i] <= c)

# Wszystkie aktywne w danym momencie nie zużywają za dużo zasobów
for z in zasoby
    @constraint(model,
    [i in 1:liczba_zadan],
    limity_zasobow[z] >= sum(zapotrzebowania_zadan[j][z] * y[j,i] for j in 1:liczba_zadan)
)
end

@constraint(model,
    [i in 1:liczba_zadan,j in 1:liczba_zadan],
    a[i,j] * M >= x[j] - x[i] + 1e-3
)

# b[i,j] = [[ x[i] + P[i] >= x[j] ]] = [[ x[i] + P[i] - x[j] >= 0 ]]
@constraint(model,
    [i in 1:liczba_zadan,j in 1:liczba_zadan],
    b[i,j] * M >= x[i] + czasy_zadan[i] - x[j] + 1e-3
)
@constraint(model,
    [i in 1:liczba_zadan,j in 1:liczba_zadan],
    y[i,j] >= a[i,j] + b[i,j] - 1
)

# Spełniony jest graf
@constraint(model, [i in 1:liczba_zadan, j in poprzednicy_zadan[i]], x[j] + czasy_zadan[j] <= x[i])

# Uruchomienie modelu
optimize!(model)

# Rozwiązanie
if termination_status(model) == MOI.OPTIMAL
    println("Znaleziono optymalne rozwiązanie.")

    println("Czas zakończenia: ", objective_value(model))
    println("Czasy rozpoczęcia zadań: ")
    for z in zadania
        println("Zadanie $z: ", value(x[z]))
    end

    p = plot(xlabel="Czas", ylabel="", legend=false, title="Rozdzielanie zasobów", yticks=false)
    for z in zadania
        xs = [value(x[z]), value(x[z]) + czasy_zadan[z], value(x[z]) + czasy_zadan[z], value(x[z]), value(x[z])]
        ys = [1.5 * z - 1.5, 1.5 * z - 1.5, 1.5 * z - 0.5, 1.5 * z - 0.5, 1.5 * z - 1.5]
        plot!(p, xs, ys, seriestype = :shape, fillalpha = 0.4)
        annotate!(p, value(x[z]) + czasy_zadan[z] / 2 , 1.5 * z - 1.0, text(z, :black, 15, :left))
    end
    savefig(p, "wynik.png")

else
    println("Nie znaleziono optymalnego rozwiązania.")
end
