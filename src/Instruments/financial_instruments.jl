# financial instruments that can be passed to simulate. They house underlying widgets as part
# of the instrument. Ex: Stock call options house an underlying stock
"""FinancialInstrument is the supertype for any instrument that uses a base asset
(widget) in its definition (like a financial derivative)."""
abstract type Derivative <: Asset end

underlying(d::Derivative) = d.underlying
checkhistoric(d::Derivative) = checkhistoric(d.underlying)
timesteps_per_period(d::Derivative) = timesteps_per_period(d.underlying)

# ----- Type system for options: subtype of FinancialInstrument ------
"""
    Option <: Derivative

Abstract FinancialInstrument subtype. Supertype of all options contract types.
"""
abstract type Option <: Derivative end

# ----- Abstract type for all call and put options -----
"""
    CallOption{T <: Widget} <: Option

Abstract option subtype. Super type for all call options types.
"""
abstract type CallOption{T<:Asset} <: Option end
"""
    PutOption{T <: Widget} <: Option

Abstract option subtype. Super type for all put options types.
"""
abstract type PutOption{T<:Asset} <: Option end

# ----- Concrete types for Euro and American call options
# TODO: Change docs 
"""
    eurocalloption(;kwargs...)
    eurocalloption(widget, strike_price, maturity, risk_free_rate, values_library)

construct a eurocalloption with underlying asset of type `widget`

## arguments
- `widget`: underlying asset
- `strike_price`: contracted price to buy underlying asset at maturity
- `maturity`: time to maturity of the option with respect to implicit time period. default 1.
- `risk_free_rate`: market risk free interest rate. default is .02.
- `values_library`: a dictionary of values returned from pricing functions. default initializes
to an empty dictionary. use `price!()` function to load theoretical option prices.

## examples
```julia
stock = stock([1,2,4,3,5,3]);

eurocalloption(stock, 10)

kwargs = dict(:widget=>stock, :strike_price=>10, :maturity=>1, :risk_free_rate=>.02);
eurocalloption(;kwargs...)
```
"""
Base.@kwdef struct EuroCallOption{T<:Asset,S} <: CallOption{T}
    underlying::T
    strike_price::S = price(underlying)
    maturity::S = 1
    risk_free_rate::S = .02
    label::String = ""

    # ordered arguments constructor
    function EuroCallOption{T,S}(
        underlying,
        strike_price,
        maturity,
        risk_free_rate,
        label
    ) where {T<:Asset,S}
        strike_price >= 0 ? nothing : error("strike_price must be non-negative")
        maturity >= 0 ? nothing : error("maturity must be positive")
        new{T,S}(underlying, strike_price, maturity, risk_free_rate, label)
    end
end

"""
    AmericanCallOption(widget, strike_price; kwargs...)
    AmericanCallOption(;kwargs...)

Construct a AmericanCallOption with underlying asset of type `Widget`

## Arguments
- `widget`: The underlying asset
- `strike_price`: Contracted price to buy underlying asset at maturity.
- `maturity`: time to maturity of the option with respect to implicit time period. Default 1.
- `risk_free_rate`: market risk free interest rate. Default is .02.
- `values_library`: The values returned from pricing models. Default initializes
to an empty dictionary. use `price!()` function to load theoretical option prices.

## Examples
```julia
stock = Stock([1,2,4,3,5,3]);

AmericanCallOption(stock, 10)

kwargs= Dict(:widget=>stock, :strike_price=>10, :maturity=>1, :risk_free_rate=>.02);
AmericanCallOption(;kwargs...)
```
"""
Base.@kwdef struct AmericanCallOption{T<:Asset,S} <: CallOption{T}
    underlying::T
    strike_price::S = price(underlying)
    maturity::S = 1
    risk_free_rate::S = .02
    label::String = ""

    # ordered arguments constructor
    function AmericanCallOption{T,S}(
        underlying,
        strike_price,
        maturity,
        risk_free_rate,
        label
    ) where {T<:Asset,S}
        strike_price >= 0 ? nothing : error("strike_price must be non-negative")
        maturity >= 0 ? nothing : error("maturity must be positive")
        new{T,S}(underlying, strike_price, maturity, risk_free_rate, label)
    end
end

"""
    EuroPutOption(widget, strike_price; kwargs...)
    EuroPutOption(;kwargs...)

Construct a EuroPutOption with underlying asset of type `Widget`

## Arguments
- `widget`: The underlying asset.
- `strike_price`: Contracted price to buy underlying asset at maturity.
- `maturity`: time to maturity of the option with respect to implicit time period. Default 1.
- `risk_free_rate`: market risk free interest rate. Default is .02.
- `values_library`: The values returned from pricing models. Default initializes
to an empty dictionary. use `price!()` function to load theoretical option prices.

## Examples
```julia
stock = Stock([1,2,4,3,5,3]);

EuroPutOption(stock, 10)

kwargs= Dict(:widget=>stock, :strike_price=>10, :maturity=>1, :risk_free_rate=>.02);
EuroPutOption(;kwargs...)
```
"""
Base.@kwdef struct EuroPutOption{T<:Asset,S} <: CallOption{T}
    underlying::T
    strike_price::S = price(underlying)
    maturity::S = 1
    risk_free_rate::S = .02
    label::String = ""

    # ordered arguments constructor
    function EuroPutOption{T,S}(
        underlying,
        strike_price,
        maturity,
        risk_free_rate,
        label
    ) where {T<:Asset,S}
        strike_price >= 0 ? nothing : error("strike_price must be non-negative")
        maturity >= 0 ? nothing : error("maturity must be positive")
        new{T,S}(underlying, strike_price, maturity, risk_free_rate, label)
    end
end


#TODO: add docs (copy from one of the above)
Base.@kwdef struct AmericanPutOption{T<:Asset,S} <: CallOption{T}
    underlying::T
    strike_price::S = price(underlying)
    maturity::S = 1
    risk_free_rate::S = .02
    label::String = ""

    # ordered arguments constructor
    function AmericanPutOption{T,S}(
        underlying,
        strike_price,
        maturity,
        risk_free_rate,
        label
    ) where {T<:Asset,S}
        strike_price >= 0 ? nothing : error("strike_price must be non-negative")
        maturity >= 0 ? nothing : error("maturity must be positive")
        new{T,S}(underlying, strike_price, maturity, risk_free_rate, label)
    end
end

# outer constructor for just the positional arguments
for st = (:EuroCallOption, :AmericanCallOption, :EuroPutOption, :AmericanPutOption)
    eval(quote
        function $st(underlying, strike_price = price(underlying), maturity = 1, risk_free_rate = .02, label = "")
            strike_price, maturity, risk_free_rate = promote(strike_price, maturity, risk_free_rate)
            $st{typeof(underlying),typeof(strike_price)}(underlying, strike_price, maturity, risk_free_rate, label)
        end
    end)
end

# TODO: Fix/ implement these more
# ------ Type system for futures: subtype of FinancialInstrument ------
"""
    Future{T <: Widget} <: FinancialInstrument

Future contract with underlying asset 'T'.
"""
struct Future{T<:Widget,S,D} <: Derivative
    widget::T
    strike_price::S
    risk_free_rate::S
    maturity::S
    label::String
    values_library::Dict{String,Dict{String,D}}
end

# ------ Type system for stuff we haven't figured out yet ------ 
"""Still under development"""
struct ETF <: Asset end
"""Still under development"""
struct InterestRateSwap <: Asset end

#------- Helpers
function add_price_value(a_fin_inst::Asset , a_new_price)
    a_new_price >= 0 ? nothing :
    @warn("You are trying to add a negative number to a prices list")
    push!(a_fin_inst.widget.prices, a_new_price)
end

function get_prices(a_fin_inst::Asset )
    a_fin_inst.widget.prices
end
