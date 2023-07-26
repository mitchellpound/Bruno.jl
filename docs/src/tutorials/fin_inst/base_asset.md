# Base Assets (Widgets)

## Overview 
[Widgets](@ref Type_system) are base (or underlying) assets for a Financial Instrument, they can also be used by themselves. Examples include the stock, bond, and commodity structs. 

## [Creating a Widget](@id asset_tutorial)
The following example is how to create a random dataset representing historical prices and create a Stock asset using those prices. 
```@meta
DocTestSetup = quote
    using Bruno
    using Random
    Random.seed!(7)
end
```

```jldoctest; output = false
# creating a random 'dataset' of 15 simulated prices
historical_prices = rand(50:70, 15)

# creates a Stock asset assuming historical prices are daily prices
a_asset = Stock(;prices=historical_prices, name="my_asset", timesteps_per_period=252)

# output

Stock{Int64, Int64, Float64}([55, 65, 67, 59, 69, 51, 68, 67, 57, 54, 67, 64, 68, 63, 65], "my_asset", 252, 2.437334881898636)

```

```@meta
DocTestSetup = nothing
```

## Interacting With a Widget
```jldoctest; output = false, setup = :(using Bruno)
historical_prices = [1, 2, 3, 4, 5]

# creates a Stock asset
a_asset = Stock(;prices=historical_prices, name="my_asset", timesteps_per_period=252)

# price the Stock asset
stock_price = price!(a_asset, StockPrice)

# output

5
```
