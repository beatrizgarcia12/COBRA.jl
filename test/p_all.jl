#-------------------------------------------------------------------------------------------
#=
    Purpose:    Test all reactions (parallel)
    Author:     Laurent Heirendt - LCSB - Luxembourg
    Date:       October 2016
=#

#-------------------------------------------------------------------------------------------

using Base.Test

if !isdefined(:includeCOBRA) includeCOBRA = true end

# output information
testFile = @__FILE__

# number of workers
nWorkers = 4

# create a pool and use the COBRA module if the testfile is run in a loop
if includeCOBRA
    solverName = :GLPKMathProgInterface
    connectSSHWorkers = false
    include("$(dirname(@__FILE__))/../src/connect.jl")

    # create a parallel pool and determine its size
    if isdefined(:nWorkers) && isdefined(:connectSSHWorkers)
        workersPool, nWorkers = createPool(nWorkers, connectSSHWorkers)
    end

    using COBRA
    using Requests

    include("getTestModel.jl")
end

# download the ecoli_core_model
getTestModel()

# include a common deck for running tests
include("$(dirname(@__FILE__))/../config/solverCfg.jl")

# change the COBRA solver
solver = changeCobraSolver(solverName, solParams)

# load an external mat file
model = loadModel("$(dirname(@__FILE__))/ecoli_core_model.mat", "S", "model")

# select the number of reactions
rxnsList = 1:length(model.rxns)

minFluxT = [-2.542357461637039
            -2.542357461637039
            -3.813536192455565
             0.848587001219999
             0.848587001219999
            -3.813536192455565
                             0
                             0
            -1.430076072170838
            -2.214311337554841
             8.390000000000001
            34.825655310640002
             0.786529800000000
            -26.528831096100003
             0.848587001219999
            35.984903218817756
            -2.145114108256252
             8.686592417159998
            -2.214311337554841
                             0
                             0
                             0
            15.206556434392406
                             0
                             0
                             0
                             0
            -10.000000000000000
                             0
                             0
            15.777787788000069
            20.935954109512409
                             0
                             0
            -5.559968424258519
            -25.619523994320012
            -3.214895047684765
                             0
                             0
             1.171711973239997
                             0
                             0
                             0
                             0
                             0
            -0.512905973490859
                             0
                             0
             9.863240997959998
             9.046615951886109
             0.201115669860000
                             0
            -5.358852754398518
                             0
                             0
            -1.271178730818519
                             0
            -32.258228771220004
             0.848587001219999
                             0
            -2.145114108256252
                             0
                             0
            -3.249704488360005
                             0
                             0
            32.659177871419992
                             0
             4.288789693440000
            17.992451609408878
                             0
             1.171711973239997
                             0
            -14.299019113100011
            -17.909167832660000
                             0
            -16.732519251860001
             2.893407175260005
                             0
                             0
                             0
                             0
                             0
            -2.542357461637041
            -0.620909006871476
            -8.611284454940005
                             0
                             0
                             0
            -8.045926834700001
            -0.154536201070266
                             0
            -0.154536201070266
            -0.466372805801210
             1.171711973239997
            ]

maxFluxT = [0
            0
            0
            0.008894513835920
            0.008894513835920
            0
            0.017160912866050
            0.008045926834700
            0
            0
            0.025550912866050
            0.059381011244985
            0.000873921506968
            -0.015206556434392
            0.008894513835920
            0.051239047988640
            0
            0.016732519251860
            0
            0.003813536192456
            0.002542357461637
            0.001430076072171
            0.026528831096100
            0.002214311337555
            0.011322274661708
            0
            0
            -0.009046615951886
            0
            0.001271178730819
            0.027100062449708
            0.032258228771220
            0.002145114108256
            0
            -0.004288789693440
            -0.017992451609409
            -0.002893407175260
            0.002542357461637
            0.001674235401566
            0.009217638807940
            0.017160912866050
            0.068643651464200
            0.068643651464200
            1.000000000000000
            0
            0.008045926834700
            0
            0.024137780504100
            0.017909167832660
            0.010000000000000
            0.017362028535910
            0
            0.013073238842470
            0.017160912866050
            0.017160912866050
            0
            0.024137780504100
            -0.020935954109512
            0.008894513835920
            0.008045926834700
            0
            0.008045926834700
            0
            0.016091853669400
            0.011935837517263
            0.015318594740410
            0.051239047988640
            0.044759390689735
            0.005559968424259
            0.025619523994320
            0.019888197055060
            0.025290553320174
            0.011322274661708
            0.009838761391000
            -0.009863240997960
            0.024137780504100
            -0.008686592417160
            0.003214895047685
            0.020346778124675
            0.017160912866050
            0.017160912866050
            0.003813536192456
            0.021382900237218
            0
            0.015526496049160
            -0.000565357620240
            0.022881217154733
            0.022881217154733
            1.000000000000000
            0
            0.007905216653480
            0.037041821616640
            0.007905216653480
            0.007621279395680
            0.009217638807940
            ]

for s = 0:2
    # define an optPercentage value
    optPercentage = 90.0

    # launch the distributedFBA process
    startTime = time()
    minFlux, maxFlux, optSol = distributedFBA(model, solver, nWorkers, optPercentage, "max", rxnsList, s)
    solTime = time() - startTime

    # Test numerical values - test on floor as different numerical precision with different solvers
    @test floor(maximum(maxFlux)) == 1000.0
    @test floor(minimum(maxFlux)) == -21.0
    @test floor(maximum(minFlux)) == 35.0
    @test floor(minimum(minFlux)) == -33.0
    @test floor(norm(maxFlux))    == 1427.0
    @test floor(norm(minFlux))    == 93.0
    @test abs((model.c' * minFlux)[1] - optPercentage / 100.0 * optSol) < 1e-6

    # test each element of the minimum and maximum flux vectors
    for i = 1:length(minFlux)
        @test abs(minFluxT[i] - minFlux[i]) < 1e-3
        @test abs(maxFluxT[i]*1000 - maxFlux[i]) < 1e-3
    end

    # print a solution summary
    printSolSummary(testFile, optSol, maxFlux, minFlux, solTime, nWorkers, solverName)
end

# launch the distributedFBA process
startTime = time()
minFlux, maxFlux, optSol, fbaSol, fvamin, fvamax = distributedFBA(model, solver, nWorkers)
solTime = time() - startTime

# Test numerical values - test on floor as different numerical precision with different solvers
@test floor(maximum(maxFlux)) == 1000.0
@test floor(minimum(maxFlux)) == -30.0
@test floor(maximum(minFlux)) == 45.0
@test floor(minimum(minFlux)) == -30.0
@test floor(norm(maxFlux))    == 1414.0
@test floor(norm(minFlux))    == 106.0
@test abs((model.c' * minFlux)[1] - optSol) < 1e-6

# save the variables to the current directory
saveDistributedFBA("testFile.mat")

# remove the file to clean up
run(`rm testFile.mat`)

# print a solution summary
printSolSummary(testFile, optSol, maxFlux, minFlux, solTime, nWorkers, solverName)

# define model and solution parameters
optPercentage = 90.0
objective = "max"
maxtrixAS = "S"
modelName = "model"

# test to save individual result files (chunks)
saveChunks = true
strategy = 0

# select the number of reactions
rxnsList = 1:length(model.rxns)

# select the reaction optimization mode
rxnsOptMode = 2 + zeros(Int64, length(rxnsList))

minFlux, maxFlux, optSol, fbaSol, fvamin, fvamax, statussolmin, statussolmax = distributedFBA(model, solver, nWorkers, optPercentage, objective, rxnsList, strategy, rxnsOptMode, true, saveChunks)

# print a solution summary with full output
printSolSummary(testFile, optSol, maxFlux, minFlux, solTime, nWorkers, solverName, strategy, saveChunks)

# remove the results folder to clean up
run(`rm -rf $(dirname(@__FILE__))/../results`)

# create folders if they are not present
if !isdir("$(dirname(@__FILE__))/../results")
    mkdir("$(dirname(@__FILE__))/../results")
    print_with_color(:green, "Directory `results` created.\n\n")

    # create a folder for storing the chunks of the fluxes of each minimization
    if !isdir("$(dirname(@__FILE__))/../results/fvamin")
        mkdir("$(dirname(@__FILE__))/../results/fvamin")
    end

    # create a folder for storing the chunks of the fluxes of each maximization
    if !isdir("$(dirname(@__FILE__))/../results/fvamax")
        mkdir("$(dirname(@__FILE__))/../results/fvamax")
    end
else
    print_with_color(:cyan, "Directory `results` already exists.\n\n")
end

minFlux, maxFlux, optSol, fbaSol, fvamin, fvamax, statussolmin, statussolmax = distributedFBA(model, solver, nWorkers, optPercentage, objective, rxnsList, strategy, rxnsOptMode, true, saveChunks)

# print a solution summary with full output
printSolSummary(testFile, optSol, maxFlux, minFlux, solTime, nWorkers, solverName, strategy, saveChunks)

# output only the fluxes
minFlux, maxFlux = distributedFBA(model, solver, nWorkers, optPercentage, objective, rxnsList, strategy, rxnsOptMode, true, false,  "$(dirname(@__FILE__))/../results", false, true)

minFlux, maxFlux, optSol, fbaSol, fvamin, fvamax, statussolmin, statussolmax = distributedFBA(model, solver, nWorkers, optPercentage, objective, rxnsList, strategy, rxnsOptMode, true, false, "$(dirname(@__FILE__))/../results", false, true)

@test fvamin == zeros(2, 2)
@test fvamax == zeros(2, 2)
@test statussolmin == ones(Int, length(rxnsList))
@test statussolmax == ones(Int, length(rxnsList))

saveDistributedFBA("testFile.mat", ["minFlux", "maxFlux"])

# remove the file to clean up
run(`rm testFile.mat`)
