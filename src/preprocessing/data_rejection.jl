"""
Reject epochs based on the maximum peak to peak voltage within an epoch across all channels

#### Arguments

* `epochs`: Array containing the epoch data in the format samples x epochs x channels
* `retain_percentage`: The percentage of epochs to retain
* `rejection_method`: Method to be used for epoch rejection (peak2peak)

#### Returns

* An array with a reduced amount of entries in the epochs dimension
"""
function epoch_rejection(epochs::Array{T, 3}, retain_percentage::AbstractFloat;
            rejection_method::Function=EEG.peak2peak) where T <: Number

    if (0 > retain_percentage) || (1 < retain_percentage)
        @warn("Non valid percentage value for retaining epochs $(retain_percentage)")
    end

    @info("Rejected $(round.(Int, (1 - retain_percentage) * 100))% of epochs based on $(string(rejection_method))")

    # Epoch value should be a value or score per epoch where a lower value is better
    # The lowest `retain_percentage` amount of epoch values will be kept
    epoch_values = rejection_method(epochs)

    cut_off_value = sort(epoch_values)[floor(Int, length(epoch_values) * retain_percentage)]
    epochs = epochs[:, epoch_values .<= cut_off_value, :]
end

"""
Find the peak to peak value for each epoch to be returned to epoch_rejection()
"""
function peak2peak(epochs)

    epochsNum = size(epochs)[2]

    peakvalues = Array{AbstractFloat}(undef, epochsNum)
    for epoch in 1:epochsNum
        peakvalues[epoch] = abs.(maximum(epochs[:, epoch, :]) - minimum(epochs[:, epoch, :]))
    end

    return peakvalues
end


"""
Reject channels with too great a variance.

Rejection can be based on a threshold or dynamicly chosen based on the variation of all channels.

#### Arguments

* `signals`: Array of data in format samples x channels
* `threshold_abs`: Absolute threshold to remove channels with variance above this value
* `threshold_std`: Reject channels with a variance more than n times the std of all channels

#### Returns

An array indicating the channels to be kept
"""
function channel_rejection(sigs::Array{T}, threshold_abs::Number, threshold_var::Number) where T <: Number

    @debug("Rejecting channels for signal of $(size(sigs,2)) chanels and $(size(sigs,1)) samples")

    variances           = var(sigs, dims = 1)        # Determine the variance of each channel
    valid_nonzero       = variances .!= 0    # The reference channel will have a variance of 0 so ignore it

    # Reject channels above the threshold
    valid_threshold_abs = variances .< threshold_abs
    @debug("Static rejection threshold: $(threshold_abs)")

    # Reject channels outside median + n * std
    variances_median    = median(variances[valid_nonzero])    # Use the median as usually not normal
    variances_std       = std(variances[valid_nonzero])       # And ignore the reference channel
    valid_threshold_var = variances  .<  (variances_median + threshold_var * variances_std)
    @debug("Dynamic rejection threshold: $(variances_median + threshold_var * variances_std)")

    valid_nonzero .& valid_threshold_abs .& valid_threshold_var   # Merge all methods
end
