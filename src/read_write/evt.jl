#######################################
#
# evt file
#
#######################################

"""
Read *.evt file and convert to form for EEG.jl
"""
function read_evt(fname::AbstractString, fs::Number; kwargs...)
    @info("Reading evt file: $fname")

    fs = ustrip(fs)

    d = readdlm(fname)

    @assert (size(d, 2) <= 3) "EVT file has too many columns"

    d = Dict(d[1,1] => d[2:end, 1], d[1,2] => d[2:end, 2], d[1,3] => d[2:end, 3])

    if haskey(d, "Tmu")
        d["Index"] = [1 + round.(i * (1 / 1000000) * float(fs)) for i in d["Tmu"]]
    elseif haskey(d, "Tsec")
        d["Index"] = [1 + round.(i  * float(fs)) for i in d["Tsec"]]
    else
        @warn("Unknown time scale in evt file")
    end

    d["Duration"] = ones(length(d["Code"]))

    @info("Imported $(length(d["Code"])) events")

    return Dict("Code" => d["Code"] .+ 252, "Index" => d["Index"], "Duration" => d["Duration"])
end
