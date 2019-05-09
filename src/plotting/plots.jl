
#######################################
#
# Plot spectrum of signal
#
#######################################

function plot_spectrum(signal::Vector, fs::Real;
titletext::S="", Fmin::Number=0, Fmax::Number=90, targetFreq::F=0.0, dBPlot::Bool=true,
noise_level::Number=0, signal_level::Number=0) where {S <: AbstractString, F <: AbstractFloat}

    # Determine fft frequencies
    signal_length = length(signal)
    frequencies = range(0, stop=1, length=Int(signal_length / 2 + 1))*fs/2

    # Calculate fft and convert to power
    fftSweep = 2 / signal_length * fft(signal)
    spectrum = abs.(fftSweep[1:div(signal_length, 2) + 1])  # Amplitude
    spectrum = spectrum.^2

    valid_idx = (frequencies .<= Fmax) .& (frequencies .>= Fmin)
    spectrum = spectrum[valid_idx]
    frequencies = frequencies[valid_idx]

    # Want a log plot?
    if dBPlot
        spectrum = 10*log10.( spectrum )
        ylabel="Response Power (dB)"
    else
        ylabel="Response Power (uV^2)"
    end

    # Plot signal
    Plots.plot(frequencies, spectrum, lab = "Spectrum", color = :black)
    xlims!(Fmin, Fmax)
    xlabel!("Frequency (Hz)")
    ylabel!(ylabel)
    p = title!(titletext)

    # Plot the noise level if requested
    if noise_level != 0
        if dBPlot
            noise_level = 10*log10.(noise_level)
        end
        p = plot!([Fmin, targetFreq+2], [noise_level, noise_level], lab = "Noise", color = :red)
    end

    # Plot the signal level if requested
    if signal_level != 0
        if dBPlot
            signal_level = 10*log10.(signal_level)
        end
        plot!([Fmin, targetFreq], [signal_level, signal_level], lab = "Signal", color = :green)

        targetFreqIdx =   something(findfirst(isequal(minimum(abs.(frequencies.-targetFreq))), abs.(frequencies.-targetFreq)), 0) 
        targetFreq    = frequencies[targetFreqIdx]
        targetResults = spectrum[targetFreqIdx]
        #TODO remove label for circle rather than make it empty
        p = plot!([targetFreq], [targetResults], marker = (:circle, 5, 0.1, :green), markerstrokecolor = :green, lab = "")
    end
    return p
end


function plot_spectrum(eeg::SSR, chan::Int; targetFreq::Number=0)

    channel_name = channelnames(eeg)[1]

    # Check through the processing to see if we have done a statistical test at target frequency
    signal = nothing
    result_idx = find_keys_containing(eeg.processing, "statistics")

    for r = 1:length(result_idx)
        result = get(eeg.processing, collect(keys(eeg.processing))[result_idx[r]], 0)
        if result[:AnalysisFrequency][1] == targetFreq

            result_snr = result[:SNRdB][chan]
            signal = result[:SignalAmplitude][chan]^2
            noise  = result[:NoiseAmplitude][chan]^2
            title  = "Channel $(channel_name). SNR = $(round(result_snr, sigdigits=4)) dB"
        end
    end

    if signal == nothing
        title  = "Channel $(channel_name)"
        noise  = 0
        signal = 0
    end

    title = replace(title, "_", " ")

    avg_sweep = dropdims(mean(eeg.processing["sweeps"], 2), dims = 2)
    avg_sweep = avg_sweep[:, chan]
    avg_sweep = convert(Array{Float64}, vec(avg_sweep ))

    p = plot_spectrum(avg_sweep, eeg.header["sampRate"][1];
                        titletext=title, targetFreq = targetFreq,
                        noise_level = noise, signal_level = signal)

    return p
end

function plot_spectrum(eeg::SSR, chan::AbstractString; targetFreq::Number=modulationrate(eeg))

    return plot_spectrum(eeg,  something(findfirst(isequal(chan), channelnames(eeg)), 0), targetFreq=targetFreq)
end



#######################################
#
# Plot time series
#
# Automatic plotting for single channel (with units) or multichannel (with channel names) time series
#
#######################################

"""
Plot a single channel time series

#### Input

* signal: Vector of data
* fs: Sample rate
* channels: Name of channel to plot
* plot_points: Number of points to plot, they will be equally spread. Used to speed up plotting
* Other optional arguements are passed to gadfly plot function


#### Output

Returns a figure

"""
function plot_single_channel_timeseries(signal::AbstractVector{T}, fs::Real;
        xlabel::S="Time (s)", ylabel::S="Amplitude (uV)", lab::S="", kwargs...) where {T <: Number, S <: AbstractString}

    @debug("Plotting single channel waveform of size $(size(signal))")

    time_s = collect(1:size(signal, 1))/fs   # Create time axis

    Plots.plot(time_s, signal, t=:line, c=:black, lab=lab, xlabel=xlabel, ylabel=ylabel)
end



"""
Plot a multi channel time series

#### Input

* signals: Array of data
* fs: Sample rate
* channels: Name of channels
* plot_points: Number of points to plot, they will be equally spread. Used to speed up plotting
* Other optional arguements are passed to gadfly plot function


#### Output

Returns a figure

"""
function plot_multi_channel_timeseries(signals::Array{T, 2}, fs::Number, channels::Array{S};
        xlabel::S="Time (s)", ylabel::S="Amplitude (uV)", kwargs...) where {T <: Number, S <: AbstractString}

    @debug("Plotting multi channel waveform of size $(size(signals))")

    time_s = collect(1:size(signals, 1))/fs                        # Create time axis

    variances = var(signals, dims = 1)          # Variance of each figure for rescaling
    mean_variance = mean(variances)     # Calculate for rescaling figures

    p = Plots.plot(t=:line, c=:black, xlabel=xlabel, ylabel=ylabel, ylim=(-0.5, size(signals, 2) - 0.5))

    for c in 1:size(signals, 2)                                  # Plot each channel
        signals[:, c] = signals[:, c] - mean(signals[:, c])      # Remove mean
        signals[:, c] = signals[:, c] / mean_variance .+ (c-1)   # Rescale and shift so all chanels are visible
        p = plot!(time_s, signals[:, c], c=:black, lab="")
    end
    p = plot!(yticks = (0:length(channels) - 1, channels))

    return p
end



#######################################
#
# Filter response
#
#######################################

# Plot filter response
function plot_filter_response(zpk_filter::FilterCoefficients, fs::Integer;
              lower::Number=1, upper::Number=30, sample_points::Int=1024)

    frequencies = range(lower, stop=upper, length=1024)
    h = freqz(zpk_filter, frequencies, fs)
    magnitude_dB = 20*log10.(convert(Array{Float64}, abs.(h)))
    phase_response = (360/(2*pi))*unwrap(convert(Array{Float64}, angle.(h)))

    p1 = plot(frequencies, magnitude_dB,   lab = "")
    p2 = plot(frequencies, phase_response, lab = "")

    p = plot(p1,p2, ylabel = ["Magnitude (dB)" "Phase (degrees)"], xlabel = "Frequency (Hz)", layout = @layout([a; b]))
end
