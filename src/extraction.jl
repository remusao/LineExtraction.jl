

type Setting
    img
    row::Int
    col::Int
end


function mod_fun(img)
    # Return new value `val` for pixel x, y
    rows, cols = size(img)
    r = rand(2:rows - 2)
    c = rand(2:cols - 2)

    v = 0
    if img[r, c] == 0
        v = 1
    end

    return v, r, c
end


function cost_fun(s::Setting, img, r, c)

    cost = 0
    beta = 0.5

    # We want the output image to be like the original
    cost += abs(img[r, c] - s.img[r, c])

    # Minimize noise
    cost += beta * abs(img[r, c] - img[r - 1, c])
    cost += beta * abs(img[r, c] - img[r - 1, c - 1])
    cost += beta * abs(img[r, c] - img[r - 1, c + 1])
    cost += beta * abs(img[r, c] - img[r + 1, c + 1])
    cost += beta * abs(img[r, c] - img[r + 1, c - 1])
    cost += beta * abs(img[r, c] - img[r + 1, c])
    cost += beta * abs(img[r, c] - img[r, c + 1])
    cost += beta * abs(img[r, c] - img[r, c - 1])

    1 - cost
end


function extract(file_path, row, col, out_path)
    println("extracting line from: $(file_path)")
    println("starting point: (row = $(row), col = $(col))")

    # Read input image
    img = grayim(imread(file_path))
    arr = convert(Array, img)
    arr[arr .== 255] = 1
    rows, cols = size(arr)

    s = Setting(arr, row, col)
    sa = SA(15.0, 0.999, 1e-5, 1000000)

    function cost(img, r, c)
        return cost_fun(s, img, row, col)
    end

    solution = run(sa, rand(0:1, rows, cols), cost, mod_fun)

    # Write result to file
    solution[solution .== 1] = 255
    display(convert(Image, solution))
    # imwrite(convert(Image, solution), out_path)
end
