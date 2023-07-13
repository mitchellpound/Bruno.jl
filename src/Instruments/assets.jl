abstract type PriceType end

struct StaticPrice{U,V} <: PriceType
    price::U
    volatility::V

    StaticPrice(price, volatility) = volatility < 0 ? 
        error("volatility must be non-negative") : 
        new{typeof(price), typeof{volatility}}(price, volatility)
end

struct HistoricPrices{T, TI} <: PriceType
    prices::Vector{T}
    timesteps_per_period::TI

    HistoricPrices(prices, timesteps_per_period) = timesteps_per_period < 0 ? 
        error("timesteps_per_period must be non-negative") : 
        new{eltype(prices), typeof{timesteps_per_period}}(prices, timesteps_per_period)
end

HistoricPrices(prices) = HistoricPrices(prices, size(prices)[1])
PriceType(price, volatility) = StaticPrice(price, volatility)
PriceType(prices::Vector, timesteps_per_period) = HistoricPrices(prices, timesteps_per_period)
PriceType(prices::Vector) = HistoricPrices(prices)
# need these to make kwargs work with the BaseAsset outer constructors
function PriceType(price, volatility, _...) 
    volatility === nothing ? 
    error("must specify volatility") :
    StaticPrice(price, volatility)
end

function PriceType(prices::Vector, _, time_steps_per_period, _...) 
    time_steps_per_period === nothing ?
    HistoricPrices(prices) :
    HistoricPrices(prices, time_steps_per_period)
end

# abstract type HistoricTrait end
# struct IsHistoric <: HistoricTrait end
# struct NotHistoric <: HistoricTrait end

# HistoricTrait(::StaticPrice) = NotHistoric()
# HistoricTrait(::HistoricPrices) = IsHistoric()

# with these types prices can now be extended. Eventually we can add a TimeArray price vector

function get_volatility(prices::Vector, timesteps_per_period)
    length(prices) > 2 ? nothing :
    # need at least three values so std can work
    return error("Must have at least three values to calculate the volatility")  
    returns = [((prices[i+1] - prices[i]) / prices[i]) + 1 for i = 1:(length(prices)-1)]
    cont_return = log.(returns)
    std(cont_return, corrected = false) * sqrt(timesteps_per_period)
end

get_volatility(p::HistoricPrices) = get_volatility(p.prices, p.timesteps_per_period)
get_volatility(p::StaticPrice) = p.volatility

abstract type Asset end
abstract type BaseAsset <: Asset end

# ------ Stocks ------
""" 
    Stock <: Widget

Widget subtype. Used as a base or root asset for financial instrument.
"""
struct Stock <: BaseAsset
    prices::PriceType
    name::String

    Stock(prices::PriceType, name = "") = new(prices, name)
end

Stock(price, volatility, name = "") = Stock(StaticPrice(price, volatility), name)
Stock(prices::Vector, timesteps_per_period = size(prices)[1], name = "") = Stock(HistoricPrices(prices, timesteps_per_period), name)

function Stock(;prices, volatility = nothing, timesteps_per_period = nothing, name = "") 
    if isa(prices, PricesType)
        return Stock(prices, name)
    end
    return Stock(PriceType(prices, volatility, timesteps_per_period), name)
end

"""
    Stock(prices, name, timesteps_per_period, volatility)
    Stock(price; kwargs...)
    Stock(;kwargs)

Construct a Stock type to use as a base asset for FinancialInstrument.

## Arguments
- `prices`:Historical prices (input as a 1-D array) or the current price input as a number `<: Real`
- `name::String`: Name of the stock or stock ticker symbol. Default "".
- `timesteps_per_period::Int64`: For the size of a timestep in the data, the number of 
time steps for a given period of time, cannot be negative. For example, if the period of 
interest is a year, and daily stock data is used, `timesteps_per_period=252`. Default is 
length of the `prices` array or 0 for single price (static) stock. 
Note: If `timesteps_per_period=0`, the Stock represents a 'static' element and cannot be 
used in the `strategy_returns()` method.
- `volatility`: Return volatility, measured in the standard deviation of continuous returns.
Defaults to using `get_volatility()` on the input `prices` array. Note: if a single number 
is given for `prices` volatility must be given.

## Examples
```julia
Stock([1,2,3,4,5], "Example", 252, .05)

kwargs = Dict(
    :prices => [1, 2, 3, 4, 5], 
    :name => "Example", 
    :timesteps_per_period => 252, 
    :volatility => .05
);

Stock(;kwargs...)

Stock(40; volatility=.05)
```
"""
