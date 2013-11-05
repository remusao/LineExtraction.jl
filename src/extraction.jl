

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
    start_index = arr[j, 3]         # We get the nearest index from the start point.
    # Randomly selecting a white pixel according to the normal distribution.
    rnd = randn()
    index = int(rnd * (nb_elt_on_col / 2) + start_index)
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
    beta = 20

    cost = 0
    # We score the distance between the start point and the pixel.
    if c > 1 && arr[c - 1, 1] == -1
        cost += alpha * abs(r - row)
    end
    # We score the distance between the previous marked pixel and the current
    # one, weighted with the square of root of the distance with the start
    # pixel. We want the relation between neighbors to be important, but we
    # also want to be close to the line to match.
    if c > 1 && arr[c - 1, 1] != -1
        cost += beta * abs(r - arr[c - 1, 1]) * (abs(r - row) + 1) ^ (1/2)
    end

    cost
end

function extract(file_path, row, col, out_path)

    println("extracting line from: $(file_path)")
    println("starting point: (row = $(row), col = $(col))")

    # Read input image to sparse matrix
    img = convert(Array, float64(imread(file_path)))
    img[row, col] = 255                       # In order to be sure there is at least one pixel on this column.
    orig = sparse(img)

    # Get number of rows and columns of the image.
    rows, cols = size(orig)

    # Candidate
    I, J, V = findnz(orig)
    arr = zeros(cols, 3)                      # arr contains the tuples (row, index, start_index) marked, one by column.
    row_map = map((x) -> I[J .== x], 1:cols)  # row_map contains the indexes of the white pixels.

    # Initial random candidate
    for j = 1:cols
        elts = row_map[j]                     # We get elements on j-th column.
        nb_elt_on_col = size(elts)[1]         # We get the number of elements.

        start_index = 0
        # If there isn't any white pixel on the column, we don't mark it.
        if (nb_elt_on_col == 0)
            i = -1
            index = -1
        else
            # We initialize with the nearest (row speaking) pixel from the
            # start pixel.
            start_index = max(size(row_map[j][row_map[j] .<= row], 1), 1)
            # Then we mark a random one, according to the normal distribution.
            rnd = randn()
            index = int(rnd * (nb_elt_on_col / 2) + start_index)
            index = max(index, 1)
            index = min(index, nb_elt_on_col)

            #index = start_index
            i = elts[index]
        end
        arr[j,:] = [i, index, start_index]    # We mark this pixel.
    end
    # Set start point.
    arr[col, 1] = row

    obj = sparse(I, J, V)

    ###########################
    # Run simulated annealing #
    ###########################


    # Simulated annealing settings
    t = 2500.0
    t_step = 0.999999
    t_stop = 5
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
    imwrite(img2, out_path)
end
