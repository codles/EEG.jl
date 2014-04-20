using JBDF
using EEGjl
using Winston

ChannelToAnalyse = 28;

dats, evtTab, trigChan, sysCodeChan = readBdf("../data/Example_40Hz_SWN_70dB_R.bdf")
bdfInfo = readBdfHeader("../data/Example_40Hz_SWN_70dB_R.bdf");
ChanName = bdfInfo["chanLabels"][ChannelToAnalyse]

dats = proc_hp(dats)

println("Referencing to $(bdfInfo["chanLabels"][48])")
dats = proc_rereference(dats, 48)

singleChan = convert(Array{Float64}, vec(dats[ChannelToAnalyse,8192*2:end]))
f = plot_timeseries(singleChan, 8192, titletext=ChanName)
file(f, "Eg1-RawData.png", width=1200, height=600)

epochs = proc_epochs(dats, evtTab)
epochs = epochs[:,3:end,:]

sweeps = proc_sweeps(epochs)

sweeps = squeeze(mean(sweeps,2),2)

singleChan = convert(Array{Float64}, vec(sweeps[:,ChannelToAnalyse]))
f = plot_spectrum(singleChan, 8192, titletext=ChanName)
file(f, "Eg1-SweepSpectrum.png", width=1200, height=600)
