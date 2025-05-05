# Tartak - problem cięcia desek
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
szerokosc_deski::Int = dane["szerokosc-deski"]
zadane_szerokosci::Vector{Int} = [z["szerokosc"] for z in dane["zapotrzebowanie"]]
zadane_ilosci::Dict{Int, Int} = Dict(
    z["szerokosc"] => z["liczba"] for z in dane["zapotrzebowanie"]
)

println("Szerokość deski: ", szerokosc_deski)
println("Zadane szerokości: ", zadane_szerokosci)
println("Zadane ilości: ", zadane_ilosci)

# Preprocessing - wygenerowanie wszystkich możliwych cięć
function generuj_ciecia(calkowita_szerokosc::Int, skladowe_szerokosci::Vector{Int})::Vector{Dict{Int, Int}}
    ciecia::Vector{Vector{Int}} = Vector{Vector{Int}}()
    
    minimalna_szerokosc = minimum(skladowe_szerokosci)
    liczba_skladowych = length(skladowe_szerokosci)
    function backtrack(aktualne_ciecie::Vector{Int}, pozostala_szerokosc::Int, minimalna_pozycja::Int) # minimalna_pozycja to indeks minimalnej szerokości; zapobiega to powtórzeniom cięć
        if pozostala_szerokosc < minimalna_szerokosc || minimalna_pozycja > liczba_skladowych
            push!(ciecia, copy(aktualne_ciecie))
            return
        end

        for pozycja in minimalna_pozycja:liczba_skladowych
            if pozostala_szerokosc >= skladowe_szerokosci[pozycja]
                push!(aktualne_ciecie, skladowe_szerokosci[pozycja])
                backtrack(aktualne_ciecie, pozostala_szerokosc - skladowe_szerokosci[pozycja], pozycja)
                pop!(aktualne_ciecie)
            end
        end
    end

    aktualne_ciecie = Vector{Int}()
    backtrack(aktualne_ciecie, calkowita_szerokosc, 1)

    ciecia_jako_slowniki = Vector{Dict{Int, Int}}()
    for ciecie in ciecia
        push!(ciecia_jako_slowniki, Dict{Int, Int}())
        for szerokosc in zadane_szerokosci
            ciecia_jako_slowniki[end][szerokosc] = 0
        end
        for szerokosc in ciecie
            ciecia_jako_slowniki[end][szerokosc] += 1
        end
    end

    return ciecia_jako_slowniki
end

mozliwe_ciecia = generuj_ciecia(szerokosc_deski, zadane_szerokosci)
odpady = [szerokosc_deski - sum(ciecie[szerokosc] * szerokosc for szerokosc in keys(ciecie)) for ciecie in mozliwe_ciecia]
liczba_mozliwych_ciec = length(mozliwe_ciecia)
println("\nMożliwe cięcia: ")
for ciecie in mozliwe_ciecia
    for szerokosc in zadane_szerokosci
        print(ciecie[szerokosc], "x", szerokosc, "; ")
    end
    println("odpad: ", szerokosc_deski - sum(ciecie[szerokosc] * szerokosc for szerokosc in keys(ciecie)))
end


# Modelowanie problemu
model = Model(GLPK.Optimizer)

# Zmienne decyzyjne - liczba desek dla każdego rodzaju cięcia
@variable(model, x[1:liczba_mozliwych_ciec] >= 0, Int)

# Funkcja celu - minimalizacja liczby odpadów
@objective(model, Min, sum(odpady[i] * x[i] for i in 1:liczba_mozliwych_ciec))

# Ograniczenia - zapotrzebowanie na deski
for szerokosc in zadane_szerokosci
    @constraint(model, sum(mozliwe_ciecia[i][szerokosc] * x[i] for i in 1:liczba_mozliwych_ciec) >= zadane_ilosci[szerokosc])
end


# Uruchomienie modelu
optimize!(model)

# Rozwiązanie
if termination_status(model) == MOI.OPTIMAL
    println("\nZnaleziono optymalne rozwiązanie:")
    for i in 1:liczba_mozliwych_ciec
        if value(x[i]) > 0
            println("Cięcie: ", mozliwe_ciecia[i], " -> ", value(x[i]), " sztuk")
        end
    end
    println("Suma odpadów: ", objective_value(model))
else
    println("Nie znaleziono optymalnego rozwiązania.")
end
