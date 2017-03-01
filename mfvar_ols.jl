using DataFrames
using VectorAutoregression
using Plots
pyplot()
default(show=true, reuse=false)

qdata = readtable("importable_data/qdata_processed.csv")
mdata = readtable("importable_data/mdata_processed.csv")

# # Aggregate monthly data to quarterly by taking final month values
# finaldata = mdata[collect(range(3,3,length(GDP))),:]
# finaldata[:GDP] = GDP

mfvar_out = VectorAutoregression.var_mf_ols(qdata, mdata, 3, 1)
irfs = VectorAutoregression.oirf(mfvar_out, 20)
varnames = VectorAutoregression.varnames(mfvar_out)

ipshock1 = irfs[1][10, :, 1]
ipshock2 = irfs[1][10, :, 4]
ipshock3 = irfs[1][10, :, 7]
plot(ipshock1, legend=false, linewidth=2)
plot!(ipshock2, legend=false, linewidth=2)
plot!(ipshock3, legend=false, linewidth = 2)
savefig("ipshock.pdf")

inflshock1 = irfs[1][10, :, 2]
inflshock2 = irfs[1][10, :, 5]
inflshock3 = irfs[1][10, :, 8]
plot(inflshock1, legend=false, linewidth=2)
plot!(inflshock2, legend=false, linewidth=2)
plot!(inflshock3, legend=false, linewidth = 2)

unempshock1 = irfs[1][10, :, 3]
unempshock2 = irfs[1][10, :, 6]
unempshock3 = irfs[1][10, :, 9]
plot(unempshock1, legend=false, linewidth=2)
plot!(unempshock2, legend=false, linewidth=2)
plot!(unempshock3, legend=false, linewidth = 2)
