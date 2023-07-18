module Instruments
using Statistics: var

# export from widgets
export Widget, Stock, Commodity, Bond
# exports from financial_instruments
export Asset,
    Option,
    CallOption,
    PutOption,
    EuroCallOption,
    AmericanCallOption,
    EuroPutOption,
    AmericanPutOption,
    Future

export get_volatility, add_price_value, get_prices # exporting this to make tests easier

include("widgets.jl")
include("assets.jl")
include("financial_instruments.jl")

# exporting here since still working on it...
export Derivative

end #module
