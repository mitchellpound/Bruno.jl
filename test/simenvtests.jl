@testset verbose=true "SimulationEnvironment tests" begin

@testset verbose=true "Env setup tests" begin
    @testset verbose=true "Constructor test" begin
        m = SimulationEnvironment(10, 252, 5, 100.0)
        @test m.N == 10
        @test m.timesteps_per_period == 252
        @test m.window_size == 5
        @test m["lend_interest"] == zeros(Float64, 15)
        @test m["borrow_interest"] == zeros(Float64, 15)
    end

    @testset verbose=true "Adding variable tests" begin
        m = SimulationEnvironment(10, 252, 5, 100.0)
        m["test_vec"] = fill(1.0, 15)
        m["test_single"] = 2
        add_variable!(x -> x .+ 1, m, "test_single", "function_test")
        @test m["test_vec"][1] == 1.0
        @test m["test_single"] == fill(2, 15)
        @test m["function_test"] == fill(3, 15)
    end

    @testset verbose=true "Adding Asset tests" begin
        @testset verbose=true "BaseAsset tests" begin
            m = SimulationEnvironment(10, 252, 5, 100.0)
            hist_prices = Float64[1:5...]
            future_prices = Float64[6:15...]
            add_asset!(m, Stock, hist_prices, future_prices, "test")
            add_asset!(m, Stock, hist_prices, future_prices, "test_2", 5)
            @test m["test"] == Float64[1:15...]
            @test m["test_2"] == Float64[1:15...]
            @test m.starting_holdings["test"] == 0
            @test m.starting_holdings["test_2"] == 5
            @test get_type(m, "test") == Stock 

            #test that volititly is working...
        end

        @testset verbose=true "Derivitive tests" begin
            m = SimulationEnvironment(10, 252, 5, 100.0)
            sim_to = 15
            strike_price = 10
            hist_prices = Float64[1:5...]
            future_prices = Float64[6:sim_to...]
            add_asset!(m, Stock, hist_prices, future_prices, "test", 5)

            add_asset!(m, EuroCallOption, BlackScholes, "test", strike_price, 1, "der_test", 1)
            
            @test all(y->ismissing(y), m["der_test"][1:4])  # Check if the first 4 values are missing as they cant exist due to math constraints
            @test length(m["der_test"][5]) == 10  # The lag prices should be 10 long as that is the 
            @test isapprox(m["der_test"][end][end], sim_to - strike_price, atol=0.001)

        end
    end

end # Env setup tests

@testset verbose=true "Buy/sell tests" begin
    env = SimulationEnvironment(10, 252, 5, 100.0)
    hist_prices = Float64[1:5...]
    stock = Stock(hist_prices, 252, "stock")
    call = EuroCallOption(;underlying=stock, strike_price=10, label="call")
    future_prices = Float64[6:15...]
    add_asset!(env, call, BlackScholes; future_prices=future_prices)
        
    # setting up ts_holdings outside of a strategy setting 
    ts_holdings = DataFrame()
    ts_holdings[!, "cash"] = [env.starting_holdings["cash"]]

    for asset in get_subtypes(env, Asset)
        build_ts_holdings!(get_type(env, asset), asset,env, ts_holdings)
    end
    push!(ts_holdings, deepcopy(ts_holdings[end, :]))

    # buying 1 call on day 1
    Bruno.BackTest._buy(typeof(call), "call", 1, env, 1, ts_holdings, 0)

    # moving on until day 5
    for _ in 1:4
        push!(ts_holdings, deepcopy(ts_holdings[end, :]))
    end
    
    # buy 2 calls issued 2 days ago on day 5
    Bruno.BackTest._buy(typeof(call), "call", 2, env, 5, ts_holdings, 2)

    # step forward one day
    push!(ts_holdings, deepcopy(ts_holdings[end, :]))
    
    # buy 3 calls on day 6
    Bruno.BackTest._buy(typeof(call), "call", 3, env, 6, ts_holdings, 0)
    
    # step forward one day
    push!(ts_holdings, deepcopy(ts_holdings[end, :]))

    # sell 2 calls issued on day 3 on day 7 - to negate 2nd buy
    Bruno.BackTest._sell(typeof(call), "call", 2, env, 7, ts_holdings, 4)

    # step forward one day
    push!(ts_holdings, deepcopy(ts_holdings[end, :]))

    # complicated sell. Sell 5 on day 8 using FIFO
    Bruno.BackTest._sell(typeof(call), "call", 5, env, 8, ts_holdings)

end

end # SimulationEnvironment tests