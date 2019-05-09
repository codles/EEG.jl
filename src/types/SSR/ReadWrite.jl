#######################################
#
# Read SSR
#
#######################################

"""
## Read SSR from file or IO stream
Read a file or IO stream and store the data in an `SSR` type.

Matching .mat files are read and modulation frequency information extracted.
Failing that, user passed arguments are used or the modulation frequency is extracted from the file name.

#### Arguments

* `fname`: Name of the file to be read
* `min_epoch_length`: Minimum epoch length in samples. Shorter epochs will be removed (0)
* `max_epoch_length`: Maximum epoch length in samples. Longer epochs will be removed (0 = all)
* `valid_triggers`: Triggers that are considered valid, others are removed ([1,2])
* `stimulation_amplitude`: Amplitude of stimulation (NaN)
* `modulationrate`: Modulation frequency of SSR stimulation (NaN)
* `carrier_frequency`: Carrier frequency (NaN)
* `participant_name`: Name of participant ("")
* `remove_first`: Number of epochs to be removed from start of recording (0)
* `max_epochs`: Maximum number of epochs to retain (0 = all)
* `env` (nothing)
* `bkt` ("")

#### Supported file formats

* BIOSEMI (.bdf)
"""
function read_SSR(fname::String;
                  stimulation_amplitude::Number=NaN,   # User can set these
                  modulationrate::Number=NaN,          # values, but if not
                  carrier_frequency::Number=NaN,       # then attempt to read
                  stimulation_side::AbstractString="", # from file name or mat
                  participant_name::AbstractString="",
                  valid_triggers::Array{Int}=[1,2],
                  min_epoch_length::Int=0,
                  max_epoch_length::Int=0,
                  remove_first::Int=0,
                  max_epochs::Int=0,
                  env=nothing,
                  bkt="",
                  kwargs...)


    @info("Importing SSR from file: $fname")

    file_path, file_name, ext = fileparts(fname)

    if env != nothing

        @debug("File type is S3")
        fname = S3.get_object(env, bkt, fname).obj
    end


    #
    # Extract meta data
    #

    # Extract frequency from the file name if not set manually
    if occursin("Hz", file_name) && isnan(modulationrate)
        a = match(r"[-_](\d+[_.]?[\d+]?)Hz|Hz(\d+[_.]?[\d+]?)[-_]", file_name).captures
        modulationrate = float(a[[i !== nothing for i = a]][1]) * 1.0u"Hz"
        @debug("Extracted modulation frequency from file name: $modulationrate")
    end

    # Or even better if there is a mat file read it
    mat_path = string(file_path, file_name, ".mat")
    if !isfile(mat_path)
        mat_path = string(file_path, file_name, "-properties.mat")
    end

    if isfile(mat_path)
        modulationrate, stimulation_side, participant_name,
            stimulation_amplitude, carrier_frequency = read_rba_mat(mat_path)
        valid_mat = true
    else
        valid_mat = false
    end


    #
    # Read file data
    #

    # Import raw data
    if ext == "bdf"
        data, triggers, system_codes, samplingrate, reference_channel, header = import_biosemi(fname; kwargs...)
    else
        warn("File type $ext is unknown")
    end

    # Create electrodes
    elecs = Electrode[]
    for e in header["chanLabels"]
        push!(elecs, Electrode(e, Talairach(NaN, NaN, NaN), Dict()))
    end

    # Create SSR type
    if unit(modulationrate) == unit(1.0u"Hz")
        #nothing
    else
        modulationrate = modulationrate * 1.0u"Hz"
    end
    if unit(samplingrate) == unit(1.0u"Hz")
        #nothing
    else
        samplingrate = samplingrate * 1.0u"Hz"
    end

    a = SSR(data, elecs, triggers, system_codes, samplingrate, modulationrate,
            [reference_channel], file_path, file_name, Dict(), header)


    # If a valid mat file was found then store that information with the raw header
    if valid_mat
        a.header["rbadata"] = matread(mat_path)
    end


    #
    # Store meta data in processing dictionary
    #

    if stimulation_side != ""
        a.processing["Side"] = stimulation_side
    end
    if participant_name != ""
        a.processing["Name"] = participant_name
    end
    if !isnan(stimulation_amplitude)
        a.processing["Amplitude"] = stimulation_amplitude
    end
    if !isnan(carrier_frequency)
        a.processing["Carrier_Frequency"] = carrier_frequency
    end


    #
    # Clean up
    #

    # Remove status channel information
    remove_channel!(a, "Status")

    # Clean epoch index
    a.triggers = clean_triggers(a.triggers, valid_triggers, min_epoch_length, max_epoch_length, remove_first, max_epochs)

    return a
end




#######################################
#
# Read event files
#
#######################################

function read_evt(a::SSR, fname::AbstractString; kwargs...)
    d = read_evt(fname, a.samplingrate; kwargs...)
    validate_triggers(d)
    a.triggers = d
    return a
end



#######################################
#
# File IO
#
#######################################

function trigger_channel(a::SSR; kwargs...)

    create_channel(a.triggers, a.data, samplingrate(a))
end


function system_code_channel(a::SSR; kwargs...)

    create_channel(a.system_codes, a.data, samplingrate(a))
end


function write_SSR(a::SSR, fname::S; chanLabels=channelnames(a), subjID=a.header["subjID"],
startDate=a.header["startDate"], startTime=a.header["startTime"], kwargs...) where S <: AbstractString

    fname = convert(String, fname)

    @info("Saving $(size(a.data)[end]) channels to $fname")

    writeBDF(fname, a.data', vec(trigger_channel(a)), vec(system_code_channel(a)), samplingrate(Int, a),
             chanLabels = convert(Array{S, 1}, chanLabels),
             startDate = startDate, startTime = startTime, subjID = subjID)

end
