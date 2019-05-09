import Base: +, -, /, *, mean, maximum, minimum, isequal, ==
using Statistics


# +

function +(vi1::VolumeImage, vi2::VolumeImage)

    dimensions_equal(vi1, vi2)

    @debug("Adding two volume images with $(size(vi1.data, 4)) time instances")

    vout = deepcopy(vi1)

    vout.data = vi1.data .+ vi2.data

    return vout
end


# -

function -(vi1::VolumeImage, vi2::VolumeImage)

    dimensions_equal(vi1, vi2)

    @debug("Subtracting two volume images with $(size(vi1.data, 4)) time instances")

    vout = deepcopy(vi1)

    vout.data = vi1.data .- vi2.data

    return vout
end


# /

function /(vi1::VolumeImage, vi2::VolumeImage)

    dimensions_equal(vi1, vi2)

    @debug("Dividing two volume images with $(size(vi1.data, 4)) time instances")

    vout = deepcopy(vi1)

    vout.data = vi1.data ./ vi2.data

    return vout
end

function /(vi::VolumeImage, c::Number)

    vout = deepcopy(vi)

    vout.data = vi.data ./ c

    return vout
end


# *

function *(vi::VolumeImage, c::Number)

    vout = deepcopy(vi)

    vout.data = vi.data .* c

    return vout
end


# mean

function mean(vi::VolumeImage)

    @debug("Taking mean of one volume images with $(size(vi.data, 4)) time instances")

    vout = deepcopy(vi)

    vout.data = mean(vout.data, dims = 4)

    # Store time as 0 to indicate its been averaged
    vout.t = [NaN] * u"s"

    return vout
end

function mean(va::Array{VolumeImage,1})

    @debug("Taking mean of $(length(va)) volume images with $(size(va[1].data, 4)) time instances")

    mean_va = deepcopy(va[1])

    for i in 2:length(va)

        mean_va = mean_va + va[i]

    end

    return mean_va / length(va)
end


# maximum

function maximum(vi::VolumeImage)

    maximum(vi.data)
end

function maximum(vis::Array{VolumeImage})

    maximum([maximum(vi) for vi in vis])
end


# minimum

function minimum(vi::VolumeImage)

    minimum(vi.data)
end

function minimum(vis::Array{VolumeImage})

    minimum([minimum(vi) for vi in vis])
end



# normalise

function normalise(vi::VolumeImage)

    @debug("Normalising one volume images with $(size(vi.data, 4)) time instances")

    normalisation_constant = maximum(vi)

    vi = deepcopy(vi) / normalisation_constant

    vi.info["NormalisationConstant"] = normalisation_constant

    return vi
end

function normalise(va::Array{VolumeImage, 1})

    @debug("Normalising $(length(va)) volume images with $(size(va[1].data, 4)) time instances")

    vo = deepcopy(va)
    for i in 1:length(vo)
        vo[i] = normalise(vo[i])
    end
    return vo
end


# isequal

function isequal(a::VolumeImage, b::VolumeImage)

    a.data == b.data ||
    a.units == b.units ||
    a.x == b.x ||
    a.y == b.y ||
    a.z == b.z ||
    a.t == b.t ||
    a.method == b.method ||
    a.coord_system == b.coord_system

end

function ==(a::VolumeImage, b::VolumeImage)

    isequal(a, b)
end


#
# Helper functions
# ----------------
#

function dimensions_equal(vi1::VolumeImage, vi2::VolumeImage; x::Bool=true, y::Bool=true, z::Bool=true, t::Bool=true, units::Bool=true, kwargs...)

    matching = true
    if x .& .!(vi1.x == vi2.x)
        throw(KeyError("X dimensions do not match"))
    end
    if y .& .!(vi1.y == vi2.y)
        throw(KeyError("Y dimensions do not match"))
    end
    if z .& .!(vi1.z == vi2.z)
        throw(KeyError("Z dimensions do not match"))
    end
    if t .& .!(vi1.t == vi2.t)
        throw(KeyError("T dimensions do not match"))
    end
    if units .& .!(vi1.units == vi2.units)
        throw(KeyError("Units do not match"))
    end

    if matching
        return true
    end
end

"""
Find indicies of location in VolumeImage
"""
function find_location(vi::VolumeImage, x::Real, y::Real, z::Real)

    x_loc = findall(minimum(abs.(vi.x - x)) .== abs.(vi.x - x))[1]
    y_loc = findall(minimum(abs.(vi.y - y)) .== abs.(vi.y - y))[1]
    z_loc = findall(minimum(abs.(vi.z - z)) .== abs.(vi.z - z))[1]

    if length(size(vi.data)) == 3
        return [x_loc, y_loc, z_loc]
    elseif length(size(vi.data)) == 4
        return [x_loc, y_loc, z_loc, 1]
    else
        return [NaN]
    end
end
