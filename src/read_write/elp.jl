#######################################
#
# elp file
#
#######################################

"""
Read elp file containing sensor locations


#### Input
* `fname`: Name or path for the sfp file
* `coordinate`: Coordinate system for electrode location
* `r`: Radius for converting spherical coords

#### Output
* `elecs`: Array of electrode objects
"""
function read_elp(fname::AbstractString; coordinate=Talairach, r::Real=90)

    @info("Reading elp file = $fname")

    # Create an empty electrode set
    elecs = Electrode[]

    # Read file and match to expected file format
    file = read(fname, String)
    regexp = r"(\S+)\s+(\S+)\s+(\S+)"
    m = matchall(regexp, file)

    # Convert label to ascii and remove '
    for idx = 1:length(m)

        local_matches = match(regexp, m[idx])

        # Extract phi and theta
        phi = parse(Float64, local_matches[2])
        theta = parse(Float64, local_matches[3])

        # Convert to x, y, z
        x = r .* sin.(phi*(pi/180)) .* cos.(theta*(pi/180))
        y = r .* sin.(phi*(pi/180)) .* sin.(theta*(pi/180)) - 17.5
        z = r .* cos.(phi*(pi/180))

        push!(elecs, Electrode(replace(local_matches[1], "'", "" ), coordinate(x, y, z), Dict()))
    end

    @debug("Imported $(length(elecs)) electrodes")

    return elecs
end
