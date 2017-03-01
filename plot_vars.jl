using DataFrames
using VectorAutoregression
using Plots
pyplot()
default(show=true, reuse=false)

qdata = readtable("importable_data/qdata_processed.csv")
mdata = readtable("importable_data/mdata_processed.csv")

l = @layout([a b; c d])
plot(plot(mdata[:,2], legend=false, title="IP"),
     plot(mdata[:,3], legend=false, title="INFL"),
     plot(mdata[:,4], legend=false, title="UNEMP"),
     plot(qdata[:,2], legend=false, title="GDP"))

savefig("variable_plots.pdf")
