#######################################
#
# BDF file
#
#######################################

"""
Import Biosemi files
"""
function import_biosemi(fname::Union{AbstractString, IO}; kwargs...)

    @info("Importing BIOSEMI data file")

    # Read raw data using BDF.jl
    data, triggers, trigger_channel, system_code_channel = readBDF(identity(fname), transposeData=true; kwargs...)
    header = readBDFHeader(identity(fname))

    # Check the sample rate
    sample_rate = header["sampRate"]
    if sum(diff(sample_rate)) != 0
        @warn("Sampling rate varies across channels")
        sample_rate = NaN
    else
        sample_rate = sample_rate[1]
    end

    reference_channel = "Raw"

    # Tidy the trigger channel to standard names
    triggers = Dict("Code"     => triggers["code"],
                "Index"    => triggers["idx"],
                "Duration" => triggers["dur"])

    # Tidy channel names if required
    if any(header["chanLabels"] .== "B16")  # Cz is usually present
        @debug("  Converting names from BIOSEMI to 10-20")
        header["chanLabels"] = channelNames_biosemi_1020(header["chanLabels"])
    end

    system_codes = create_events(system_code_channel, sample_rate)

    return  data, triggers, system_codes, sample_rate, reference_channel, header
end

# Create events from channel
############################

function create_events(channel::Array{Int16,1}, fs::Number)

    startPoints = vcat(1, findall(diff(channel) .!= 0).+1)
    stopPoints = vcat(findall(diff(channel) .!= 0), length(channel))
    trigDurs = (stopPoints - startPoints)/fs

    evt = channel[startPoints]
    evtTab = Dict("Code" => evt,
                  "Index" => startPoints,
                  "Duration" => trigDurs)

end

# Create channel from events
############################

function create_channel(t::Dict, data::Array, fs::Number; kwargs...)

    create_channel(t, maximum(size(data)), fs; kwargs...)
end

function create_channel(t::Dict, l::Int, fs::Number; code::AbstractString="Code", index::AbstractString="Index",
                        duration::AbstractString="Duration")

    @debug("Creating trigger channel from data. Length: $l Triggers: $(length(t[index])) Fs: $fs")

    channel = Array{Int16}(undef, l)

    # Initialise array to 252 code
    for i = 1:l ; channel[i] = 252; end

    for i = 1:length(t[index])-1
        channel[t[index][i] : t[index][i] + round.(Int, t[duration][i] * fs)] .= t[code][i]
    end

    return channel
end

# Change biosemi labels to 1020
#######################################

function channelNames_biosemi_1020(original::S) where S <: AbstractString

    biosemi_1020 = ["A01" "Fp1"
                    "A1"  "Fp1"
                    "A05" "F3"
                    "A5"  "F3"
                    "A09" "FC5"
                    "A9"  "FC5"
                    "A13" "C3"
                    "A17" "CP5"
                    "A21" "P3"
                    "A25" "PO7"
                    "A29" "Oz"
                    "B01" "Fpz"
                    "B1"  "Fpz"
                    "B05" "AFz"
                    "B5"  "AFz"
                    "B9"  "F6"
                    "B13" "FC4"
                    "B17" "C2"
                    "B21" "TP8"
                    "B25" "P2"
                    "B29" "P10"
                    "A02" "AF7"
                    "A2"  "AF7"
                    "A06" "F5"
                    "A6"  "F5"
                    "A10" "FC3"
                    "A14" "C5"
                    "A18" "CP3"
                    "A22" "P5"
                    "A26" "PO3"
                    "A30" "POz"
                    "B02" "Fp2"
                    "B2"  "Fp2"
                    "B06" "Fz"
                    "B6"  "Fz"
                    "B10" "F8"
                    "B14" "FC2"
                    "B18" "C4"
                    "B22" "CP6"
                    "B26" "P4"
                    "B30" "PO8"
                    "A03" "AF3"
                    "A3"  "AF3"
                    "A07" "F7"
                    "A7"  "F7"
                    "A11" "FC1"
                    "A15" "T7"
                    "A19" "CP1"
                    "A23" "P7"
                    "A27" "O1"
                    "A31" "Pz"
                    "B03" "AF8"
                    "B3"  "AF8"
                    "B07" "F2"
                    "B7"  "F2"
                    "B11" "FT8"
                    "B15" "FCz"
                    "B19" "C6"
                    "B23" "CP4"
                    "B27" "P6"
                    "B31" "PO4"
                    "A04" "F1"
                    "A4"  "F1"
                    "A08" "FT7"
                    "A8"  "FT7"
                    "A12" "C1"
                    "A16" "TP7"
                    "A20" "P1"
                    "A24" "P9"
                    "A28" "Iz"
                    "A32" "CPz"
                    "B04" "AF4"
                    "B4"  "AF4"
                    "B08" "F4"
                    "B8"  "F4"
                    "B12" "FC6"
                    "B16" "Cz"
                    "B20" "T8"
                    "B24" "CP2"
                    "B28" "P8"
                    "B32" "O2"
                    "Status" "Status"]

    idx = something(findfirst(isequal(original), biosemi_1020), 0)

    if idx == 0
        error("Channel $original is unknown")
    end

    converted = biosemi_1020[:, 2][idx]
end

function channelNames_biosemi_1020(original::Array{S}) where S <: AbstractString

    converted = Array{AbstractString}(undef, size(original))

    @info("Fixing channel names of $(length(original)) channels")

    for i = 1:length(original)
        converted[i] = channelNames_biosemi_1020(original[i])
    end

    return converted
end
