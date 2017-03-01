using DataFrames

mdata = readtable("original_data/mdata.csv")
qdata = readtable("original_data/qdata.csv")

# y/y log change in GDP, CPI, and IPindex
GDP = (log(qdata[:GDPlev][5:end]) - log(qdata[:GDPlev][1:(end - 4)]))*100
INFL = (log(mdata[:CPI][13:end]) - log(mdata[:CPI][1:(end - 12)]))*100
IP = (log(mdata[:INDPRO][13:end]) - log(mdata[:INDPRO][1:(end - 12)]))*100

mdata_processed = DataFrame(date = mdata[:date][13:end], IP = IP, INFL = INFL, UNEMP = mdata[:UNEMP][13:end])
qdata_processed = DataFrame(date = qdata[:date][5:end], GDP = GDP)

writetable("importable_data/mdata_processed.csv", mdata_processed)
writetable("importable_data/qdata_processed.csv", qdata_processed)
