export SimulationEnvironment, add_asset!, add_variable!, add_interest_rate!
export SimVariable, get_type
using DataFrames
using SparseArrays

struct SimVariable end
# struct Cash <: Asset end

# TODO: Change to be parametric general type inference
#=
TODO list:
x - Figure out coltypes in struct and add_asset functs
x - Make sure all the add_asset functs work
- Write tests for add_asset
- Check on returned types for m[~~] 
    - Are they vectors or DataFrames? prefer vectors
x - Make easy add_asset(struct) functions w/ asset getter funcs
- Make sure buy/sell and ts_holdings works for derivatives
- Make value tracker for ts_holdings inside test_strategy
- Make/ run some tests on the whole SimEnv ecosystem
- Change SimulationEnvironment to be generalized parametric type
- Test to see if Base.axes() overload really worked
=#
Base.@kwdef struct SimulationEnvironment{TI, TF}
    N::TI
    timesteps_per_period::TI
    window_size::TI
    data::DataFrame = DataFrame()
    coltypes:: Dict{String, DataType} = Dict()
    typecols::Dict{DataType, Vector{String}} = Dict(SimVariable => [])
    starting_holdings::Dict{String, TF} = Dict()
end

# TODO: Add better variety of constructors 
function SimulationEnvironment(
    N, 
    timesteps_per_period, 
    window_size, 
    starting_cash, 
    )   
    env = SimulationEnvironment{typeof(N), Float64}(;
        N=N, 
        timesteps_per_period=timesteps_per_period, 
        window_size = window_size, 
        starting_holdings = Dict("cash" => starting_cash))
        add_interest_rate!(env, zeros(Float64, N+window_size)
    )
    return env
end

# ------- SimulationEnvironment getters --------------
Base.firstindex(env::SimulationEnvironment) = 1 - env.window_size
Base.lastindex(env::SimulationEnvironment) = env.N
Base.axes(env::SimulationEnvironment, i::Int64) = -env.window_size+1:env.N

# TODO: Fix BoundsError messages
Base.getindex(env::SimulationEnvironment, string::AbstractString) = env.data[!,string]
Base.getindex(env::SimulationEnvironment, i::AbstractArray{<:AbstractString}) = env.data[!, i]

function Base.getindex(env::SimulationEnvironment, current_time::Int)
    current_time >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    current_time <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[current_time + env.window_size, :]
end

function Base.getindex(env::SimulationEnvironment, vec::AbstractArray{<:AbstractString}, current_time::Int)
    current_time >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    current_time <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[current_time + env.window_size, vec]
end

function Base.getindex(env::SimulationEnvironment, string::AbstractString, i::Int)
    i >= -env.window_size ? nothing : throw(BoundsError(env, i))
    i <= env.N ? nothing : throw(BoundsError(i , "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i + env.window_size, string]
end

function Base.getindex(env::SimulationEnvironment, i::UnitRange{<:Int})
    i.start >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    i.stop <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i.start + env.window_size:i.stop + env.window_size, :]
end

function Base.getindex(env::SimulationEnvironment, vec::AbstractArray{<:AbstractString}, i::UnitRange{<:Int})
    i.start >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    i.stop <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i.start + env.window_size:i.stop + env.window_size, vec]
end

function Base.getindex(env::SimulationEnvironment, string::AbstractString, i::UnitRange{<:Int})
    i.start >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    i.stop <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i.start + env.window_size:i.stop + env.window_size, string]
end

function Base.getindex(env::SimulationEnvironment, i::StepRange{<:Int})
    i.start >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    i.stop <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i.start + env.window_size:i.step:i.stop + env.window_size, :]
end

function Base.getindex(env::SimulationEnvironment, vec::AbstractArray{<:AbstractString}, i::StepRange{<:Int})
    i.start >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    i.stop <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i.start + env.window_size:i.step:i.stop + env.window_size, vec]
end
function Base.getindex(env::SimulationEnvironment, string::AbstractString, i::StepRange{<:Int})
    i.start >= -env.window_size ? nothing : throw(BoundsError(current_time, "can only index in at time steps along the"))
    i.stop <= env.N ? nothing : throw(BoundsError(current_time, "attepted to access prices beyond SimulationEnvironment capacity"))

    env.data[i.start + env.window_size:i.step:i.stop + env.window_size, string]
end

#TODO: finish this
function Base.getindex(env::SimulationEnvironment, i::DataType)
    get_all_of_type
end

Base.setindex!(env::SimulationEnvironment, variable, string) = add_variable!(env, variable, string)

get_variables(env::SimulationEnvironment) = env[SimVariable]
get_variable_names(env::SimulationEnvironment) = names(env[SimVariable])


get_type(env::SimulationEnvironment, name) = env.coltypes[name]
get_all_of_type(env::SimulationEnvironment, type) = nothing

function get_subtypes(env::SimulationEnvironment, type) 
    cols = []
    for key in keys(env.typecols)
        if key <: type
            push!(cols, env.typecols[key]...)
        end
    end
    return cols
end

# ------------------- SimulationEnvironment show funcs ------------

# function Base.show(io::IO, e::SimulationEnvironment{T}) where{T}
#     println("SimulationEnvironment{$T}")
#     println("  Assets")
#     for key in keys(e.asset_names)
#         println("    $key")
#     end
#     println("  Variables")
#     for key in keys(e.variable_names)
#         println("    $key")
#     end
# end

# -------------- SimulationEnvironment add functions -----------
# lend interest is interest rate you get on your savings
# borrow interest is the rate you pay on negative balances
function add_interest_rate!(env::SimulationEnvironment, lend_interest, borrow_interest = lend_interest )
    add_variable!(env, lend_interest, "lend_interest")
    add_variable!(env, borrow_interest, "borrow_interest")
end

function add_variable!(env::SimulationEnvironment, value, name)
    env.data[!, name] = fill(value, env.N+env.window_size)
    env.coltypes[name] = SimVariable
    push!(env.typecols[SimVariable], name)
end

# assumes that the last entry is the furthest in the future (last of the simulation)
function add_variable!(env::SimulationEnvironment, var_vec::AbstractArray, name)
    @assert length(var_vec)>=env.N "not enough variable entries for simulation"
    length(var_vec) <= env.N + env.window_size ? nothing : var_vec = var_vec[end-env.N-env.window_size+1:end]

    # add zeros to the end of the variable vector if it's not long enough
    if length(var_vec) < env.N + env.window_size
        var_vec = vcat(zeros(eltype(var_vec), env.N + env.window_size - length(var_vec)), var_vec) #TODO: Make missing instead of zeros()
    end

    # add variable to the sim env dataframe
    env.data[!, name] = var_vec 

    # add type data to sim env
    env.coltypes[name] = SimVariable
    push!(env.typecols[SimVariable], name)
    # push!(env.coltypes, SimVariable)
end

# adds a variable that is a function of some other variable or asset
function add_variable!(f::Function, env::SimulationEnvironment, access_name::String, var_name, args...)
    
    # get variables from access_name
    temp = env[access_name]
        
    # run the function on the variable from access_name
    var_vec = f(temp, args...)

    # put the new vector into the SimulationEnvironment
    add_variable!(env, var_vec, var_name)
end
    
add_asset!(env::SimulationEnvironment, asset::BaseAsset, future_prices, starting_holdings = 0) = 
    add_asset!(env, typeof(asset), price_vec(asset), future_prices, get_name(asset), starting_holdings)

function add_asset!(
    env::SimulationEnvironment,
    asset_type::Type{<:BaseAsset},
    historic_prices, 
    future_prices, 
    name,
    starting_holdings = 0)

    # check that there is enough prices 
    @assert size(future_prices)[1]>=env.N "Not enough future prices"
    @assert size(historic_prices)[1]>=env.window_size "Not enough historic prices"
    historic_prices = historic_prices[end - env.window_size+1:end]

    # add to SimulationEnvironment assets dataframe
    env.data[!, name] = reduce(vcat, [historic_prices, future_prices[1:env.N]])
    
    # add type data to env
    env.coltypes[name] = asset_type
    if asset_type in keys(env.typecols)
        push!(env.typecols[asset_type], name)
    else
        env.typecols[asset_type] = [name]
    end
    
    # add volatility to variables
    add_variable!(volatility_history, env, name, "$(name)_volatility", env.timesteps_per_period, env.window_size) 

    # add to holdings dataframe
    env.starting_holdings[name] = starting_holdings

    return "Rat 225"
end

function add_asset!(env, derivative::Derivative, pricing_model, starting_holdings = 0; future_prices = [], underlying_starting_holdings = 0)
    # if the underlying asset is already in the SimulationEnvironment
    if derivative.underlying.name in names(env.data)
        add_asset!(
            env, 
            typeof(derivative), 
            pricing_model, 
            derivative.underlying.name, 
            derivative.strike_price, 
            derivative.maturity, 
            derivative.label, 
            starting_holdings
        )
    # need to add unerlying as well as 
    else
        if isempty(future_prices)
            throw(ArgumentError("Future prices must be provided for a new stock"))
        end
        add_asset!(env, derivative.underlying, future_prices, underlying_starting_holdings)
        add_asset!(
            env, 
            typeof(derivative), 
            pricing_model, 
            derivative.underlying.name, 
            derivative.strike_price, 
            derivative.maturity, 
            derivative.label, 
            starting_holdings
        )
    end
    return "Rat 258"
end

function add_asset!(
    env::SimulationEnvironment,
    asset_type::Type{<:Derivative}, 
    pricing_model, 
    underlying_name, 
    strike_price, 
    maturity,
    name, 
    starting_holdings = 0
)
    underlying = env[underlying_name]
    hist_volatil = env["$(underlying_name)_volatility"]
    risk_free = env["lend_interest"]
    
    # price out option with N time lags each time step
    prices = []
    for i in 1:env.N+1
        push!(prices, time_lag_price(
            pricing_model, 
            asset_type, 
            underlying[env.window_size-1+i], 
            strike_price, 
            hist_volatil[env.window_size-1+i], 
            risk_free[env.window_size-1+i], 
            maturity, 
            env.N, 
            env.timesteps_per_period)
        )
    end

    # add data to the sim environment
    env.data[!, name] = vcat(fill(missing, env.window_size-1), prices)
    # add type data to env
    # if the datatype is paramtetric, make sure it is a full datatype
    if !isa(asset_type, DataType)
        asset_type = asset_type{get_type(env, underlying_name), eltype(env[underlying_name])}
    end
    env.coltypes[name] = asset_type
    if asset_type in keys(env.typecols)
        push!(env.typecols[asset_type], name)
    else
        env.typecols[asset_type] = [name]
    end
    
    # add to env starting holds
    env.starting_holdings[name] = starting_holdings

    return
end

# ------------------ Using the strategy ---------------
# The actual meat of the SimulationEnvironment
function test_strategy(strategy!::Function, env)
    # build out holdings dataframe with starting holdings (setup)
    ts_holdings = DataFrame()
    ts_holdings[!, "cash"] = [env.starting_holdings["cash"]]

    for asset in get_subtypes(env, Asset)
        build_ts_holdings!(get_type(env, asset), asset,env, ts_holdings)
    end
    push!(ts_holdings, ts_holdings[end, :])

    # TODO: add value marker to ts_holdings

    for step in 1:(env.N)

        # run strategy for each timestep
        strategy!(env, step, ts_holdings)
        
        # copy prices for next round to change
        push!(ts_holdings, ts_holdings[end, :])

        # update holdings for derivatives
        update_holdings(
            for key in ts_holdings
                update_obj(env, key)
            end
        )

        # pay/ get interest for time period
        if ts_holdings[step, "cash"] >= 0
            ts_holdings[step+1, "cash"] *= exp(env.data[step, "lend_interest"] / env.timesteps_per_period)
        else
            ts_holdings[step+1, "cash"] *= exp(env.data[step, "borrow_interest"] / env.timesteps_per_period)
        end

    end
    return ts_holdings
end

function build_ts_holdings!(::Type{<:BaseAsset}, asset_name, env, ts_holdings)
    ts_holdings[!, asset_name] = [env.starting_holdings[asset_name]]
end

function build_ts_holdings!(::Type{<:Derivative}, asset_name, env, ts_holdings)
    ts_holdings[!, asset_name] = [spzeros(typeof(env.starting_holdings[asset_name]), env.N)]
    ts_holdings[1, asset_name][1] = env.starting_holdings[asset_name]
end
# ----------------- buy and sell functions for use in strategies ----------
function _buy(type::Type{<:BaseAsset}, name, number, env, step, ts_holdings)
    ts_holdings[step+1, "cash"] -= env.data[step, name] * number 
    ts_holdings[step+1, name] += number
end

function _buy(type::Type{<:Derivative}, name, number, env, step, ts_holdings)
    ts_holdings[step+1, "cash"] -= env.data[step, name]

end

function _sell(type::Type{<:BaseAsset},name, number, env, step, ts_holdings)
    ts_holdings[step+1, "cash"] += env.data[step, name] * number 
    ts_holdings[step+1, name] -= number
end

function _sell(type::Type{<:Derivative}, name, number, env, step, ts_holdings)

end
# ------------------ helpers ofr use in strategies -------------------------
macro environment_setup(env, step, ts_holdings)
    quote
        buy(name::AbstractString, number, args...) = _buy(get_type(name), name, number, $env, $step, $ts_holdings, args...)
        sell(name::AbstractString, number, args...) = _sell(get_type(name), name, number, $env, $step, $ts_holdings, args...)
    end
end

function assign_variables(env::SimulationEnvironment, step, names)
    for name in names
        @eval $(Symbol(name)) = env.data[begin:step, $name]
    end
end