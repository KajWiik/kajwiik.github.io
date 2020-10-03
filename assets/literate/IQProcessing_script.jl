# This file was generated, do not modify it.

using DSP, PyPlot

const GHz = 1e9
fs = 32GHz;

h = remez(35, fs.*[0, 0.2, 0.25, 0.5], [0.5, 1], Hz = fs);
rf_sig = randn(1000000);
t = range(0, step = 1/fs, length = length(rf_sig))
rf_sig = rf_sig + 0.2*sin.(2*pi*6GHz*t) + 0.1*sin.(2*pi*9GHz*t);
rf_sig = filt(h, rf_sig);

function plotspec(sig, fs, limits)
    n = div(length(sig), 1024)
    noverlap = div(n, 2)
    pgram = welch_pgram(sig, n, noverlap)
    f = freq(pgram)
    p = power(pgram)
    i = sortperm(f)
    plt = plot(fs*f[i]/GHz, pow2db.(p[i]))
    ylim(limits...)
    xlabel("Frequency [GHz]")
    ylabel("Power [dB]")
    return plt
end

figure() # hide

plotspec(rf_sig, fs, (-10, 10))
title("Input signal spectrum");

savefig(joinpath(@OUTPUT, "spectrum.svg")) # hide

lo_sig = 8GHz*t;
baseband_sig = rf_sig.*exp.(im*2*pi*lo_sig);

responsetype = Lowpass(3.8GHz, fs=fs)
designmethod = Butterworth(20)
i = filt(digitalfilter(responsetype, designmethod), imag(baseband_sig))
q = filt(digitalfilter(responsetype, designmethod), real(baseband_sig));

i = i[1:4:end]
q = q[1:4:end];

figure() # hide
subplot(121)
plotspec(i, fs/4, (-15, 5))
title("Filtered I channel")
subplot(122)
plotspec(q, fs/4, (-15, 5))
title("Filtered Q channel")
tight_layout(pad=2.0)
savefig(joinpath(@OUTPUT, "iqspectrum.svg")) # hide

c = i + q.*im

figure() #hide
subplot(111)
plotspec(c, fs/4, (-20, 0))
title("Complex baseband signal spectrum");
savefig(joinpath(@OUTPUT, "cspectrum.svg")) # hide
