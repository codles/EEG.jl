# Trigger information is stored in a dictionary
# containing three fields, all referenced in samples.
# Index:    Start of trigger
# Code:     Code of trigger
# Duration: Duration of trigger


#######################################
#
# Validate trigger channel
#
#######################################

function validate_triggers(t::Dict; kwargs...)

    info("Validating trigger information")

    if t.count > 3
        err("Trigger channel has extra columns")
    end

    if !haskey(t, "Index")
        critical("Trigger channel does not contain index information")
    end

    if !haskey(t, "Code")
        critical("Trigger channel does not contain code information")
    end

    if !haskey(t, "Duration")
        critical("Trigger channel does not contain duration information")
    end

    if length(t["Index"]) !== length(t["Code"]) && length(t["Index"]) !== length(t["Duration"])
        critical("Trigger data lengths are different")
    end
end


#######################################
#
# Clean trigger channel
#
#######################################

function clean_triggers(t::Dict; valid_indices::Array{Int}=[1, 2],
                        min_epoch_length::Int=0, max_epoch_length::Number=Inf,
                        remove_first::Int=0,     max_epochs::Number=Inf, kwargs...)

    info("Cleaning triggers")

    validate_triggers(t)

    # Make in to data frame for easy management
    epochIndex = DataFrame(Code = t["Code"], Index = t["Index"], Duration = t["Duration"]);
    epochIndex[:Code] = epochIndex[:Code] - 252

    # Check for not valid indices and throw a warning
    if sum([in(i, [0, valid_indices]) for i = epochIndex[:Code]]) != length(epochIndex[:Code])
        non_valid = !convert(Array{Bool}, [in(i, [0, valid_indices]) for i = epochIndex[:Code]])
        non_valid = sort(unique(epochIndex[:Code][non_valid]))
        warn("File contains non valid triggers: $non_valid")
    end
    # Just take valid indices
    valid = convert(Array{Bool}, vec([in(i, valid_indices) for i = epochIndex[:Code]]))
    epochIndex = epochIndex[ valid , : ]

    # Trim values if requested
    if remove_first > 0
        epochIndex = epochIndex[remove_first+1:end,:]
        info("Trimming first $remove_first triggers")
    end
    if max_epochs < Inf
        epochIndex = epochIndex[1:minimum([max_epochs, length(epochIndex[:Index])]),:]
        info("Trimming to $max_epochs triggers")
    end

    # Throw out epochs that are the wrong length
    if length(epochIndex[:Index]) > 2
        epochIndex[:Length] = [0, diff(epochIndex[:Index])]
        if min_epoch_length > 0
            epochIndex[:valid_length] = epochIndex[:Length] .> min_epoch_length
            num_non_valid = sum(!epochIndex[:valid_length])
            if num_non_valid > 1    # Don't count the first trigger
                warn("Removed $num_non_valid triggers < length $min_epoch_length")
                epochIndex = epochIndex[epochIndex[:valid_length], :]
            end
        end
        epochIndex[:Length] = [0, diff(epochIndex[:Index])]
        if max_epoch_length < Inf
            epochIndex[:valid_length] = epochIndex[:Length] .< max_epoch_length
            num_non_valid = sum(!epochIndex[:valid_length])
            if num_non_valid > 0
                warn("Removed $num_non_valid triggers > length $max_epoch_length")
                epochIndex = epochIndex[epochIndex[:valid_length], :]
            end
        end

        # Sanity check
        if std(epochIndex[:Length][2:end]) > 1
            warn("Your epoch lengths vary too much")
            warn(string("Length: median=$(median(epochIndex[:Length][2:end])) sd=$(std(epochIndex[:Length][2:end])) ",
                  "min=$(minimum(epochIndex[:Length][2:end]))"))
            debug(epochIndex)
        end

    end

    triggers = ["Index" => vec(int(epochIndex[:Index])'), "Code" => vec(epochIndex[:Code] .+ 252),
                "Duration" => vec(epochIndex[:Duration])']

    validate_triggers(triggers)

    return triggers
end

