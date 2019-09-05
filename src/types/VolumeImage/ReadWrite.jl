function read_VolumeImage(fname::AbstractString)

    @info("Creating volume image from file $fname")

    if occursin(".dat", fname)
        x, y, z, s, t = read_dat(fname)
        method = "CLARA"
        header = Dict()
        units = "nAm/cm^3"
        x = x/1000
        y = y/1000
        z = z/1000
        t = t/1000
    else
        @warn("Unknown file type")
    end

    header["FileName"] = fname

    coord_system = "?"

    VolumeImage(s, units, collect(x) * u"m", collect(y) * u"m", collect(z) * u"m", collect(t) * u"s", method, header, coord_system)
end


