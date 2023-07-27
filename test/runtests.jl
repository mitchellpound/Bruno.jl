using Test
using Bruno
using Distributions: Normal
using Statistics: mean
using HypothesisTests: ADFTest
using LinearAlgebra

include("baseassettests.jl")
include("fininsttests.jl")

include("datagentests.jl")
include("bootstraptests.jl")
# include("factorytest.jl")

include("pricingmodeltests.jl")

# include("hedgingtests.jl")
# include("simenvtests.jl")
