# Planowanie produkcji na jednej maszynie z uwzględnieniem gotowości zadań
# Karol Janic

using JSON
using JuMP
using GLPK


# Wczytanie danych
if length(ARGS) != 1
    println("Użycie: julia model.jl <plik-danych.json>")
    exit(1)
else
    plik_danych = ARGS[1]
end

dane = JSON.parsefile(plik_danych)
zadania::Vector{Int} = [z["numer"] for z in dane["zadania"]]
czasy_zadan::Dict{Int, Int} = Dict(
    z["numer"] => z["czas"] for z in dane["zadania"]
)
wagi_zadan::Dict{Int, Int} = Dict(
    z["numer"] => z["waga"] for z in dane["zadania"]
)
gotowosci_zadan::Dict{Int, Int} = Dict(
    z["numer"] => z["gotowosc"] for z in dane["zadania"]
)

println("Zadania: ", zadania)
println("Czasy zadań: ", czasy_zadan)
println("Wagi zadań: ", wagi_zadan)
println("Gotowości zadań: ", gotowosci_zadan)

M::Int = maximum(values(gotowosci_zadan)) + sum(values(czasy_zadan)) + 1


# Modelowanie problemu
model = Model(GLPK.Optimizer)

# Zmienne decyzyjne - czas rozpoczęcia każdego zadania
@variable(model, x[z in zadania] >= 0)

# Zmienne decyzyjne - kolejność zadań
@variable(model, y[z1 in zadania, z2 in zadania], Bin)

# Funkcja celu - minimalizacja maksymalnego czasu zakończenia z uwzględnieniem wag
@objective(model, Min, sum(wagi_zadan[z] * (x[z] + czasy_zadan[z]) for z in zadania))

# Ograniczenie - zadanie nie może być rozpoczęte przed jego gotowością
for z in zadania
    @constraint(model, x[z] >= gotowosci_zadan[z])
end

# Ograniczenie - zachowanie spójności kolejności zadań
for z1 in zadania
    for z2 in zadania
        if z1 == z2
            @constraint(model, y[z1, z2] == 0)
        elseif z1 < z2
            @constraint(model, y[z1, z2] + y[z2, z1] == 1)
        end
    end
end

# Ograniczenie - zadanie nie może być rozpoczęte przed zakończeniem poprzedniego
for z1 in zadania
    for z2 in zadania
        if z1 < z2
            @constraint(model, x[z1] + czasy_zadan[z1] <= x[z2] + M * (1 - y[z1, z2]))
            @constraint(model, x[z2] + czasy_zadan[z2] <= x[z1] + M * y[z1, z2])
        end
    end
end


# Uruchomienie modelu
optimize!(model)

# Rozwiązanie
if termination_status(model) == MOI.OPTIMAL
    println("\nZnaleziono optymalne rozwiązanie:")
    for z in zadania
        println("Zadanie ", z, ": rozpoczęcie w czasie ", value(x[z]), ", zakończenie w czasie ", value(x[z]) + czasy_zadan[z])
    end
    println("Koszt całkowity: ", objective_value(model))
else
    println("Nie znaleziono optymalnego rozwiązania.")
end
