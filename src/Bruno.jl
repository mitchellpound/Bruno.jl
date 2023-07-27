module Bruno
# exports from Instruments 
"""
Instruments.jl contains the exports for the different Bruno Structs.
At the core of the struct hierarchy lives the "Widget" abstract type.
From there concrete structs are made like Stocks or Commodities. These
assets are then put into a Financial Instrument. These Financial 
Instruments are then used in various Bruno functions.
"""

include("Instruments/Instruments.jl")

using .Instruments
export Asset, Widget
export Bond, Commodity, Stock
export AmericanCallOption,
    AmericanPutOption, CallOption, EuroCallOption, EuroPutOption, Future, Option, PutOption

export get_volatility, add_price_value, get_name

# DataGeneration submodule
"""
DataGeneration.jl is where the data generation functions live. Examples
include the bootstrap and factory functions. DataGeneration uses either
a asset or Financial Instrument to generate new prices.
"""

include("DataGeneration/DataGeneration.jl")
using .DataGeneration

export BootstrapInput, DataGenInput, data_gen_input, LogDiffInput, TSBootMethod
export Stationary, MovingBlock, CircularBlock
export factory, makedata, opt_block_length

# Models submodule
"""
Models.jl is where Financial Instruments go to be priced. In
the future other pricing methods can live here. As a note
"price!" returns what a given model believes a FinancialInstrument
should be worth and adds the function call parameters / result to the
FinancialInstrument.
"""

include("Models/Models.jl")
using .Models

export Model
export BinomialTree, BlackScholes, StockPrice
export MonteCarlo, MonteCarloModel, LogDiffusion, MCBootstrap
export price!, price

# BackTest Module
"""
BackTest.jl contains the logic for the hedging strategy framework
and other simulators. This is where we put code for finding dollar
returns.
"""

include("BackTest/BackTest.jl")
using .BackTest
export Hedging, Naked, RebalanceDeltaHedge, StaticDeltaHedge
export find_correlation_coeff, strategy_returns, strategy

# new ones... just for now...
export PriceType, StaticPrice, HistoricPrices, HistoricTrait, IsHistoric, NotHistoric, checkhistoric
export price_vec, underlying, price_history, volatility_history, timesteps_per_period, BaseAsset, Derivative
export SimulationEnvironment, add_asset, add_variable, add_interest_rate
export SimVariable, get_type

export time_lag_price
end # end Bruno module 
