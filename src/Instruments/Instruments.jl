module Instruments
using Statistics: var

# export from assets.jl
export Asset, BaseAsset, Stock, Commodity, Bond, PriceType, StaticPrice, HistoricPrices, HistoricTrait, IsHistoric, NotHistoric
export price_vec, underlying, volatility_history, timesteps_per_period, checkhistoric

# exports from financial_instruments
export Option,
    CallOption,
    PutOption,
    EuroCallOption,
    AmericanCallOption,
    EuroPutOption,
    AmericanPutOption,
    Future

export get_volatility, add_price_value, get_prices # exporting this to make tests easier

include("assets.jl")
include("financial_instruments.jl")

# exporting here since still working on it...
export Derivative

end #module
