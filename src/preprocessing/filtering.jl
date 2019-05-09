"""
High pass filter applied in forward and reverse direction

Simply a wrapper for the DSP.jl functions

#### Arguments

* `signals`: Signal data in the format samples x channels
* `cutOff`: Cut off frequency in Hz
* `fs`: Sampling rate
* `order`: Filter orde

#### Returns

* filtered signal
* filter used on signal
"""
function highpass_filter(signals::Array{T}, cutOff::Number, fs::Number, order::Int) where T <: AbstractFloat
    @debug("Highpass filtering $(size(signals)[end]) channels.  Pass band > $(cutOff) Hz")
    Wn = cutOff/(fs/2)
    highpass_filter(signals, Wn, order)
end


function highpass_filter(signals::Array{T}, Wn::Number, order::Int) where T <: AbstractFloat
    @debug("Filter order = $order, Wn = $Wn")
    f = digitalfilter(Highpass(Wn), Butterworth(order))
    signals = filtfilt(f, signals)
    return signals, f
end



"""
Low pass filter applied in forward and reverse direction

Simply a wrapper for the DSP.jl functions

#### Input

* `signals`: Signal data in the format samples x channels
* `cutOff`: Cut off frequency in Hz
* `fs`: Sampling rate
* `order`: Filter orde

#### Output

* filtered signal
* filter used on signal
"""
function lowpass_filter(signals::Array{T}, cutOff::Number, fs::Number, order::Int) where T <: AbstractFloat
    @debug("Lowpass filtering $(size(signals)[end]) channels.  Pass band < $(cutOff) Hz")
    Wn = cutOff/(fs/2)
    lowpass_filter(signals, Wn, order)
end


function lowpass_filter(signals::Array{T}, Wn::Number, order::Int) where T <: AbstractFloat
    @debug("Filter order = $order, Wn = $Wn")
    f = digitalfilter(Lowpass(Wn), Butterworth(order))
    signals = filtfilt(f, signals)
    return signals, f
end


"""
Band pass filter
"""
function bandpass_filter(signals::Array, lower::Number, upper::Number, fs::Number, n::Int, rp::Number)
    # Type 1 Chebychev filter
    # TODO filtfilt does not work. Why not?

    signals = convert(Array{Float64}, signals)

    f = digitalfilter(Bandpass(lower, upper, fs=fs), Chebyshev1(n, rp))

    @info("Bandpass filtering $(size(signals)[end]) channels.     $lower < Hz < $upper")
    @debug("Filter order = $n, fs = $fs")

    signals = filt(f, signals)
    signals = filt(f, reverse(signals, dims = 1))
    signals = reverse(signals, dims = 1)

    return signals, f
end


#######################################
#
# Filter compensation
#
#######################################

function compensate_for_filter(d::Dict, spectrum::AbstractArray, fs::Real)
    frequencies = range(0, stop = 1, length = Int(size(spectrum, 1))) * fs / 2

    key_name = "filter"
    key_numb = 1
    key      = string(key_name, key_numb)

    while haskey(d, key)

        spectrum = compensate_for_filter(d[key], spectrum, frequencies, fs)

        @debug("Accounted for $key response in spectrum estimation")

        key_numb += 1
        key = string(key_name, key_numb)
    end

    return spectrum
end


"""
Recover the spectrum of signal by compensating for filtering done.

#### Arguments

* `filter`: The filter used on the spectrum
* `spectrum`: Spectrum of signal
* `frequencies`: Array of frequencies you want to apply the compensation to
* `fs`: Sampling rate

#### Returns

Spectrum of the signal after comensating for the filter

#### TODO

Extend this to arbitrary number of dimensions rather than the hard coded 3
"""
function compensate_for_filter(filter::FilterCoefficients, spectrum::AbstractArray, frequencies::AbstractArray, fs::Real)
    filter_response     = freqz(filter, frequencies, fs)

    for f = 1:length(filter_response)
        spectrum[f, :, :] = spectrum[f, :, :] ./ abs.(filter_response[f])^2
    end

    return spectrum
end
