using Plots
using DSP

include("../src/readfiles.jl")
include("../scripts/onelead.jl")

binfile = "D:/INCART/Pulse_Data/все базы/Шумовая база/Абасова_16-01-21_13-36-57_.bin"
signals, fs, timestart, units = readbin(binfile)

sig = signals[1][374601:447719]
plot(sig)

responsetype = Lowpass(35; fs=fs)
designmethod = Butterworth(4)
fsig = filt(digitalfilter(responsetype, designmethod), sig)
fsig = fsig[1000:end]

res = LeadMarkup(fsig, fs)

P = res.P
R = res.R
T = res.T

plot(fsig)

responsetype = Highpass(5; fs=fs)
designmethod = Butterworth(4)
ffsig = filt(digitalfilter(responsetype, designmethod), fsig)

plot!(ffsig.+mean(fsig))

scatter!(P, fsig[P], markersize = 1)
scatter!(R, fsig[R], markersize = 1)
scatter!(T, fsig[T], markersize = 1)

xlims!(50000,55000)