"""
Return a new processing key with the number incremented.  
It checks for existing keys and returns a string with the next key to be used.

#### Arguments

* `d`: Dictionary containing existing keys
* `key_name`: Base of the

#### Returns

* AbstractString with new key name

#### Returns

```julia
results_storage = Dict()
results_storage[new_processing_key(results_storage, "FTest")] = 4
results_storage[new_processing_key(results_storage, "FTest")] = 49

# Dict(Any, Any) with 2 entries
#   "FTest1" => 4
#   "FTest2" => 49
```
"""
function new_processing_key(d::Dict, key_name::AbstractString)
    key_numb = 1
    key = string(key_name, key_numb)
    while haskey(d, key)
        key_numb += 1
        key = string(key_name, key_numb)
    end
    return key
end


"""
Find dictionary keys containing a string.

#### Arguments

* `d`: Dictionary containing existing keys
* `partial_key`: AbstractString you want to find in key names

#### Returns

* Array containg the indices of dictionary containing the partial_key

#### Returns

```julia
results_storage = Dict()
results_storage[new_processing_key(results_storage, "FTest")] = 4
results_storage[new_processing_key(results_storage, "Turtle")] = 5
results_storage[new_processing_key(results_storage, "FTest")] = 49

find_keys_containing(results_storage, "FTest")

# 2-element Array{Int64,1}:
#  1
#  3
```
"""
function find_keys_containing(d::Dict, partial_key::AbstractString)
    valid_keys = [startswith(i, partial_key) for i = collect(keys(d))]
    findall((in)(true), valid_keys)
end


"""
Extract the path, filename and extension of a file

#### Arguments

* `fname`: AbstractString with the full path to a file

#### Output

* Three strings containing the path, file name and file extension

#### Returns

```julia
fileparts("/Users/test/subdir/test-file.bdf")

# ("/Users/test/subdir/","test-file","bdf")
```
"""
function fileparts(fname::AbstractString)
    if fname==""
        pathname  = ""
        filename  = ""
        extension = ""
    else

        pathname = dirname(fname)
        if pathname == ""
            #nothing
        else
            pathname = string(pathname, "/")
        end
        filename = splitext(basename(fname))[1]
        extension = splitext(basename(fname))[2][2:end]
    end

    return pathname, filename, extension
end


"""
Find the closest number to a target in an array and return the index

#### Arguments

* `list`: Array containing numbers
* `target`: Number to find closest to in the list

#### Output

* Index of the closest number to the target

#### Returns

```julia
_find_closest_number_idx([1, 2, 2.7, 3.2, 4, 3.1, 7], 3)

# 6
```
"""
function _find_closest_number_idx(list::AbstractArray{T, 1}, target::Number) where T <: Number
    diff_array = abs.(list .- target)
    targetIdx  = something(findfirst(isequal(minimum(diff_array)), diff_array), 0)
end


#######################################
#
# DataFrame manipulation
#
#######################################

function add_dataframe_static_rows(a::DataFrame, args...)
    @debug("Adding column(s)")
    for kwargs in args
        @debug(kwargs)
        for k in kwargs
            name = Symbol(k[1])
            code = k[2]
            expanded_code = vec(repmat([k[2]], size(a, 1), 1))
            @debug("Name: $name  Code: $code")
            DataFrames.insert_single_column!(a, expanded_code, size(a,2)+1)
            rename!(a, Symbol(string("x", size(a,2))) =>  name)
        end
    end
    return a
end
