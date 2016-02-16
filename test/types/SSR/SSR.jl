using EEG, Base.Test, Logging
Logging.configure(level=Logging.DEBUG)

fname = joinpath(dirname(@__FILE__), "../../data", "test_Hz19.5-testing.bdf")
fname2 = joinpath(dirname(@__FILE__), "../../data", "test_Hz19.5-copy.bdf")

cp(fname, fname2, remove_destination = true)  # So doesnt use .mat file

s = read_SSR(fname2)

@test samplingrate(s) == 8192.0
@test samplingrate(Int, s) == 8192
@test isa(samplingrate(s), AbstractFloat)
@test isa(samplingrate(Int, s), Int)

@test modulationrate(s) == 19.5
@test isa(modulationrate(s), AbstractFloat)

s = merge_channels(s, "Cz", "MergedCz")
s = merge_channels(s, ["Cz" "10Hz_SWN_70dB_R"], "Merged")


s2 = hcat(deepcopy(s), deepcopy(s))

@test size(s2.data, 1) == 2 * size(s.data, 1)
@test size(s2.data, 2) == size(s.data, 2)

    keep_channel!(s, ["Cz" "10Hz_SWN_70dB_R"])

@test_throws ArgumentError hcat(s, s2)

#
# Test removing channels
#

s = read_SSR(fname)
s = extract_epochs(s)
s = create_sweeps(s, epochsPerSweep = 2)

s2 = deepcopy(s)
remove_channel!(s2, "Cz")
@test size(s2.data, 2) == 5
@test size(s2.processing["epochs"], 3) == 5
@test size(s2.processing["epochs"], 1) == size(s.processing["epochs"], 1)
@test size(s2.processing["epochs"], 2) == size(s.processing["epochs"], 2)
@test size(s2.processing["sweeps"], 3) == 5
@test size(s2.processing["sweeps"], 1) == size(s.processing["sweeps"], 1)
@test size(s2.processing["sweeps"], 2) == size(s.processing["sweeps"], 2)

s2 = deepcopy(s)
remove_channel!(s2, ["10Hz_SWN_70dB_R"])
@test size(s2.data, 2) == 5

s2 = deepcopy(s)
remove_channel!(s2, [2])
@test size(s2.data, 2) == 5
@test s2.data[:, 2] == s.data[:, 3]

s2 = deepcopy(s)
remove_channel!(s2, 3)
@test size(s2.data, 2) == 5
@test s2.data[:, 3] == s.data[:, 4]

s2 = deepcopy(s)
remove_channel!(s2, [2, 4])
@test size(s2.data, 2) == 4
@test s2.data[:, 2] == s.data[:, 3]
@test s2.data[:, 3] == s.data[:, 5]
@test size(s2.processing["epochs"], 3) == 4
@test size(s2.processing["epochs"], 1) == size(s.processing["epochs"], 1)
@test size(s2.processing["epochs"], 2) == size(s.processing["epochs"], 2)
@test size(s2.processing["sweeps"], 3) == 4
@test size(s2.processing["sweeps"], 1) == size(s.processing["sweeps"], 1)
@test size(s2.processing["sweeps"], 2) == size(s.processing["sweeps"], 2)

s2 = deepcopy(s)
remove_channel!(s2, ["Cz", "10Hz_SWN_70dB_R"])
@test size(s2.data, 2) == 4



#
# Test frequency changes
#

f = assr_frequency([4, 10, 20, 40, 80])

@test f == [3.90625,9.765625,19.53125,40.0390625,80.078125]
