#######################################
#
# FTest
#
#######################################


function ftest(s::SSR; freq_of_interest::Union{Real, AbstractArray}=modulationrate(s), side_freq::Number=0.5,
    ID::AbstractString="", spill_bins::Int=2, results_key::AbstractString="statistics", kwargs... )

    # Do calculation here once, instead of in each low level call
    spectrum    = EEG._ftest_spectrum(s.processing["sweeps"])
    spectrum    = compensate_for_filter(s.processing, spectrum, samplingrate(s))
    frequencies = range(0, stop=1, length=Int(size(spectrum, 1)))*samplingrate(s)/2

    for freq in freq_of_interest

        snrDb, phase, signal, noise, statistic = ftest(spectrum, frequencies, freq, side_freq, spill_bins)

        result = DataFrame(ID                 = vec(repmat([ID], length(channelnames(s)), 1)),
                           Channel            = copy(channelnames(s)),
                           ModulationRate     = copy(modulationrate(s)),
                           AnalysisType       = vec(repmat(["F-test"], length(channelnames(s)))),
                           AnalysisFrequency  = vec(repmat([freq], length(channelnames(s)))),
                           SignalAmplitude    = vec(sqrt.(signal)),
                           SignalPhase        = vec(phase),
                           NoiseAmplitude     = vec(sqrt.(noise)),
                           SNRdB              = vec(snrDb),
                           Statistic          = vec(statistic))

        result = add_dataframe_static_rows(result, kwargs)

        if haskey(s.processing, results_key)
            s.processing[results_key] = vcat(s.processing[results_key], result)
        else
            s.processing[results_key] = result
        end

    end

    return s
end


#######################################
#
# Helper functions
#
#######################################


# Save ftest results to file
function save_results(a::SSR; name_extension::AbstractString="", results_key::AbstractString="statistics", kwargs...)

    file_name = string(a.file_name, name_extension, ".csv")

    # Rename to save space
    results = a.processing

    # Index of keys to be exported
    result_idx = find_keys_containing(results, results_key)

    if length(result_idx) > 0

        to_save = get(results, collect(keys(results))[result_idx[1]], 0)

        CSV.write(file_name, to_save)
    end

    @info("File saved to $file_name")

    return a
end
