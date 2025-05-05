# Planowanie procesu z rodzielaniem zasobów oraz ograniczeniami kolejności
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
typy_zasobow::Vector{Int} = [z["typ"] for z in dane["zasoby"]]
limity_zasobow::Dict{Int, Int} = Dict(z["typ"] => z["limit"] for z in dane["zasoby"])
zadania::Vector{Int} = [z["numer"] for z in dane["zadania"]]
czasy_zadan::Dict{Int, Int} = Dict(z["numer"] => z["czas"] for z in dane["zadania"])
poprzednicy_zadan::Dict{Int, Vector{Int}} = Dict(z["numer"] => z["poprzednicy"] for z in dane["zadania"])

liczba_zadan::Int = length(zadania)
liczba_zasobow::Int = length(typy_zasobow)

println("Typy zasobów: ", typy_zasobow)
println("Limity zasobów: ", limity_zasobow)
println("Zadania: ", zadania)
println("Czasy zadań: ", czasy_zadan)
println("Poprzednicy zadań: ", poprzednicy_zadan)
println("Liczba zadań: ", liczba_zadan)
println("Liczba zasobów: ", liczba_zasobow)

M::Int = sum(values(czasy_zadan)) + 1

Events = 1:2*liczba_zadan
println("Events: ", Events)

# Modelowanie problemu
model = Model(GLPK.Optimizer)

# Zmienne decyzyjne - czasy eventów
@variable(model, t[Events] >= 0)

# Zmienne decyzyjne - eventy będące rozpoczęciem zadań
@variable(model, x[zadania, Events], Bin)

# Zmienne decyzyjne - eventy będące zakończeniem zadań
@variable(model, y[zadania, Events], Bin)

# Zmienne decyzyjne - aktywność zadań w trakcie eventów
@variable(model, z[zadania, Events], Bin)

# Funkcja celu - minimalizacja maksymalnego czasu zakończenia wszystkich zadań
@objective(model, Min, t[2*liczba_zadan])

# Ograniczenie - każde zadanie musi być przypisane do jednego eventu rozpoczęcia i zakończenia
for z in zadania
    @constraint(model, sum(x[z, e] for e in Events) == 1)
    @constraint(model, sum(y[z, e] for e in Events) == 1)
end

# Ograniczenie - czas nie maleje
for e in 1:(2*liczba_zadan-1)
    @constraint(model, t[e] <= t[e+1])
end

# Ograniczenie - pierwszy event musi być równy zeru
@constraint(model, t[1] == 0)