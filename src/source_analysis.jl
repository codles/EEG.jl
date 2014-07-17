using MinMaxFilter

type Dipole
    coord_system::String
    x::Number
    y::Number
    z::Number
    xori::Number
    yori::Number
    zori::Number
    color::Number
    state::Number
    size::Number
end


#######################################
#
# LCMV Beamformer
#
# Localization of brain electrical activity via linearly constrained minimum variance spatial filtering
# Van Veen, B. D., van Drongelen, W., Yuchtman, M., & Suzuki, A. (1997)
#
#######################################


function beamformer_lcmv(x::Array, n::Array, H::Array; verbose::Bool=false, debug::Bool=false)
    # LCMV beamformer as described in Van Veen et al '97
    #
    # Input:    x = N x M matrix     = M sample measurements on N electrodes
    #           n = N x ? matrix     = ? sample measurement of noise on N electrodes
    #           H = L x 3 x N matrix = forward head model.  !! Different to paper !!

    # This function sets everything up and checks data before passing to efficient actual calculation

    # Constants
    N = size(x)[1]      # Sensors
    M = size(x)[2]      # Samples
    L = size(H)[1]      # Locations

    # Some sanity checks on the input
    if size(H)[3] != N; error("Leadfield and data dont match"); end
    if size(H)[2] != 3; error("Leadfield dimension is incorrect"); end
    if N > L; error("More channels than samples. Something switched?"); end
    if any(isnan(x)); error("Their is a nan in your input x data"); end

    # Covariance matrices sampled at 4 times more locations than sensors
    C_x = cov(x[:, round(linspace(2, M-1, 4*N))]')
    Q   = cov(n[:, round(linspace(2, size(n)[2]-1, 4*N))]')

    # Space to save results
    V   = Array(Float64, (L,1))         # Variance
    N   = Array(Float64, (L,1))         # Noise
    NAI = Array(Float64, (L,1))         # Neural Activity Index

    # More checks
    if any(isnan(C_x)); error("Their is a nan in your signal data"); end
    if any(isnan(Q)); error("Their is a nan in your noise data"); end

    # Scan each location
    if verbose; p = Progress(L, 1, "  Scanning... ", 50); end
    for location = 1:L
        V[location], N[location], NAI[location] = beamformer_lcmv_actual(C_x, squeeze(H[location,:,:], 1)', Q, debug=debug)
        if verbose; next!(p); end
    end

    return V, N, NAI
end


function beamformer_lcmv_actual(C_x::Array, H::Array, Q::Array; N=64, debug::Bool=false)

    if debug
        if size(H)[1] != N; error("Leadfield and data dont match"); end
        if size(H)[2] != 3; error("Leadfield dimension is incorrect"); end
        if size(C_x)[1] != N; error("Covariance size is incorrect"); end
        if size(C_x)[2] != N; error("Covariance size is incorrect"); end
        if size(Q) != size(C_x); error("Covariance matrices dont match"); end
    end

    # Strength of source
    V_q = trace( inv( H' * pinv(C_x) * H ) )

    # Noise strength
    N_q = trace( inv(H' * inv(Q) * H) )

    # Neural activity index
    NAI = V_q / N_q

    return V_q, N_q, NAI
end


#######################################
#
# Find dipoles in source data
#
# Use local maxima as dipoles
#
#######################################


function find_dipoles(s::Array{FloatingPoint, 3}; window::Number=6,
                      x=1:size(s,1), y=1:size(s,2),
                      z=1:size(s,3), t=1:size(s,4),
                      verbose::Bool=false, debug::Bool=false)

    minval, maxval = minmax_filter(s, window, verbose=false)

    # Find the positions matching the maxima
    matching = s[2:size(maxval)[1]+1, 2:size(maxval)[2]+1, 2:size(maxval)[3]+1]
    matching = matching .== maxval

    # dipoles are defined as maxima locations and within 90% of the maximum
    peaks = maxval[matching]
    peaks = peaks[peaks .>= 0.1 * maximum(peaks)]

    dips = Array(Dipole, (1,length(peaks)))
    for l = 1:length(peaks)
        xidx, yidx, zidx = ind2sub(size(s), find(s .== peaks[l]))

        dips[l] = Dipole("Unknown", x[xidx[1]], y[yidx[1]], z[zidx[1]],
                         0, 0, 0, 0, 0,
                         peaks[l])

    end

    return dips
end


function find_dipoles(s::Array{Float64, 4}; window::Number=6,
                      x=1:size(s,1), y=1:size(s,2),
                      z=1:size(s,3), t=1:size(s,4),
                      verbose::Bool=false, debug::Bool=false)

    # Fob of the time dimension
    # TODO: take 4d max
    s = squeeze(maximum(s,4),4)

    s = convert(Array{FloatingPoint}, s)

    find_dipoles(s, x=x, y=y, z=z, t=t, verbose=verbose, debug=debug)
end
