# Testing scheduling_on_unrelated_parallel_machines_approx.jl
# Karol Janic

using JSON
using Plots
using JLD2

include("scheduling_on_unrelated_parallel_machines_approx.jl")


function read_testcases(config_file::String)
    data = JSON.parsefile(config_file)
    test_series = data["test_series"]
    
    testcases = Tuple{String, String}[]
    for series in test_series
        data_directory = series["data_directory"]
        solution_directory = series["solution_directory"]
        solution_filename = series["solution_filename"]
        filenames = readdir(data_directory)
        for filename in filenames
            index = split(filename, ".")[1]
            solution_file = replace(solution_filename, "{index}" => index)
            testcases = push!(testcases, (joinpath(data_directory, filename), joinpath(solution_directory, solution_file)))
        end
    end

    return testcases
end

function run_aproximation(data_file::String)
    T, _, frac_perc, int_perc = run_schedule_unrelated_parallel_machines(data_file)
    return T, frac_perc, int_perc
end

function get_optimal_makespan(solution_file::String)
    open(solution_file, "r") do file
        for line in eachline(file)
            if startswith(line, "Cmax")
                return parse(Float64, split(line)[2])
            end
        end
    end
end

function plot_results(x::Vector{String}, y1::Vector{Float64}, y2::Vector{Float64})
    ratio = y1 ./ y2
    
    plot(x, ratio, 
        seriestype = :scatter,
        title="Współczynnik aproksymacji",
        xlabel="indeks instancji",
        ylabel="współczynnik\naproksymacji", 
        legend=false, 
        xticks=1:100:length(x)+1,
        grid=false,
        markersize = 3,
    )

    hline!([2], color=:green, lw=2, linestyle=:dashdot)
    
    savefig("approximation_ratio_plot.png")
end

function analyze_max_min_mean(approx::Vector{Float64}, optimal::Vector{Float64}, testcases::Vector{Tuple{String, String}})
    min_ratios = Dict{String, Float64}()
    max_ratios = Dict{String, Float64}()
    sum_ratios = Dict{String, Float64}()
    counts = Dict{String, Int}()
    for (i, (a, o, (a_dir, o_dir))) in enumerate(zip(approx, optimal, testcases))
        instance_group = split(a_dir, "/")[2]
        ratio = a / o
        if !haskey(min_ratios, instance_group)
            min_ratios[instance_group] = ratio
            max_ratios[instance_group] = ratio
            sum_ratios[instance_group] = ratio
            counts[instance_group] = 1
        else
            min_ratios[instance_group] = min(min_ratios[instance_group], ratio)
            max_ratios[instance_group] = max(max_ratios[instance_group], ratio)
            sum_ratios[instance_group] += ratio
            counts[instance_group] += 1
        end
    end

    println("Analysis of approximation ratios:")
    for group in keys(min_ratios)
        min_ratio = min_ratios[group]
        max_ratio = max_ratios[group]
        mean_ratio = sum_ratios[group] / counts[group]
        println("Group: $group\nMin: $min_ratio\nMax: $max_ratio\nMean: $mean_ratio\n")
    end
end

function analyze_groups(testcases::Vector{Tuple{String, String}}, approx::Vector{Float64}, optimal::Vector{Float64}, fractionals::Vector{Float64}, integrals::Vector{Float64})
    groups = Dict{String, Tuple{Vector{String}, Vector{Float64}, Vector{Float64}, Vector{Float64}, Vector{Float64}}}()
    for (_, (testcase, a, o, f, i)) in enumerate(zip(testcases, approx, optimal, fractionals, integrals))
        group = split(testcase[1], "/")[2]
        if !haskey(groups, group)
            groups[group] = ([testcase[1]], [a], [o], [f], [i])
        else
            push!(groups[group][1], testcase[1])
            push!(groups[group][2], a)
            push!(groups[group][3], o)
            push!(groups[group][4], f)
            push!(groups[group][5], i)
        end
    end

    # create plot data
    for (group, (names, approx_values, optimal_values, fractional_values, integral_values)) in groups
        sizes = [parse(Int, match(r"/(\d+)\.txt$", str).captures[1]) for str in names]
        ratios = approx_values ./ optimal_values

        p1 = plot(sizes, ratios,
            seriestype = :scatter,
            title = "Wyniki dla grupy $group",
            ylabel = "współczynnik\naproksymacji",
            legend = false,
            grid = false,
            markersize = 3
        )
        p2 = plot(sizes, fractional_values,
            seriestype = :scatter,
            ylabel = "procent ułamkowych\nprzydziałów",
            xlabel = "rozmiar instancji",
            legend = false,
            grid = false,
            markersize = 3
        )

        plot(p1, p2, layout = @layout([a; b]), size=(700, 500))
        savefig("approximation_ratio_group_$group.png")
    end
end


# testcases = read_testcases("test_data.json")

# approx = Float64[]
# optimal = Float64[]
# fractionals = Float64[]
# integrals = Float64[]
# for (test_data, solution_data) in testcases
#     println("Processing test case: ", test_data)
#     approx_makespan, frac_perc, int_perc = run_aproximation(test_data)
#     optimal_makespan = get_optimal_makespan(solution_data)

#     println(approx_makespan, " vs ", optimal_makespan, " -> ", approx_makespan / optimal_makespan)
#     if approx_makespan / optimal_makespan > 2
#         println("Warning: Approximation ratio exceeds 2 for test case: ", test_data)
#     end
    
#     push!(approx, approx_makespan)
#     push!(optimal, optimal_makespan)
#     push!(fractionals, frac_perc)
#     push!(integrals, int_perc)
# end

# @save "results.jld2" testcases approx optimal fractionals integrals

@load "results.jld2" testcases approx optimal fractionals integrals

testcase_names = [replace(replace(testcase[1], "RCmax/" => ""), ".txt" => "")  for testcase in testcases]
plot_results(testcase_names, approx, optimal)
analyze_max_min_mean(approx, optimal, testcases)
analyze_groups(testcases, approx, optimal, fractionals, integrals)