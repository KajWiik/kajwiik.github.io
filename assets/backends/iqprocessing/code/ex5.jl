# This file was generated, do not modify it. # hide
figure() # hide
plotspec(rf_sig, fs, (-10, 10))
title("RF signal spectrum");
gcf()
savefig(joinpath(@OUTPUT, "spectrum.svg")) # hide
#\fig{spectrum}