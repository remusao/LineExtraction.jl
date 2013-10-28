

type Setting
    img
    row::Int
    col::Int
end


function mod_fun(V)
    # Return new value `val` for pixel x, y
    elem = rand(2:(size(V, 1) - 2))

    v = 0
    if V[elem] == 0
        v = 255
    end

    return elem, v
end


function cost_fun(orig, new, v, pos, start)
    # Compute the local cost of the modification
    # Orig : the original image
    # new : the modified image
    # v : the candidate value for position `pos`
    # pos : position of the modification
    # start : hint about the start of the line given to the program

    row, col = start
    r, c = pos

    cost = 0
    beta = 10

    # We want the output image to be like the original
    cost += beta * abs(v - orig[r, c])
    cost += v * float(abs(row - r))
    #cost += v * (-2 * 255
    #    + new[r - 1, c]
    #    + new[r - 1, c - 1]
    #    + new[r - 1, c + 1]
    #    + new[r + 1, c + 1]
    #    + new[r + 1, c - 1]
    #    + new[r + 1, c]
    #    + new[r, c + 1]
    #    + new[r, c - 1])

    cost
end


function extract(file_path, row, col, out_path)

    println("extracting line from: $(file_path)")
    println("starting point: (row = $(row), col = $(col))")

    # Read input image to sparse matrix
    orig = sparse(convert(Array, imread(file_path)))
    rows, cols = size(orig)

    # Candidate
    obj = copy(orig)
    I, J, V = findnz(obj)


    # Initial random candidate
    nbelem = size(V, 1)
    for i = 1:nbelem
        V[i] = rand(0:1)
    end
    V *= 255


    ###########################
    # Run simulated annealing #
    ###########################


    # Simulated annealing settings
    t = 10.0
    t_step = 0.999
    t_stop = 1e-5
    max_epoc = 10000000
    epoc = 0


    println("Compute score matrix")

    score = zeros(Float64, nbelem)
    for i = 2:(nbelem - 1)
        score[i] = cost_fun(orig, obj, V[i], (I[i], J[i]), (row, col))
    end

    tot_score = sum(score)
    println("Total score: $(tot_score)")

    println("Run Simulated Annealing")

    while epoc < max_epoc && t > t_stop

        # Choose neighbor
        elem, v = mod_fun(V)
        r = I[elem]
        c = J[elem]

        # Compute local score
        score_mod = cost_fun(orig, obj, v, (r, c), (row, col))

        # Compute energy delta
        mod_e = score_mod - score[elem]

        # Keep the candidate or not
        if mod_e < 0 || rand() <= exp(-mod_e / t)
            V[elem] = v
            obj[r, c] = v
            tot_score = tot_score - score[elem] + score_mod
            score[elem] = score_mod
        end

        # Decrease temperature
        if epoc % 100 == 0
            t *= t_step
        end

        epoc += 1
        # println("Iteration number: $(epoc); e: $(mod_e); cost: $(tot_score), temp: $(t)")
    end

    println("epocs: $epoc")


    ###################
    # Display results #
    ###################

    obj *= 0.0005
    for i = 1:nbelem
        if V[i] == 255
            obj[I[i], J[i]] = 255
        end
    end

    # Display result
    display(convert(Image, dense(obj)))
    # imwrite(convert(Image, solution), out_path)
end
