# Scheduling on Unrelated Parallel Machines - 2-Approximation Algorithm
# Karol Janic

using JuMP
using HiGHS

function read_data(file)
    open(file, "r") do f
        jobs_num, machines_num, _ = parse.(Int, split(readline(f))) # first line - number of jobs and machines
        readline(f)                                                 # second line - number of machines (not used)

        # matrix of processing times for jobs on machines
        processing_times = zeros(Int, jobs_num, machines_num)                   
        for i in 1:jobs_num
            line = split(readline(f))
            for j in 1:machines_num
                processing_times[i, j] = parse(Int, line[2 * j])
            end
        end

        return jobs_num, machines_num, processing_times
    end
end

function greedy_schedule(jobs_num::Int, machines_num::Int, processing_times::Matrix{Int})
    # each job is assigned to the machine on which it has the smallest processing time
    total_times = zeros(Int, machines_num)  # stores the total processing time on each machine
    for i in 1:jobs_num
        min_time, min_time_machine_index = findmin(processing_times[i, :])
        total_times[min_time_machine_index] += min_time
    end

    return maximum(total_times)  # return the makespan of the greedy schedule
end

function create_lp_model(jobs_num::Int, machines_num::Int, processing_times::Matrix{Int}, T::Int)
    model = Model(HiGHS.Optimizer)
    set_silent(model)

    S_T_complement = [(i,j) for i in 1:jobs_num, j in 1:machines_num if processing_times[i, j] > T]
    S_T_i = [[j for j in 1:machines_num if processing_times[i, j] <= T] for i in 1:jobs_num]
    S_T_j = [[i for i in 1:jobs_num if processing_times[i, j] <= T] for j in 1:machines_num]

    # x[i, j] = 1 if job i is assigned to machine j, 0 otherwise
    @variable(model, x[1:jobs_num, 1:machines_num] >= 0) # relaxation to allow fractional assignments

    # use only the pairs (i, j) where processing time is less than or equal to T
    @constraint(model, [(i, j) in S_T_complement], x[i, j] == 0)

    # each job must be assigned to exactly one machine
    @constraint(model, [i in 1:jobs_num], sum(x[i, j] for j in S_T_i[i]) == 1)

    # total processing time on each machine j must not exceed T
    @constraint(model, [j in 1:machines_num], sum(processing_times[i, j] * x[i, j] for i in S_T_j[j]) <= T)

    # check only if model is feasible
    @objective(model, Min, 0)

    return model
end

function solve_model(model::Model)
    optimize!(model)
    is_feasible = termination_status(model) == OPTIMAL::TerminationStatusCode
    
    if is_feasible
        solution = value.(model[:x])

        eps = get_optimizer_attribute(model, "primal_feasibility_tolerance")
        solution = map(x -> abs(x - 1) < eps ? 1.0 : abs(x) < eps ? 0.0 : x, solution)

        return is_feasible, solution
    else
        return is_feasible, nothing
    end
end

function find_target_makespan(jobs_num::Int, machines_num::Int, processing_times::Matrix{Int})
    alpha = greedy_schedule(jobs_num, machines_num, processing_times)
    min_T = div(alpha, machines_num)
    max_T = alpha

    fisible_T = 0
    fisible_solution = nothing
    while min_T <= max_T
        T = div(min_T + max_T, 2)
        model = create_lp_model(jobs_num, machines_num, processing_times, T)
        is_feasible, solution = solve_model(model)
        if is_feasible
            fisible_T = T
            fisible_solution = solution

            max_T = T - 1
        else
            min_T = T + 1
        end
    end

    min_T_model = create_lp_model(jobs_num, machines_num, processing_times, min_T)
    min_T_is_feasible, min_T_solution = solve_model(min_T_model)
    if min_T_is_feasible
        fisible_T = min_T
        fisible_solution = min_T_solution
    end

    return fisible_T, fisible_solution
end

function resolve_fractional_assignments(jobs_num::Int, machines_num::Int, solution::Matrix{Float64})
    feasible_solution = copy(solution)

    # process leaves
    leaves_possible = true
    while leaves_possible
        leaves_possible = false
        for j in 1:machines_num
            # check if there is only one fractional assignment - leaf
            if count(x -> 0 < x < 1, feasible_solution[:, j]) == 1
                i = findfirst(x -> 0 < x < 1, feasible_solution[:, j])
                for k in 1:machines_num
                    if k != j
                        feasible_solution[i, k] = 0
                    else
                        feasible_solution[i, k] = 1
                    end
                end
                leaves_possible = true
            end
        end
    end

    # proces cycles - select alternate edges of each cycle
    for j in 1:machines_num    
        for i in 1:jobs_num
            if 0 < feasible_solution[i, j] < 1
                for k in 1:machines_num
                    if k != j
                        feasible_solution[i, k] = 0
                    else
                        feasible_solution[i, k] = 1
                    end
                end
            end
        end
    end

    return feasible_solution
end

function schedule_unrelated_parallel_machines(jobs_num::Int, machines_num::Int, processing_times::Matrix{Int})
    T, solution = find_target_makespan(jobs_num, machines_num, processing_times)
    feasible_solution = resolve_fractional_assignments(jobs_num, machines_num, solution)

    feasible_solution_T = maximum([sum(processing_times[i, j] * feasible_solution[i, j] for i in 1:jobs_num) for j in 1:machines_num])
    job_to_machine = [findfirst(x -> x > 0, feasible_solution[i, :]) for i in 1:jobs_num]

    return feasible_solution_T, job_to_machine
end

function run_schedule_unrelated_parallel_machines(data_file::String)
    jobs_num, machines_num, processing_times = read_data(data_file)
    T, job_to_machine_assignment = schedule_unrelated_parallel_machines(jobs_num, machines_num, processing_times)
    return T, job_to_machine_assignment
end
