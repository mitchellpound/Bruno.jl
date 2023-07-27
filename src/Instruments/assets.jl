using Statistics
using ..Bruno
# TODO: Add docs
"""

"""
abstract type Asset end
abstract type BaseAsset <: Asset end

# ------- PriceTypes ---------
"""
    PriceType
    PriceType(price, volatility, _...)
    PriceType(prices, volatility, timesteps_per_period)

Prices for BaseAssets. They can be tuples (price, volatility) or vectors of historical prices. Can be 
used as a method to create the correct PriceType subtype given data. 
```julia
PriceType(100, .07)
PriceType([1, 2, 3, 4, 5], nothing, 252)
```
"""
abstract type PriceType end

# traits for PriceType subtypes
abstract type HistoricTrait end
struct IsHistoric <: HistoricTrait end
struct NotHistoric <: HistoricTrait end

struct StaticPrice{U,V} <: PriceType
    price::U
    volatility::V

    function StaticPrice(price, volatility) 
        volatility < 0 ? error("volatility must be non-negative") : nothing
        price <= 0 ? error("price must be non-negative") : nothing
        new{typeof(price), typeof(volatility)}(price, volatility)
    end
end

struct HistoricPrices{T, TI} <: PriceType
    prices::Vector{T}
    timesteps_per_period::TI

    function HistoricPrices(prices, timesteps_per_period) 
        timesteps_per_period < 0 ? error("timesteps_per_period must be non-negative") : nothing
        length(prices) < 1 ? error("must give at least 2 prices") : 
        new{eltype(prices), typeof(timesteps_per_period)}(prices, timesteps_per_period)
    end
end

HistoricPrices(prices) = HistoricPrices(prices, size(prices)[1])

# constructors to make the correct concrete subtpyes of PriceType
PriceType(price, volatility) = StaticPrice(price, volatility)
PriceType(prices::AbstractArray, timesteps_per_period) = HistoricPrices(prices, timesteps_per_period)
PriceType(prices::AbstractArray) = HistoricPrices(prices)


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

# returns price vec or error depending on PriceType subtype
price_vec(p::HistoricPrices) = p.prices
price_vec(::StaticPrice) = error("StaticPrice type has no price vector")

volatility_history(::StaticPrice, _...) = error("must use HistoricPrices")
volatility_history(p::HistoricPrices, window_size=3) = volatility_history(p.prices, p.timesteps_per_period, window_size)

timesteps_per_period(p::PriceType) = p.timesteps_per_period

checkhistoric(::StaticPrice) = NotHistoric()
checkhistoric(::HistoricPrices) = IsHistoric()

checkhistoric(input::IsHistoric, needs::IsHistoric) = IsHistoric()
checkhistoric(input::NotHistoric, needs::NotHistoric) = NotHistoric()
checkhistoric(input::IsHistoric, needs::NotHistoric) = NotHistoric()
checkhistoric(_::Any, _::Any) = error("not compatible")
# TODO: make a better error name

get_volatility(p::HistoricPrices) = get_volatility(p.prices, p.timesteps_per_period)
get_volatility(p::StaticPrice) = p.volatility


# ------ Stocks ------
# TODO: Change docs
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
    Stock <: BaseAsset

BaseAsset subtype. Used as a base or root asset for financial instrument.
"""
struct Stock <: BaseAsset
    prices::PriceType
    name::String

    Stock(prices::PriceType, name = "") = new(prices, name)
end

# outer constructors
Stock(price, volatility, name = "") = Stock(StaticPrice(price, volatility), name)
Stock(prices::AbstractArray, timesteps_per_period = size(prices)[1], name = "") = Stock(HistoricPrices(prices, timesteps_per_period), name)

function Stock(;prices, volatility = nothing, timesteps_per_period = nothing, name = "") 
    if isa(prices, PriceType)
        return Stock(prices, name)
    end
    if isa(prices, AbstractArray)
        if volatility !== nothing
            @warn "If a vector of prices is give, HistoricPrices takes priority and volatility will be ignored"
        end
    end
    return Stock(PriceType(prices, volatility, timesteps_per_period), name)
end

# getter functions
price_vec(s::Stock) = price_vec(s.prices)
get_volatility(s::Stock) = get_volatility(s.prices)
get_name(s::Stock) = s.name
timesteps_per_period(s::Stock) = timesteps_per_period(s.prices)

checkhistoric(s::Stock) = checkhistoric(s.prices)
volatility_history(s::Stock, window_size) = volatility_history(s.prices, window_size)

# -------- Commodity ------------

struct Commodity <: Asset
    prices::PriceType
    name::String

    Commodity(prices::PriceType, name = "") = new(prices, name)
end

Commodity(price, volatility, name = "") = Commodity(StaticPrice(price, volatility), name)
Commodity(prices::AbstractArray, timesteps_per_period = size(prices)[1], name = "") = Commodity(HistoricPrices(prices, timesteps_per_period), name)

function Commodity(;prices, volatility = nothing, timesteps_per_period = nothing, name = "") 
    if isa(prices, PriceType)
        return Stock(prices, name)
    end
    if isa(prices, AbstractArray)
        if volatility !== nothing
            @warn "If a vector of prices is give, HistoricPrices takes priority and volatility will be ignored"
        end
    end
    return Commodity(PriceType(prices, volatility, timesteps_per_period), name)
end

# helper functions
function get_volatility(prices, timesteps_per_period)
    length(prices) > 2 ? nothing :
    # need at least three values so std can work
    return error("Must have at least three values to calculate the volatility")  
    returns = [((prices[i+1] - prices[i]) / prices[i]) + 1 for i = 1:(length(prices)-1)]
    cont_return = log.(returns)
    std(cont_return, corrected = false) * sqrt(timesteps_per_period)
end

function volatility_history(prices::AbstractArray, timesteps_per_period, window_size = 3)
    h_volatil = zeros(eltype(prices), size(prices)[1] - window_size + 1) # TODO change to undef fill
    for i in 1:size(prices)[1] - window_size + 1
        h_volatil[i] = get_volatility(@view(prices[i:i+window_size-1]),timesteps_per_period)
    end
    return h_volatil
end

# getter functions
price_vec(s::Commodity) = price_vec(s.prices)
get_volatility(s::Commodity) = get_volatility(s.prices)
get_name(s::Commodity) = s.name
timesteps_per_period(s::Commodity) = timesteps_per_period(s.prices)

checkhistoric(s::Commodity) = checkhistoric(s.prices)
volatility_history(s::Commodity, window_size) = volatility_history(s.prices, window_size)

# TODO: Figure out Bond logic/ clean up constructors
# ---------- Bonds -----------------
""" 
    Bond <: Asset

Asset subtype. Used as a base or root asset for FinancialInstrument.
"""
struct Bond{T,TF} <: Asset
    prices::Array{T}
    name::String
    time_mat::TF
    coupon_rate::TF

    # constructor for kwargs
    function Bond{T,TF}(; prices, name = "", time_mat = 1, coupon_rate = 0.03, _...) where {T,TF}
        size(prices)[1] > 0 ? nothing : error("Prices cannot be an empty vector")
        time_mat > 0 ? nothing : error("time_mat must be positive")
	new{T,TF}(prices, name, time_mat, coupon_rate)
    end

    # constructor for ordered argumentes 
    function Bond{T,TF}(prices, name = "", time_mat = 1, coupon_rate = 0.03) where {T,TF}
        size(prices)[1] > 0 ? nothing : error("Prices cannot be an empty vector")
        time_mat > 0 ? nothing : error("time_mat must be positive")
	new{T,TF}(prices, name, time_mat, coupon_rate)
    end
end

# outer constructor to make a Bond with a (static) single price
"""
    Bond(prices, name, time_mat, coupon_rate)
    Bond(price; kwargs...)
    Bond(;kwargs)

Construct a Bond type to use as a base asset for FinancialInstrument.

## Arguments
- `prices`:Historical prices (input as a 1-D array) or the current price input as a number `<: Real`
- `name`: String name of the Bond or issuing company. Default "".
- `time_mat`: Time until the bond expires (matures) in years. Default 1.
- `coupon_rate`: The coupon rate for the bond. Default .03.

## Examples
```julia
Bond([1,2,3,4,5], "Example", .5, .05)

kwargs = Dict(:prices => [1, 2, 3, 4, 5], :name => "Example", :time_mat => .5, :coupon_rate => .05);
Bond(;kwargs...)

Bond(2; coupon_rate=.05)
```
"""
function Bond(price; name = "", time_mat = 1, coupon_rate = 0.03)
    prices = [price]
    T = typeof(price)
    time_mat, coupon_rate = promote(time_mat, coupon_rate)
    TF = typeof(coupon_rate)
    return Bond{T,TF}(; prices = prices, name = name, time_mat = time_mat, coupon_rate = coupon_rate)
end

# outer constructor with implied type of prices vector 
function Bond(; prices, name = "", time_mat = 1, coupon_rate = 0.03, _...)
    T = eltype(prices)
    time_mat, coupon_rate = promote(time_mat, coupon_rate)
    TF = typeof(coupon_rate)
    return Bond{T,TF}(prices, name, time_mat, coupon_rate)
end
function Bond(prices::Vector, name = "", time_mat = 1, coupon_rate = 0.03)
    T = eltype(prices)
    time_mat, coupon_rate = promote(time_mat, coupon_rate)
    TF = typeof(coupon_rate)
    return Bond{T,TF}(prices, name, time_mat, coupon_rate)
end