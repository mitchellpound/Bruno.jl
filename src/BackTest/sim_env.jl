using DataFrames
struct SimVariable end
# struct Cash <: Asset end

Base.@kwdef struct SimulationEnvironment
    N::Int32
    timesteps_per_period::Int32
    window_size::Int32
    data::DataFrame = DataFrame()
    coltypes::Vector{DataType} = DataType[]
    starting_holdings::Dict{String, Float64} = Dict()
end

SimulationEnvironment(
    N, 
    timesteps_per_period, 
    window_size, 
    starting_cash, 
) = SimulationEnvironment(;
    N=N, 
    timesteps_per_period=timesteps_per_period, 
    window_size = window_size, 
    starting_holdings = Dict("cash" => starting_cash)
)

Base.firstindex(env::SimulationEnvironment) = 1 - env.window_size
Base.lastindex(env::SimulationEnvironment) = env.N

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
Base.getindex(env::SimulationEnvironment, string::AbstractString, i::Int) = env[[string], i]

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
Base.getindex(env::SimulationEnvironment, string::AbstractString, i::UnitRange{<:Int}) = env[[string], i]

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
Base.getindex(env::SimulationEnvironment, string::AbstractString, i::StepRange{<:Int}) = env[[string], i]

function Base.getindex(env::SimulationEnvironment, i::DataType)
    t = broadcast(<:, env.coltypes, i)
    env.data[:, t]
end

Base.setindex!(env::SimulationEnvironment, variable, string) = add_variable(env, variable, string)

get_variables(env::SimulationEnvironment) = env[SimVariable]
get_variable_names(env::SimulationEnvironment) = names(env[SimVariable])

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

function add_interest_rate(env::SimulationEnvironment, lend_interest, borrow_interest = lend_interest )
    add_variable(env, lend_interest, "lend_interest")
    add_variable(env, borrow_interest, "borrow_interest")
end

function add_variable(env::SimulationEnvironment, value, name)
    env.data[!, name] = fill(value, env.N+env.window_size)
    push!(env.coltypes, SimVAriable)
end

# assumes that the last entry is the furthest in the future (last of the simulation)
function add_variable(env::SimulationEnvironment, var_vec::Vector, name)
    @assert length(var_vec)>=env.N "not enough variable entries for simulation"
    length(var_vec) <= env.N + env.window_size ? nothing : var_vec = var_vec[end-env.N-env.window_size+1:end]

    # add zeros to the end of the variable vector if it's not long enough
    if length(var_vec) < env.N + env.window_size
        var_vec = vcat(zeros(eltype(var_vec), env.N + env.window_size - length(var_vec)), var_vec) #TODO: Make missing instead of zeros()
    end

    # add variable to the sim env dataframe
    env.data[!, name] = var_vec 
    push!(env.coltypes, SimVariable)
end

# adds a variable that is a function of some other variable or asset
function add_variable(f::Function, env::SimulationEnvironment, access_name::String, var_name, args...)
    
    # get variables from access_name
    temp = env[access_name]
        
    # run the function on the variable from access_name
    var_vec = f(temp, args...)

    # put the new vector into the SimulationEnvironment
    add_variable(env, var_vec, var_name)
end
    

function add_asset(
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
    push!(env.coltypes, asset_type)
    
    # add volatility to variables
    add_variable(volatility_history, env, name, "$(name)_volatility", env.timesteps_per_period, env.window_size) 

    # add to holdings dataframe
    env.starting_holdings[name] = starting_holdings
end

function test_strategy(strategy::Function, env)
    # build out holdings dataframe with starting holdings
    ts_holdings = DataFrame()
    for key in keys(env.starting_holdings)
        ts_holdings[!, key] = vcat([env.starting_holdings[key]], fill(missing, env.N - 1))    
    end

    for step in 1:(env.N)
        # run strategy for each timestep
        strategy(ts_holdings, step, env) 

        
        


        # pay/ get interest for time period
        if ts_holdings[step, "cash"] >= 0
            ts_holdings[step+1, "cash"] = exp(env[hold_return_int_rate] / env.timesteps_per_period)
        else
            holdings["cash"] *= exp(pay_int_rate / timesteps_per_period)
        end



    end


    
end



macro environment_setup(strings)
    symbols = []
    for str in strings
        sym = Symbol(str)
        push!(symbols, sym)
        esc(:(($sym,) = env.data[$str]))
    end
    quote
        function buy(name::String, number::Int)
            # Code here about how to get things into the buy
            # holdings[name] += number
        end
        function sell(name::String, number::Int)
            # Code here about how to sell things
        end
        $(symbols...)
    end
end
