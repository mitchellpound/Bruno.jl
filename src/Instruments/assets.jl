export PriceType, StaticPrice, HistoricPrices, HistoricTrait, IsHistoric, NotHistoric, checkhistoric
export price_vec, underlying, volatility_history, timesteps_per_period, BaseAsset
abstract type PriceType end

struct StaticPrice{U,V} <: PriceType
    price::U
    volatility::V

    StaticPrice(price, volatility) = volatility < 0 ? 
        error("volatility must be non-negative") : 
        new{typeof(price), typeof(volatility)}(price, volatility)
end

struct HistoricPrices{T, TI} <: PriceType
    prices::Vector{T}
    timesteps_per_period::TI

    HistoricPrices(prices, timesteps_per_period) = timesteps_per_period < 0 ? 
        error("timesteps_per_period must be non-negative") : 
        new{eltype(prices), typeof(timesteps_per_period)}(prices, timesteps_per_period)
end

HistoricPrices(prices) = HistoricPrices(prices, size(prices)[1])
PriceType(price, volatility) = StaticPrice(price, volatility)
PriceType(prices::AbstractArray, timesteps_per_period) = HistoricPrices(prices, timesteps_per_period)
PriceType(prices::AbstractArray) = HistoricPrices(prices)

price_vec(p::HistoricPrices) = p.prices
price_vec(::StaticPrice) = error("StaticPrice type has no price vector")

timesteps_per_period(p::PriceType) = p.timesteps_per_period

# need these constructor methods to make kwargs work with the BaseAsset outer constructors
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


abstract type HistoricTrait end
struct IsHistoric <: HistoricTrait end
struct NotHistoric <: HistoricTrait end

checkhistoric(::StaticPrice) = NotHistoric()
checkhistoric(::HistoricPrices) = IsHistoric()

# with these types prices can now be extended. Eventually we can add a TimeArray price vector

function get_volatility(prices, timesteps_per_period)
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
Stock(prices::AbstractArray, timesteps_per_period = size(prices)[1], name = "") = Stock(HistoricPrices(prices, timesteps_per_period), name)

function Stock(;prices, volatility = nothing, timesteps_per_period = nothing, name = "") 
    if isa(prices, PricesType)
        return Stock(prices, name)
    end
    return Stock(PriceType(prices, volatility, timesteps_per_period), name)
end

price_vec(s::Stock) = price_vec(s.prices)
timesteps_per_period(s::Stock) = timesteps_per_period(s.prices)
get_volatility(s::Stock) = get_volatility(s.prices)
checkhistoric(s::Stock) = checkhistoric(s.prices)

function volatility_history(prices::AbstractArray, timesteps_per_period, window_size = 3)
    h_volatil = zeros(eltype(prices), size(prices)[1] - window_size + 1) # TODO change to undef fill
    for i in 1:size(prices)[1] - window_size + 1
        h_volatil[i] = get_volatility(@view(prices[i:i+window_size-1]),timesteps_per_period)
    end
    return h_volatil
end

volatility_history(::StaticPrice, _...) = error("must use HistoricPrices")
volatility_history(p::HistoricPrices, window_size = 3) = volatility_history(p.prices, p.timesteps_per_period, window_size)

volatility_history(s::Stock, window_size) = volatility_history(s.prices, window_size)

# -------- Commodity ------------

struct Commodity <: Asset
    prices::Vector{T}
    name::String
    timesteps_per_period::TI
    volatility::TF

    function Commodity{T,TI,TF}(;
        prices,
        name = "",
        timesteps_per_period = length(prices),
        volatility = get_volatility(prices, timesteps_per_period),
        _...
    ) where {T,TI,TF}
        # allows single price input through kwargs (and ordered arguments)
        if !isa(prices, Vector)
            prices >= 0 ? prices = [prices] :
            error("Single price point must be non-negative")
            volatility == nothing ?
            error("When using single value input for prices must specify volatility") :
            nothing
        end
        size(prices)[1] > 0 ? nothing : error("Prices cannot be an empty vector")
        # catch nothing volatility from get_volatility()
        volatility == nothing ? error("Volatility cannot be nothing") : nothing
        # catch negative volatility
        volatility >= 0 ? nothing : error("volatility must be non negative")
        # catch negative timesteps_per_period
        timesteps_per_period >= 0 ? nothing : 
        error("timesteps_per_period cannot be negative")
	new{T,TI,TF}(prices, name, timesteps_per_period, volatility)
    end

    # constructor for ordered argumentes 
    function Commodity{T,TI,TF}(
        prices,
        name = "",
        timesteps_per_period = length(prices),
        volatility = get_volatility(prices, timesteps_per_period)
    ) where {T,TI,TF}
        if !isa(prices, Vector)
            prices >= 0 ? prices = [prices] :
            error("Single price point must be non-negative")
            volatility == nothing ?
            error("When using single value input for prices must specify volatility") :
            nothing
        end
        size(prices)[1] > 0 ? nothing : error("Prices cannot be an empty vector")
        # catch nothing volatility from get_volatility()
        volatility == nothing ? error("Volatility cannot be nothing") : nothing
        # catch negative volatility
        volatility >= 0 ? nothing : error("volatility must be non negative")
        timesteps_per_period >= 0 ? nothing : 
        # catch negative timesteps_per_period
        error("timesteps_per_period cannot be negative")
	new{T,TI,TF}(prices, name, timesteps_per_period, volatility)
    end
end



function Commodity(price; name = "", volatility)
    prices = [price]
    T = typeof(price)
    TF = typeof(volatility)
    return Commodity{T,Int16,TF}(; prices = prices, name = name, volatility = volatility, timesteps_per_period = 0)
end

# outer constructor to infer the type used in the prices array
function Commodity(
    prices::Vector,
    name = "",
    timesteps_per_period = length(prices),
    volatility = get_volatility(prices, timesteps_per_period)
)
    T = eltype(prices)
    TI = typeof(timesteps_per_period)
    TF = typeof(volatility)
    return Commodity{T,TI,TF}(prices, name, timesteps_per_period, volatility)
end
function Commodity(;
        prices,
        name = "",
        timesteps_per_period = length(prices),
        volatility = get_volatility(prices, timesteps_per_period),
        _...
)
    T = eltype(prices)
    TI = typeof(timesteps_per_period)
    TF = typeof(volatility)
    return Commodity{T,TI,TF}(prices, name, timesteps_per_period, volatility)
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
