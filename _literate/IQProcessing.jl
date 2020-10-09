# # Wideband direct conversion IF stages for the RFSoC
# Recently a number of microwave (2.5 - 45 GHz) IQ downconverters targeted to the 5G wireless network have appeared on the market, e.g. [HMC8193](https://www.analog.com/en/products/hmc8193.html), [HMC904](https://www.analog.com/en/products/hmc904.html), [HMC977](https://www.analog.com/en/products/hmc977.html), [ADMV1012](https://www.analog.com/en/products/admv1012.html), and [ADMV1014](https://www.analog.com/en/products/admv1014.html). An evaluation board is available for all these chips, so only interface to the RFSoC (e.g. the [ZCU111](https://www.xilinx.com/products/boards-and-kits/zcu111.html) evaluation board) ADC's is needed to be designed and built in-house in order to experiment with them.

# ~~~
# <img src="/assets/backends/iqprocessing/EV1HMC8193LC4ANGLE-web.png" alt="HMC8193_eval" style="width:500px;"/>
# ~~~

# __*Fig 1:*__ *HMC8193 evaluation board*


# Building a wideband receiver for radio astronomy would be quite easy with these devices. Concepts for 4 - 8 (4 GHz bandwidth, one polarization channel), 22 and 37/43 GHz (8 GHz bandwidth, one polarization channel) receivers are shown in Figs 2 - 4.

# \figalt{IQ-IF-22}{./IQ-IF-6.svg}
# __*Fig 2:*__ *4 - 8 GHz receiver*

# \figalt{IQ-IF-22}{./IQ-IF-22.svg}
# __*Fig 3:*__ *22  GHz receiver*

# \figalt{IQ-IF-43}{./IQ-IF-43.svg}
# __*Fig 4:*__ *37/43 GHz receiver*

# Of course these designs can be used also at IF for higher frequency receivers (86 GHz and up).

# For simplicity the RFSoC 4GS/s ADC's (total of eight in a chip) are used in an interleaved mode in the versions with 8 GHz bandwidth to increase the total speed to 8 GS/s and 4 GHz bandwidth per channel. This is possible because analog bandwidth of these converters is 4 GHz. Because both the I and Q channels are digitized, the total bandwidth is 8 GHz. There is a support for I/Q phase/amplitude equalisation and synchronisation in the RFSoC.

# It should be noted that in the examples above, some of the chips are used slightly beyond specifications, not in a way that the performance (mainly IF response from DC and up to 4 GHz) is known to be bad outside specs but that the values are not shown in the datasheets. These values can easily be measured during the design process. Slight droops in the response can of course be calibrated out in the firmware (ADC's have 12 bit dynamic range)).


# # Digitizing IQ streams

# To clarify IQ mixing and conversion process, here is a simple simulation written in [Julia language](https://julialang.org).

# Let's first load some libraries:

using DSP, PyPlot

# Set up sampling rate at the input port, this is large enough to express the 16 GHz IF band. In reality, this signal is in the analog domain.

const GHz = 1e9
fs = 32GHz;

# Then a test signal is generated by filtering some white noise and adding two sinusoids (6 GHz and 9 GHz).

h = remez(35, fs.*[0, 0.2, 0.25, 0.5], [0.5, 1], Hz = fs);
rf_sig = randn(1000000);
t = range(0, step = 1/fs, length = length(rf_sig))
rf_sig = rf_sig + 0.2*sin.(2*pi*6GHz*t) + 0.1*sin.(2*pi*9GHz*t);
rf_sig = filt(h, rf_sig);


# A convenience function for plotting spectrum:

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

# The resulting test signal looks like this:
figure() # hide

plotspec(rf_sig, fs, (-10, 10))
title("Input signal spectrum");

savefig(joinpath(@OUTPUT, "spectrum.svg")) # hide

# \figalt{spectrum}{spectrum.svg}

# The input signal is then mixed (multiplied) with a complex local oscillator (LO) signal at 8 GHz producing a complex baseband signal:

lo_sig = 8GHz*t;
baseband_sig = rf_sig.*exp.(im*2*pi*lo_sig);

# Before AD conversion, the baseband signal must be lowpass filtered to 0 - 4 GHz (Nyquist):

responsetype = Lowpass(3.8GHz, fs=fs)
designmethod = Butterworth(20)
i = filt(digitalfilter(responsetype, designmethod), imag(baseband_sig))
q = filt(digitalfilter(responsetype, designmethod), real(baseband_sig));

# In this simulation, AD conversion is expressed as decimation, i.e. only every fourth sample is preserved. Now the sample rate of each of the streams is (32/4 GS/s =) 8 GS/s, i.e. the sample rate of two interleaved ADC's in the RFSoC.

i = i[1:4:end]
q = q[1:4:end];

# Here are spectra of the digitized I and Q streams. The amplitude spectra seem to be identical and summed version of the upper and lower basebands (phase differs).

figure() # hide
subplot(121)
plotspec(i, fs/4, (-15, 5))
title("Filtered I channel")
subplot(122)
plotspec(q, fs/4, (-15, 5))
title("Filtered Q channel")
tight_layout(pad=2.0)
savefig(joinpath(@OUTPUT, "iqspectrum.svg")) # hide

# \figalt{iqspectrum}{iqspectrum.svg}

# Let's combine the streams to a complex signal:

c = i + q.*im

# Spectrum of the complex signal is a good representation of the original signal around LO at 8 GHz:

figure() #hide
subplot(111) 
plotspec(c, fs/4, (-20, 0))
title("Complex baseband signal spectrum");
savefig(joinpath(@OUTPUT, "cspectrum.svg")) # hide

# \figalt{cspectrum}{cspectrum.svg}


