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
    T, _ = run_schedule_unrelated_parallel_machines(data_file)
    return T
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
        xlabel="Indeks testu",
        ylabel="Współczynnik aproksymacji", 
        legend=false, 
        xticks=1:100:length(x)+1,
        grid=false
    )

    hline!([2], color=:green, lw=2, linestyle=:dashdot)
    
    savefig("approximation_ratio_plot.png")
end


# testcases = read_testcases("test_data.json")

# approx = Float64[]
# optimal = Float64[]
# for (test_data, solution_data) in testcases
#     println("Processing test case: ", test_data)
#     approx_makespan = run_aproximation(test_data)
#     optimal_makespan = get_optimal_makespan(solution_data)

#     println(approx_makespan, " vs ", optimal_makespan, " -> ", approx_makespan / optimal_makespan)
#     if approx_makespan / optimal_makespan > 2
#         println("Warning: Approximation ratio exceeds 2 for test case: ", test_data)
#     end
    
#     push!(approx, approx_makespan)
#     push!(optimal, optimal_makespan)
# end

# @save "results.jld2" testcases approx optimal

@load "results.jld2" testcases approx optimal

testcase_names = [replace(replace(testcase[1], "RCmax/" => ""), ".txt" => "")  for testcase in testcases]
plot_results(testcase_names, approx, optimal)