function read_VolumeImage(fname::String)

    if contains(fname, ".dat")
        x, y, z, s, t = read_dat(fname)
        method = "CLARA"
        header = Dict()
        units = "nAm/cm^3"
        x = x/1000
        y = y/1000
        z = z/1000
        t = t/1000
    else
        warn("Unknown file type")
    end

    VolumeImage(s, units, x, y, z, t, method, header)
end


