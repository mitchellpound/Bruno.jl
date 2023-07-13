# mutable struct SimulationEnvironment{T}
#     assets::Vector{Array{T}}
#     asset_names::Dict{Symbol, Tuple}
#     variables::
#     variable_names::Dict{Symbol, Int}
#     holdings::Vector{Array{TF}}
#     N::Int8
#     time_steps_per_period::Int8
# end

# function add_asset(
#     env::SimulationEnvironment,
#     asset_type,
#     historic_prices, 
#     future_prices, 
#     name,
#     volatility)

# end