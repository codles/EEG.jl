#######################################
#
# dat file
#
#######################################

"""
Read dat files

#### Arguments
* `fname`: Name or path for the dat file

#### Returns
* `x`: Range of x values
* `y`: Range of y values
* `z`: Range of z values
* `complete_data`: Array (x × y × z x t)
* `sample_times`

#### References
File specs were taken from [fieldtrip](https://github.com/fieldtrip/fieldtrip/blob/1cabb512c46cc70e5b734776f20cdc3c181243bd/external/besa/readBESAimage.m)
"""
function read_dat(fname::AbstractString)
    @info("Reading dat file = $fname")

    read_dat(open(fname, "r"))
end


function read_dat(fid::IO)

    if isa(fid, IOBuffer)
        fid.ptr = 1
    end

    # Ensure we are reading version 2
    versionAbstractString = match(r"(\S+):(\d.\d)", readline(fid))
    version = float(versionAbstractString.captures[2])
    @debug("Version = $version")

    # Use @assert here?
    if version != 2
        Logging.warn("Unknown dat file version")
        return
    end

    # Header info
    readline(fid) # Empty line
    data_file = readline(fid)
    condition = readline(fid)
    typeline  = readline(fid)

    # Types of data that can be stored
    if search(typeline, "Method") != 0:-1  # TODO: change to imatch
        @debug("File type is Method")

        image_type = typeline[21:end]
        image_mode = "Time"
        regularization = readline(fid)[21:end-1]

        #=Latency=#  # TODO: Fix for latencies. See fieldtrip

        # Units
        units          = readline(fid)[3:end-1]

        @debug("Regularisation = $regularization")
        @debug("Units = $units")
    elseif search(typeline, "MSBF") != 0:-1

        image_mode = "Single Time"
        image_type = "Multiple Source Beamformer"
        units = condition[3:end-1]
        regularization = "None"

        Logging.warn("MSBF type under development")
    elseif search(typeline, "MSPS") != 0:-1
        Logging.warn("MSPS type not implemented yet")
    elseif search(typeline, "Sens") != 0:-1
        Logging.warn("Sens type not implemented yet")
    else
        Logging.warn("Unknown type")
    end

    readline(fid) # Empty line
    description = readline(fid)

    # Read in the dimensions
    regexp = r"[X-Z]:\s+(-?\d+\.\d+)\s+(-?\d+\.\d+)\s+(-?\d+)"
    xrange = match(regexp, readline(fid))
    x = range(float(xrange.captures[1]), stop=float(xrange.captures[2]), length=parse(Int, xrange.captures[3]))
    yrange = match(regexp, readline(fid))
    y = range(float(yrange.captures[1]), stop=float(yrange.captures[2]), length=parse(Int, yrange.captures[3]))
    zrange = match(regexp, readline(fid))
    z = range(float(zrange.captures[1]), stop=float(zrange.captures[2]), length=parse(Int, zrange.captures[3]))

    empty       = readline(fid)

    # Variables to fill
    t = 1
    complete_data = Array{Float64}(undef, (length(x), length(y), length(z), t))
    sample_times  = Float64[]

    description = readline(fid)
    if search(description, "Sample") != 0:-1

        #
        # 4D file
        #

        s = match(r"Sample \d+, (-?\d+.\d+) ms", description)
        push!(sample_times, float(s.captures[1]))

        file_still_going = true
        while file_still_going
            for zind = 1:length(z)
                readline(fid)           # Z: z

                for yind = 1:length(y)
                    d = readline(fid)       # values
                    m = matchall(r"(-?\d+.\d+)", d)
                    complete_data[:, yind, zind, t] = float(m)
                end

                readline(fid)           # blank or dashed
            end

            if eof(fid)
                file_still_going = false
            else
                t += 1
                s = readline(fid)               # Sample n, t.tt ms
                s = match(r"Sample \d+, (-?\d+.\d+) ms", s)
                push!(sample_times, float(s.captures[1]))

                # There is no nice way to grow a multidimensional array
                temp = complete_data
                complete_data = Array{Float64}(undef, (length(x), length(y), length(z), t))
                complete_data[:,:,:,1:t-1] = temp
            end
        end
    else

        #
        # 3D file
        #

        file_still_going = true
        idx = 1
        while file_still_going
            for zind = 1:length(z)

                for yind = 1:length(y)
                    d = readline(fid)       # values
                    m = matchall(r"(-?\d+.\d+)", d)
                    complete_data[:, yind, zind, t] = float(m)
                end

                d = readline(fid)           # blank or dashed
                d = readline(fid)           # blank or dashed
            end

            if eof(fid)
                file_still_going = false
            else
                println("File should have finished")
            end
        end

        sample_times = [0]
    end

    close(fid)

    return x, y, z, complete_data, sample_times
end


"""
Write dat file
"""
function write_dat(fname::AbstractString,
X::AbstractVector, Y::AbstractVector, Z::AbstractVector,
S::Array{DataT,4}, T::AbstractVector;
data_file::AbstractString="NA", condition::AbstractString="NA", method::AbstractString="NA", regularization::AbstractString="NA",
units::AbstractString="NA") where DataT <: AbstractFloat

    if size(S,1) != length(X); Logging.warn("Data and x sizes do not match"); end
    if size(S,2) != length(Y); Logging.warn("Data and y sizes do not match"); end
    if size(S,3) != length(Z); Logging.warn("Data and z sizes do not match"); end
    if size(S,4) != length(T); Logging.warn("Data and t sizes do not match"); end

    @info("Saving dat to $fname")

    open(fname, "w") do fid
        @printf(fid, "BESA_SA_IMAGE:2.0\n")
        @printf(fid, "\n")
        @printf(fid, "Data file:          %s\n", data_file)
        @printf(fid, "Condition:          %s\n", condition)
        @printf(fid, "Method:             %s\n", method)
        @printf(fid, "Regularization:     %s\n", regularization)
        @printf(fid, "  %s\n",                   units)

        @printf(fid, "\n")
        @printf(fid, "Grid dimensions ([min] [max] [nr of locations]):\n")
        @printf(fid, "X:  %2.6f %2.6f %d\n", minimum(X), maximum(X), length(X))
        @printf(fid, "Y:  %2.6f %2.6f %d\n", minimum(Y), maximum(Y), length(Y))
        @printf(fid, "Z:  %2.6f %2.6f %d\n", minimum(Z), maximum(Z), length(Z))
        @printf(fid, "==============================================================================================\n")

        for t = 1:size(S, 4)
            @printf(fid, "Sample %d, %1.2f ms\n", t-1, T[t])
            for z = 1:size(S, 3)
                @printf(fid, "Z: %d\n", z-1)
                for y = 1:size(S,2)
                    for x = 1:size(S,1)
                        @printf(fid, "%2.10f ", S[x,y,z,t])
                    end
                    @printf(fid, "\n")
                end
                @printf(fid, "\n")
            end
        end
        @debug("File successfully written")
    end
end
