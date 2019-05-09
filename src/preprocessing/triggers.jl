# Trigger information is stored in a dictionary
# containing three fields, all referenced in samples.
# Index:    Start of trigger
# Code:     Code of trigger
# Duration: Duration of trigger


"""
Validate trigger channel
"""
function validate_triggers(t::Dict)

    @debug("Validating trigger information")

    if t.count > 3
        @error("Trigger channel has extra columns")
    end

    if !haskey(t, "Index")
        throw(KeyError("Trigger channel does not contain index information"))
    end

    if !haskey(t, "Code")
        throw(KeyError("Trigger channel does not contain code information"))
    end

    if !haskey(t, "Duration")
        throw(KeyError("Trigger channel does not contain duration information"))
    end

    if length(t["Index"]) !== length(t["Duration"])
        throw(KeyError("Trigger index and duration lengths are different"))
    end

    if length(t["Index"]) !== length(t["Code"])
        throw(KeyError("Trigger index and code lengths are different"))
    end
end


"""
Clean trigger channel
""" 
function clean_triggers(t::Dict, valid_triggers::Array{Int}, min_epoch_length::Int, max_epoch_length::Int,
                        remove_first::Int, max_epochs::Int)

    @debug("Cleaning triggers")

    # Ensure the passed in dictionary contains all required fields
    validate_triggers(t)

    # Make in to data frame for easy management
    epochIndex = DataFrame(Code = t["Code"] -252, Index = t["Index"], Duration = t["Duration"])

    # Present information about triggers before processing
    @debug("Original trigger codes $(unique(epochIndex[:Code]))")
    @debug("Originally $(length(epochIndex[:Code])) triggers")

    # Check for not valid indices and throw a warning
    if sum([in(i, [0; valid_triggers]) for i = epochIndex[:Code]]) != length(epochIndex[:Code])
        @warn("Non valid triggers found")
        validity = Bool[]
        for ep in epochIndex[:Code]
            push!(validity, in(ep, valid_triggers))
        end
        non_valid = sort(unique(epochIndex[:Code][.!validity]))
        @warn("Non valid triggers: $non_valid")
    end

    # Just take valid indices
    valid = convert(Array{Bool}, vec([in(i, valid_triggers) for i = epochIndex[:Code]]))
    epochIndex = epochIndex[ valid , : ]

    # Trim values if requested
    if remove_first > 0
        epochIndex = epochIndex[remove_first+1:end,:]
        @debug("Trimming first $remove_first triggers")
    end
    if max_epochs != 0
        epochIndex = epochIndex[1:minimum([max_epochs, length(epochIndex[:Index])]),:]
        @debug("Trimming to $max_epochs triggers")
    end

    # Throw out epochs that are the wrong length
    if length(epochIndex[:Index]) > 2
        epochIndex[:Length] = [0; diff(epochIndex[:Index])]
        if min_epoch_length > 0
            epochIndex[:valid_length] = epochIndex[:Length] .> min_epoch_length
            num_non_valid = sum(.!epochIndex[:valid_length])
            if num_non_valid > 1    # Don't count the first trigger
                @debug("Removed $num_non_valid triggers < length $min_epoch_length")
                epochIndex = epochIndex[epochIndex[:valid_length], :]
            end
        end
        epochIndex[:Length] = [0; diff(epochIndex[:Index])]
        if max_epoch_length != 0
            epochIndex[:valid_length] = epochIndex[:Length] .< max_epoch_length
            num_non_valid = sum(.!epochIndex[:valid_length])
            if num_non_valid > 0
              @debug("Removed $num_non_valid triggers > length $max_epoch_length")
                epochIndex = epochIndex[epochIndex[:valid_length], :]
            end
        end

        # Sanity check
        if std(epochIndex[:Length][2:end]) > 1
            @warn("Your epoch lengths vary too much")
            @warn(string("Length: median=$(median(epochIndex[:Length][2:end])) sd=$(std(epochIndex[:Length][2:end])) ",
                  "min=$(minimum(epochIndex[:Length][2:end]))"))
            @debug(epochIndex)
        end

    end

    # If the trigger has been signalled by 0 status then offset this
    # Otherwise when saving and reading again, nothing will be detected
    if sum(epochIndex[:Code]) == 0
        @warn("Trigger status indicated by 0, shifting to 1 for further processing")
        epochIndex[:Code] = epochIndex[:Code] .+ 1
    end

    triggers = Dict("Index" => vec((epochIndex[:Index])'), "Code" => vec(epochIndex[:Code] .+ 252),
                "Duration" => vec(epochIndex[:Duration])')

    validate_triggers(triggers)

    return triggers
end


"""
Place extra triggers a set time after existing triggers.

A new trigger with `new_trigger_code` will be placed `new_trigger_time` seconds after exisiting `old_trigger_code` triggers.
"""
function extra_triggers(t::Dict, old_trigger_code::Union{Int, Array{Int}},
                        new_trigger_code::Int, new_trigger_time::Number, fs::Number;
                        trigger_code_offset::Int=252, max_inserted::Number=Inf)

    # Scan through existing triggers, when you find one that has been specified to trip on
    # then add a new trigger at a set time after the trip

    # Calculate the delay in samples. This may not be an integer number.
    # Don't round here as you will get drifting
    new_trigger_delay = new_trigger_time*fs

    # Find triggers we want to trip on
    valid_trip       = any(t["Code"]-trigger_code_offset .== old_trigger_code', dims = 2)
    valid_trip_idx   = findall(valid_trip)
    valid_trip_index = [t["Index"][valid_trip_idx]; 0]  # Place a 0 at end so we dont use the last epoch
    valid_trip_code  = t["Code"][valid_trip_idx]

    @debug("Found $(length(valid_trip_code)) exisiting valid triggers")
    @debug("Adding new trigger $new_trigger_code after $new_trigger_time (s) = $new_trigger_delay (samples) from $old_trigger_code")

    validate_triggers(t)

    code  = Int[]
    index = Int[]

    vt = 0 # Count which valid index we are up to

    for i in 1:length(t["Index"])-1

        push!(code, t["Code"][i]-trigger_code_offset)
        push!(index, t["Index"][i])

        if valid_trip[i]

            offset = t["Index"][i] + new_trigger_delay
            counter = 0
            vt += 1

            while offset < valid_trip_index[vt+1] && counter < max_inserted

                push!(code, new_trigger_code)
                push!(index, Int(round.(offset)))  # Round and take integer here to minimise the drift

                offset  += new_trigger_delay
                counter += 1

            end
        end
    end

    # Ensure triggers are sorted
    v = sortperm(index)
    index = index[v]
    code  = code[v]

    # if there are any two triggers directly on top of each other then remove them
    valid_idx = [true; diff(index) .!= 0]
    index = index[valid_idx]
    code = code[valid_idx]

    triggers = Dict("Index" => vec((index)'), "Code" => vec(code .+ trigger_code_offset),
                "Duration" => vec([0; diff(index)])')

    validate_triggers(triggers)

    return triggers
end
