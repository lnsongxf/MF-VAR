#=
Retieves data to replicate Chiu et al (2011) and Ghysels (2016)

From 1947 to 2011:

* Real GDP, quarterly (BEA)
* Industrial Production, monthly (FRED)
* CPI Inflation, monthly (BLS)
* Unemployment rate, monthly (BLS)

=#
using BeaData, FredData
using DataFrames

#--------- BEA Data
bea = Bea()
startyear = 1947
endyear = 2011
# Real GDP
nipa116 = get_nipa_table(bea, 6, "Q", startyear, endyear)
qdata = nipa116.df[[:date, :line1]]
rename!(qdata, :line1, :GDPlev)

#--------- FRED Data
fred = Fred()
startdate = "1947-01-01"
enddate = "2011-12-31"
# Unemployment rate
UNEMP_id = "UNRATE"
unemp_data = FredData.get_data(fred, UNEMP_id, observation_start = startdate, observation_end = enddate)
UNEMP = unemp_data.df[[:date, :value]]
rename!(UNEMP, :value, :UNEMP)
# CPI
CPI_id = "CPIAUCSL"
cpi_data = FredData.get_data(fred, CPI_id, observation_start = startdate, observation_end = enddate)
CPI = cpi_data.df[[:date, :value]]
rename!(CPI, :value, :CPI)
# Industrial Production
IP_id = "INDPRO"
ip_data = FredData.get_data(fred, IP_id, observation_start = startdate, observation_end = enddate)
INDPRO = ip_data.df[[:date, :value]]
rename!(INDPRO, :value, :INDPRO)

mdata = join(INDPRO, CPI,  on=:date, kind=:left)
mdata = join(mdata, UNEMP, on=:date, kind=:left)
sort!(mdata, cols = :date)

# Save Data
writetable("original_data/mdata.csv", mdata)
writetable("original_data/qdata.csv", qdata)
