

type Setting
    img
    row::Int
    col::Int
end


function mod_fun(row_map, arr, col, scores)
    j = rand(1:size(arr)[1])        # We randomly choose a column.
    while arr[j, 1] == -1 || j == col
        j = rand(1:size(arr)[1])
    end
    elts = row_map[j]               # We get the elements on j-th column.
    nb_elt_on_col = size(elts)[1]   # We get the number of elements.
    start_index = arr[j, 3]
    rnd = randn()
    index = int(rnd * (10) + start_index)
    index = max(index, 1)
    index = min(index, nb_elt_on_col)
    #index = rand(1:nb_elt_on_col)
    i = elts[index]

    return (i,j,index)
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

    alpha = 1
    #beta = 12
    beta = 40

    cost = 0
    #cost += (abs(r - row) / 40) ^ 5
    #if  c > 1 && arr[c - 1, 1] != arr[c, 1]
    #    cost += abs(arr[c - 1, 1] - arr[c, 1])
    #end
    if c > 1 && arr[c - 1, 1] == -1
        cost += alpha * abs(r - row)
    end
    if c > 1 && arr[c - 1, 1] != -1
        cost += beta * abs(r - arr[c - 1, 1]) * (abs(r - row) + 1) ^ (1/2)
    end
    if c < size(arr,1) && arr[c + 1, 1] != -1
        cost += beta * abs(r - arr[c + 1, 1]) * (abs(r - row) + 1) ^ (1/2)
    end

    cost
end

function extract(file_path, row, col, out_path)

    println("extracting line from: $(file_path)")
    println("starting point: (row = $(row), col = $(col))")

    # Read input image to sparse matrix
    img = convert(Array, float64(imread(file_path)))
    img[row, col] = 255
    orig = sparse(img)
    rows, cols = size(orig)

    # Candidate
    I, J, V = findnz(orig)
    arr = zeros(cols, 3)
    row_map = map((x) -> I[J .== x], 1:cols)

    # Initial random candidate
    nbelem = size(V, 1)
    V *= 0
    for j = 1:cols
        elts = row_map[j]                    # We get elements on j-th column.
        nb_elt_on_col = size(elts)[1]   # We get the number of elements.
        start_index = 0
        if (nb_elt_on_col == 0)
            i = -1
            index = -1
        else
            start_index = max(size(row_map[j][row_map[j] .<= row], 1), 1)
            #rnd = randn()
            #index = int(rnd * (10) + start_index)
            #index = max(index, 1)
            #index = min(index, nb_elt_on_col)
            #println("start_index: $(start_index + 0), nb_elt: $nb_elt_on_col rnd: $rnd, index: $index")
            index = start_index
            i = elts[index]       # We randomly pick a pixel on this column.
        end
        arr[j,:] = [i, index, start_index]                      # We mark this pixel.
    end

    obj = sparse(I, J, V)

    ###########################
    # Run simulated annealing #
    ###########################


    # Simulated annealing settings
    t = 2500.0
    t_step = 0.99999
    t_stop = 1
    max_epoc = 10000000000
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
        r,c,index = mod_fun(row_map, arr, col, score)

        # Compute local score
        score_mod = cost_fun(orig, obj, arr, (r, c), (row, col))

        # Compute energy delta
        mod_e = score_mod - score[c]

        # Keep the candidate or not
        if mod_e < 0 || rand() <= exp(-mod_e / t)
            arr[c,:] = [r, index, arr[c,3]]
            tot_score = tot_score - score[c] + score_mod
            score[c] = score_mod
        end

        # Decrease temperature
        if epoc % 100 == 0
            t *= t_step
        end
        if epoc % 1000000 == 0
            println("Iteration number: $(epoc); e: $(mod_e); cost: $(tot_score), temp: $(t)")
        end

        epoc += 1
    end

    println("temperature: $t")
    println("energy: $tot_score")
    println("epocs: $epoc")


    ###################
    # Display results #
    ###################

    img *= 0.0005
    for i = 1:cols
        if (arr[i] != -1)
            r = int(arr[i])
            img[r, i] = 255
        end
    end

    # Display result
    img2 = convert(Image, img)
    display(img2)
    #imwrite(img2, out_path)
end
