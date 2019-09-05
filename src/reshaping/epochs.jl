
#######################################
#
# Extract epochs
#
#######################################

"""
Extract epoch data from array of channels.

#### Input

* Array of raw data. Samples x Channels
* Dictionary of trigger information
* Vector of valid trigger numbers
* Number of first triggers to remove
* Number of end triggers to remove

#### Example

```julia
epochs = extract_epochs(data, triggers, [1,2], 0, 0)
```
"""
function extract_epochs(data::Array{T, 2}, triggers::Dict, valid_triggers::Union{AbstractVector, Int},
    remove_first::Int, remove_last::Int, trigger_offset::Int = 252) where T <: Number

    @debug("Extracting epochs for $(size(data)[end]) channels using triggers $(valid_triggers)")

    validate_triggers(triggers)

    newTidx = [Int(i) for i in triggers["Index"]]

    triggers = DataFrame(Code = triggers["Code"], Index = newTidx)
    # TODO Use convert function
    #=triggers = convert(DataFrame, triggers)=#

    # Change offset so numbers are manageable
    triggers[:Code] = triggers[:Code] - trigger_offset

    # Determine indices of triggers which are valid
    valid_triggers = any(triggers[:Code] .== valid_triggers',  dims = 2)[:, 1]

    @debug("Number of valid triggers: $(length(valid_triggers))")

    # Remove unwanted triggers
    triggers = triggers[valid_triggers, :]                # That aren't valid
    triggers = triggers[remove_first+1:end-remove_last,:] # Often the first trigger is rubbish

    lenEpochs = minimum(diff(triggers[:Index]))
    numChans  = size(data)[end]

    # Check we aren't looking past the end of the data
    start_indices = convert(Array{Int}, triggers[:Index])
    end_indices   = convert(Array{Int}, start_indices + lenEpochs - 1)
    while end_indices[end] > size(data, 1)
        pop!(start_indices)
        pop!(end_indices)
        @debug("Removed end epoch as its not complete")
    end

    # Create variable for epochs
    numEpochs = length(start_indices)
    epochs = zeros(Float64, (Int(lenEpochs), Int(numEpochs), Int(numChans)))

    # User feedback
    @debug("Creating epochs: $lenEpochs x $numEpochs x $numChans")

    for si = 1:length(start_indices)
        epochs[:, si, :] = data[start_indices[si]: end_indices[si], :]
    end

    @info("Generated $numEpochs epochs of length $lenEpochs for $numChans channels")

    return epochs
end


#######################################
#
# Create average epochs
#
#######################################

function average_epochs(ep::Array)

    @info("Averaging down epochs to 1 epoch of length $(size(ep,1)) from $(size(ep,2)) epochs on $(size(ep,3)) channels")

    dropdims(mean(ep, dims = 2), dims = 2)
end
