#######################################
#
# AVR file
#
#######################################

"""
Read AVR (.avr) file

#### Input
* `fname`: Name or path for the AVR file

#### Output
* `data`: Array of data read from AVR file. Each column represents a channel, and each row represents a point.
* `chanNames`: Channel Names

"""
function read_avr(fname::AbstractString)
    @info("Reading AVR file: $fname")

    # Open file
    file = open(fname, "r")

    # Header line
    header_exp = r"Npts= (\d*)\s+TSB= ([-+]?[0-9]*\.?[0-9]+)\s+DI= ([-+]?[0-9]*\.?[0-9]+)\s+SB= ([-+]?[0-9]*\.?[0-9]+)\s+SC= ([-+]?[0-9]*\.?[0-9]+)\s+Nchan= (\d*)"
    m     = match(header_exp, readline(file))
    npts  = parse(Int, ascii(m.captures[1])) # Number of points
    tsb   = m.captures[2] # Omit?
    di     = m.captures[3] # Omit?
    sb    = m.captures[4] # Omit?
    sc    = m.captures[5] # Omit?
    nchan = parse(Int, ascii(m.captures[6])) # Number of channels

    # Channel line
    names_exp = r"(\w+)"
    chanNames      = matchall(names_exp, readline(file))

    # Data
    data = Array{Float64}(undef, (npts, nchan))
    for c = 1:nchan
        d = matchall(r"([-+]?[0-9]*\.?[0-9]+)", readline(file))
        for n = 1:npts
            data[n,c] = float(ascii(d[n]))
        end
    end

    # Close file
    close(file)

    return data, chanNames
end

"""
Write AVR file
"""
function write_avr(fname::AbstractString, data::Array, chanNames::Array, fs::Number)

    @info("Saving avr to $fname")

    fs  = float(fs)

    open(fname, "w") do fid
        @printf(fid, "Npts= %d   TSB= %2.6f DI= %2.6f SB= %2.3f SC= %3.1f Nchan= %d\n", size(data,1), 1000/fs, 1000/fs,
                1.0, 200.0, size(data,2))

        @printf(fid, "%s", chanNames[1])
        for c = 2:length(chanNames)
            @printf(fid, " ")
            @printf(fid, "%s", chanNames[c])
        end
        @printf(fid, "\n")

        for c = 1:size(data,2)
            @printf(fid, "%2.6f", data[1,c])
            for p = 2:size(data,1)
                @printf(fid, " ")
                @printf(fid, "%2.6f", data[p,c])
            end
            @printf(fid, " ")
            @printf(fid, "\n")
        end
    end
end
