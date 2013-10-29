

type Setting
    img
    row::Int
    col::Int
end


function mod_fun(I, J, arr)
    j = rand(1:size(arr)[1])        # We randomly choose a column.
    while arr[j] == -1
        j = rand(1:size(arr)[1])
    end
    elts = I[J .== j]               # We get the elements on j-th column.
    nb_elt_on_col = size(elts)[1]   # We get the number of elements.
    i = elts[rand(1:nb_elt_on_col)]       # We randomly pick a pixel on this column.

    return (i,j)
end


function cost_fun(orig, new, arr, pos, start)
    # Compute the local cost of the modification
    # Orig : the original image
    # new : the modified image
    # v : the candidate value for position `pos`
    # pos : position of the modification
    # start : hint about the start of the line given to the program

    rows, cols = size(new)
    row, col = start
    r, c = pos

    beta = 1
    cost = 0
    cost += abs(r - row)
    if (c > 1 && c < cols && arr[c - 1] != arr[c])
        cost += beta
    end

    cost
end


function extract(file_path, row, col, out_path)

    println("extracting line from: $(file_path)")
    println("starting point: (row = $(row), col = $(col))")

    # Read input image to sparse matrix
    orig = sparse(convert(Array, imread(file_path)))
    rows, cols = size(orig)

    # Candidate
    I, J, V = findnz(orig)
    arr = zeros(cols)

    # Initial random candidate
    nbelem = size(V, 1)
    V *= 0
    for j = 1:cols
        elts = I[J .== j]               # We get elements on j-th column.
        nb_elt_on_col = size(elts)[1]   # We get the number of elements.
        if (nb_elt_on_col == 0)
            i = -1
        else
            i = elts[rand(1:nb_elt_on_col)]       # We randomly pick a pixel on this column.
        end
        arr[j] = i                      # We mark this pixel.
    end

    obj = sparse(I, J, V)

    ###########################
    # Run simulated annealing #
    ###########################


    # Simulated annealing settings
    t = 25.0
    t_step = 0.999
    t_stop = 1e-4
    max_epoc = 1#0000000
    epoc = 0


    println("Compute score matrix")

    score = zeros(Float64, cols)
    for i = 1:cols
        score[i] = cost_fun(orig, obj, arr, (arr[i], i), (row, col))
    end

    tot_score = sum(score)
    println("Total score: $(tot_score)")

    println("Run Simulated Annealing")

    while epoc < max_epoc && t > t_stop

        # Choose neighbor
        r,c = mod_fun(I, J, arr)

        # Compute local score
        score_mod = cost_fun(orig, obj, arr, (r, c), (row, col))

        # Compute energy delta
        mod_e = score_mod - score[c]

        # Keep the candidate or not
        if mod_e < 0 || rand() <= exp(-mod_e / t)
            arr[c] = r
            tot_score = tot_score - score[c] + score_mod
            score[c] = score_mod
        end

        # Decrease temperature
        if epoc % 100 == 0
            t *= t_step
        end
        if epoc % 10000 == 0
            println("Iteration number: $(epoc); e: $(mod_e); cost: $(tot_score), temp: $(t)")
        end

        epoc += 1
    end

    println("energy: $tot_score")
    println("epocs: $epoc")


    ###################
    # Display results #
    ###################

    orig *= 0.0005
    for i = 1:cols
        if (arr[i] != -1)
            r = int(arr[i])
            orig[r, i] = 255
        end
    end

    # Display result
    display(convert(Image, dense(orig)))
    #imwrite(convert(Image, orig), out_path)
end
