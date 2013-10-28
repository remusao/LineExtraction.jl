
type SA
    t_init::Float64
    t_step::Float64
    t_stop::Float64
    max_epoc::Int
end


function run(sa::SA, init, cost_fun, mod_fun)

    t = sa.t_init

    # Initial state
    obj = init
    obj_mod = copy(obj)

    # Sizes
    rows, cols = size(obj)

    println("Compute score matrix")
    score = zeros(Float64, rows, cols)

    for i = 2:(rows - 1), j = 2:(cols - 1)
        score[i, j] = cost_fun(obj, i, j)
    end

    println("compute total score")
    tot_score = sum(score)

    println("Run Simulated Annealing")
    epoc = 0

    while t > sa.t_stop
        # Choose neighbor
        v, r, c = mod_fun(obj_mod)

        score_mod = cost_fun(obj_mod, r, c)

        # Compute energy delta
        mod_e = score_mod - score[r, c]

        # Keep the candidate or not
        if mod_e <= 0 || rand() < exp(-mod_e / t)
            obj_mod[r, c] = v
            tot_score = tot_score - score[r, c] + score_mod
        end

        if epoc % 100 == 0
            t *= sa.t_step
        end

        epoc += 1
        # println("Iteration number: $(epoc); e: $(mod_e); cost: $(tot_score), temp: $(t)")
    end

    return obj_mod
end
