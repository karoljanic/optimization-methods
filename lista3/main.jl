# Main script to run the scheduling on unrelated parallel machines problem
# Karol Janic

include("scheduling_on_unrelated_parallel_machines_approx.jl")


if length(ARGS) != 1
    println("Usage: julia main.jl <data_file>")
    exit(1)
else
    data_file = ARGS[1]
end

T, job_to_machine_assignment = run_schedule_unrelated_parallel_machines(data_file)
println("Makespan: ", T)
println("Job to machine assignment: ", job_to_machine_assignment)