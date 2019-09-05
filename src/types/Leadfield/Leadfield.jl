mutable struct Leadfield{T <: AbstractFloat, S <: AbstractString}
    L::Array{T, 3}
    x::Vector{T}
    y::Vector{T}
    z::Vector{T}
    sensors::Vector{S}
end


function Base.show(io::IO, l::Leadfield)
    @printf "Leadfield\n"
    @printf "  Number of sources: %d\n" size(l.L, 1)
    @printf "  Number of dimensions + nulls: %d\n" size(l.L, 2)
    @printf "  Number of sensors: %d\n" size(l.L, 3)
end


function match_leadfield(l::Leadfield, s::SSR)

    @info("Matching leadfield to SSR")

    idx = [something(findfirst(isequal(name), l.sensors), 0) for name = channelnames(s)]

    if length(unique(idx)) < length(idx)
        error("Not all SSR channels mapped to sensor #SSR=$(length(channelnames(s))), #L=$(length(l.sensors))")
    end

    l.L = l.L[:,:,idx]
    l.sensors = l.sensors[idx]

    @debug("matched $(length(idx)) sensors")

    return l
end


