using Plots
import Plots.plot


"""
Plot a volume image

#### Arguments

* `v`: A VolumeImage type
* `threshold`: Minimum value to plot, values smaller than this are plotted as `minsize`
* `min_val`: Force a minimum value for color and size scaling
* `max_val`: Force a maximum value for color and size scaling
* `minsize`: Minimum size a marker can be
* `maxsize`: Maximum size a marker can be
* `exclude`: Values not to plot
* `title`: Figure title
* `elp`: Path to elp file to overlay channel names
* `colorbar`: Should a colorbar be plotted


#### Returns

* A Plots.jl figure

"""
function plot(v::VolumeImage; kwargs...)

    x = AbstractFloat[xi / (1 * u"mm") for xi in v.x]
    y = AbstractFloat[yi / (1 * u"mm") for yi in v.y]
    z = AbstractFloat[zi / (1 * u"mm") for zi in v.z]

    plot_src(squeeze(v.data, 4), x, y, z; kwargs...)
end


function plot_src(d::Array{A, 3}, x::Vector{A}, y::Vector{A}, z::Vector{A};
            threshold::Real=-Inf, min_val::Real=Inf, max_val::Real=-Inf, minsize::Real=2, maxsize::Real=6,
            exclude::A=0.0, title::S="", elp::AbstractString="", colorbar::Bool=true, kwargs...) where {A <: AbstractFloat, S <: AbstractString}

    # cols = [colorant"darkblue", colorant"orange", colorant"darkred"]

    scaleval = maxsize / maximum(d)

    plot_labels = false
    if elp != ""
        e = read_elp(elp)
        plot_labels = true
    end

    #
    # First facet

    x_tmp = AbstractFloat[]
    y_tmp = AbstractFloat[]
    c_tmp = AbstractFloat[]
    s_tmp = AbstractFloat[]
    t = copy(d)
    t = maximum(t, dims = 3)
    t = squeeze(t, 3)
    for x_i in 1:size(t, 1)
        for y_i in 1:size(t, 2)
            val = t[x_i, y_i]
            if val != exclude
                push!(x_tmp, x[x_i])
                push!(y_tmp, y[y_i])
                if val > threshold
                    push!(s_tmp, max(scaleval * val, minsize))
                    push!(c_tmp, val)
                else
                    push!(s_tmp, minsize)
                    push!(c_tmp, minsize)
                end
            end
        end
    end
    if max_val > maximum(c_tmp)
        @debug("Manually specifying maximum plotting value")
        push!(s_tmp, max_val)
        push!(c_tmp, max_val)
        push!(x_tmp, -200)
        push!(y_tmp, -200)
    end
    if min_val < minimum(c_tmp)
        @debug("Manually specifying minimum plotting value")
        push!(s_tmp, min_val)
        push!(c_tmp, min_val)
        push!(x_tmp, -200)
        push!(y_tmp, -200)
    end
    p1 = plot(x_tmp, y_tmp, zcolor=c_tmp, ms=s_tmp, legend=false, l=:scatter, lab = "Source", colorbar = false, markerstrokewidth = 0.1, xlabel="Left - Right (mm)", ylabel="Posterior - Anterior (mm)", xlims = (-100, 100), ylims =(-120, 90); kwargs...)
    if plot_labels
        plotlist = ["Fpz", "Fp2", "AF8", "F8", "FT8", "T8", "TP8", "P10", "PO8", "O2", "Oz", "O1", "PO7", "P9", "TP7", "T7", "FT7", "F7", "AF7", "Fp1"]
        for elec in e
            if something(findfirst(isequal(elec.label), plotlist), 0) > 0
                annotate!(p1, elec.coordinate.x-5, 1.1*elec.coordinate.y-2, elec.label, colorbar = false)
            end
        end
    end


    #
    # Second facet

    x_tmp = AbstractFloat[]
    y_tmp = AbstractFloat[]
    c_tmp = AbstractFloat[]
    s_tmp = AbstractFloat[]
    t = copy(d)
    t = maximum(t, dims = 1)
    t = squeeze(t, 1)
    for x_i in 1:size(t, 1)
        for y_i in 1:size(t, 2)
            val = t[x_i, y_i]
            if val != exclude
                push!(x_tmp, y[x_i])
                push!(y_tmp, z[y_i])
                if val > threshold
                    push!(s_tmp, max(scaleval * val, minsize))
                    push!(c_tmp, val)
                else
                    push!(s_tmp, minsize)
                    push!(c_tmp, minsize)
                end
            end
        end
    end
    if max_val > maximum(c_tmp)
        @debug("Manually specifying maximum plotting value")
        push!(s_tmp, max_val)
        push!(c_tmp, max_val)
        push!(x_tmp, -200)
        push!(y_tmp, -200)
    end
    if min_val < minimum(c_tmp)
        @debug("Manually specifying minimum plotting value")
        push!(s_tmp, min_val)
        push!(c_tmp, min_val)
        push!(x_tmp, -200)
        push!(y_tmp, -200)
    end
    p2 = plot(x_tmp, y_tmp, zcolor=c_tmp, ms=s_tmp, legend=false, l=:scatter, title = title, lab = "Source", colorbar = false, markerstrokewidth = 0.1, xlabel = "Posterior - Anterior (mm)", ylabel = "Inferior - Superior (mm)", xlims = (-120, 90), ylims =(-70, 100); kwargs...)
    if plot_labels
        plotlist = ["Iz", "Oz", "POz", "Pz", "CPz", "Cz", "FCz", "Fz", "AFz", "Fpz"]
        for elec in e
            if  something(findfirst(isequal(elec.label), plotlist), 0)   > 0
                annotate!(p2, elec.coordinate.y-5, elec.coordinate.z, elec.label)
            end
        end
    end

    #
    # Third facet

    x_tmp = AbstractFloat[]
    y_tmp = AbstractFloat[]
    c_tmp = AbstractFloat[]
    s_tmp = AbstractFloat[]
    t = copy(d)
    t = maximum(t, dims = 2)
    t = squeeze(t, 2)
    for x_i in 1:size(t, 1)
        for y_i in 1:size(t, 2)
            val = t[x_i, y_i]
            if val != exclude
                push!(x_tmp, x[x_i])
                push!(y_tmp, z[y_i])
                if val > threshold
                    push!(s_tmp, max(scaleval * val, minsize))
                    push!(c_tmp, val)
                else
                    push!(s_tmp, minsize)
                    push!(c_tmp, minsize)
                end
            end
        end
    end
    if max_val > maximum(c_tmp)
        @debug("Manually specifying maximum plotting value")
        push!(s_tmp, max_val)
        push!(c_tmp, max_val)
        push!(x_tmp, -200)
        push!(y_tmp, -200)
    end
    if min_val < minimum(c_tmp)
        @debug("Manually specifying minimum plotting value")
        push!(s_tmp, min_val)
        push!(c_tmp, min_val)
        push!(x_tmp, -200)
        push!(y_tmp, -200)
    end
    p3 = plot(x_tmp, y_tmp, zcolor=c_tmp, ms=s_tmp, legend=false, l=:scatter, lab = "", markerstrokewidth = 0.1, colorbar = colorbar, xlabel = "Left - Right (mm)", ylabel = "Inferior - Superior (mm)", xlims = (-100, 100), ylims =(-70, 100); kwargs...)
    if plot_labels
        plotlist = ["T7", "C5", "C3", "C1", "Cz", "C2", "C4", "C6", "T8"]
        for elec in e
            if findfirst(plotlist, elec.label)  > 0
                annotate!(p3, elec.coordinate.x-5, elec.coordinate.z, elec.label)
            end
        end
    end

    l  = @layout([a b c])
    return plot(p1, p2, p3, layout = l)
end
