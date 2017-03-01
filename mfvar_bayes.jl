using DataFrames
using VectorAutoregression
using Distributions
using Plots
pyplot()
default(show=true, reuse=false)

# ------------------------------------------------------------------------------------------
# Import Data
# ------------------------------------------------------------------------------------------
qdata = readtable("importable_data/qdata_processed.csv")
mdata = readtable("importable_data/mdata_processed.csv")
# Convert from DataFrame to Array
qdatamat = Matrix(qdata[[:GDP]])
mdatamat = Matrix(mdata[[:IP, :INFL, :UNEMP]])
# Dimensions
Kl = size(qdatamat, 2)
Kh = size(mdatamat, 2)
m = 3
lags = 1
constant = true
trend = false
nsave = 5000
nburn = 1000
h = 20
# Create the mixed-frequency matrix of endogenous variables
Ymix = mixed_freq_matrix(qdatamat, mdatamat, m)

# Aggregate monthly data to quarterly by taking final month values
aggregatedata = mdata[collect(range(3,3,length(qdata[:GDP]))) , :]
aggregatedata[:GDP] = qdata[:GDP]
Yagg = Matrix(aggregatedata[[:IP, :INFL, :UNEMP, :GDP]])

# ------------------------------------------------------------------------------------------
# Specify prior for coefficient matrix : Assuming all variables are AR(1) only
# ------------------------------------------------------------------------------------------

# AR coefficients for high-freq variables
rho_ip = 0.0
rho_infl = 0.9
rho_unemp = 0.9
rhos = [rho_ip, rho_infl, rho_unemp]
# AR coefficient for low-freq variable(s)
a = 0.0
# Initialize coefficient matrix
Aprior = zeros(Kh*m+Kl, Kh*m+Kl)
# Fill in high-freq block
Aprior[1:3, 7:9] = diagm(rhos)
Aprior[4:6, 7:9] = diagm(rhos.^2)
Aprior[7:9, 7:9] = diagm(rhos.^3)
# Fill in low-freq block
Aprior[10:10] = a
# Add constant term
if constant
    Aprior = hcat(zeros(Kh*m + Kl), Aprior)
end

# ------------------------------------------------------------------------------------------
# Specify prior for variance of coefficient matrix
# ------------------------------------------------------------------------------------------

# Hyperparameters
lambda = 1.0    # regulates tightness of prior: larger = higher-variance prior
vartheta = 1.0  # regulates effect of low-freq variables on high-freq variables: larger = higher-variance prior
# Initialize matrix
Vprior = zeros(Kh*m+Kl, Kh*m+Kl)
# prior variance on time (t-1) lags of the high-freq variables
for a = 1:m:Kh*m
    for b = 1:m:(Kh*(m-1))
        denom = (m - (div(b, m) + 1) + (div(a, m) + 1))^2
        Vprior[a:a+m-1, b:b+m-1] = ((lambda^2)/denom)*ones(Kh,Kh)
    end
end
# prior variance on AR coefficients for high-freq variables
for a = 1:m:Kh*m
    b = Kh*(m-1)+1
    denom = (div(a, m) + 1)^2
    Vprior[a:a+m-1, b:b+m-1] = ((lambda^2)/denom)*ones(Kh,Kh)
end
# prior for variance of effect of low-freq variables on high-freq variables
# Note: missing a scaling ratio S_hl present Ghysels (2016) (equiv., assuming S_hl = 1 for all)
for a = 1:m:Kh*m
    b = Kh*m + 1
    denom = (div(a, m) + 1)^2
    Vprior[a:a+m-1, b] = vartheta*((lambda^2)/denom)*ones(Kh)
end
# prior variance for coeffecients in low-freq block:
# 1) effect of high-freq variables on low-freq varables
for b = 1:m:Kh*m
    a = Kh*m + 1
    denom = (m - (div(b, m) + 1) + 1)^2
    Vprior[a:end, b:b+m-1] = ((lambda^2)/denom)*ones(Kl, Kh)
end
# 2) variance of low-freq AR coefficient
Vprior[Kh*m + 1, Kh*m + 1] = (lambda^2)/(m^2)
if constant
    const_var = (lambda^2)/(m^2)*ones(Kh*m + Kl)
    Vprior = hcat(const_var, Vprior)
end
# Transpose so they're in the proper orientation
Aprior = Aprior'
Vprior = Vprior'
# ------------------------------------------------------------------------------------------
# End prior specification
# ------------------------------------------------------------------------------------------

# Estimate MF-BVAR with default Independent Normal-Wishart prior
# varout = BVAR(Ymix, lags, constant, trend, nsave, nburn, [""])

# Estimte MF-BVAR with specified priors
var_mix = BVAR(Ymix, lags, constant, trend, nsave, nburn, [""]; Aprior=Aprior, Vprior=Vprior)

# Estimate BVAR with aggregate data
var_agg = BVAR(Yagg, lags, constant, trend, nsave, nburn, [""])

# IP Shock
# ------------------------------------------------------------------------------------------
# Calculate IRFs for MF-BVAR
irf_mix1 = VectorAutoregression.irf_bvar(var_mix, h, 1, 10)
irf_mix2 = VectorAutoregression.irf_bvar(var_mix, h, 4, 10)
irf_mix3 = VectorAutoregression.irf_bvar(var_mix, h, 7, 10)
# Calculate IRFs for BVAR with aggregate data
irf_agg1 = VectorAutoregression.irf_bvar(var_agg, h, 1, 4)

plot(irf_mix1[:point],  linewidth=2, label="Q1 shock", title="Response of GDP to IP shock")
plot!(irf_mix2[:point], linewidth=2, label="Q2 shock")
plot!(irf_mix3[:point], linewidth=2, label="Q3 shock")
plot!(irf_agg1[:point], linewidth=2, label="Aggregate VAR", color=:black)
plot!(irf_agg1[:lower], linewidth=2, linestyle=:dash, color=:black, label="")
plot!(irf_agg1[:upper], linewidth=2, linestyle=:dash, color=:black, label="")
savefig("IPshock.pdf")

# INFL Shock
# ------------------------------------------------------------------------------------------
# Calculate IRFs for MF-BVAR
irf_mix1 = VectorAutoregression.irf_bvar(var_mix, h, 2, 10)
irf_mix2 = VectorAutoregression.irf_bvar(var_mix, h, 5, 10)
irf_mix3 = VectorAutoregression.irf_bvar(var_mix, h, 8, 10)
# Calculate IRFs for BVAR with aggregate data
irf_agg1 = VectorAutoregression.irf_bvar(var_agg, h, 2, 4)

plot(irf_mix1[:point],  linewidth=2, label="Q1 shock", title="Response of GDP to INFL shock")
plot!(irf_mix2[:point], linewidth=2, label="Q2 shock")
plot!(irf_mix3[:point], linewidth=2, label="Q3 shock")
plot!(irf_agg1[:point], linewidth=2, label="Aggregate VAR", color=:black)
plot!(irf_agg1[:lower], linewidth=2, linestyle=:dash, color=:black, label="")
plot!(irf_agg1[:upper], linewidth=2, linestyle=:dash, color=:black, label="")
savefig("INFLshock.pdf")

# UNEMP Shock
# ------------------------------------------------------------------------------------------
# Calculate IRFs for MF-BVAR
irf_mix1 = VectorAutoregression.irf_bvar(var_mix, h, 3, 10)
irf_mix2 = VectorAutoregression.irf_bvar(var_mix, h, 6, 10)
irf_mix3 = VectorAutoregression.irf_bvar(var_mix, h, 9, 10)
# Calculate IRFs for BVAR with aggregate data
irf_agg1 = VectorAutoregression.irf_bvar(var_agg, h, 3, 4)

plot(irf_mix1[:point],  linewidth=2, label="Q1 shock", title="Response of GDP to UNEMP shock")
plot!(irf_mix2[:point], linewidth=2, label="Q2 shock")
plot!(irf_mix3[:point], linewidth=2, label="Q3 shock")
plot!(irf_agg1[:point], linewidth=2, label="Aggregate VAR", color=:black)
plot!(irf_agg1[:lower], linewidth=2, linestyle=:dash, color=:black, label="")
plot!(irf_agg1[:upper], linewidth=2, linestyle=:dash, color=:black, label="")
savefig("UNEMPshock.pdf")
