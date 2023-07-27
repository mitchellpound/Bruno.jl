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
        @test m.coltypes == fill(SimVariable, 5)
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
            hist_prices = Float64[1:5...]
            future_prices = Float64[6:15...]
            add_asset(m, EuroCallOption, hist_prices, future_prices, "test")
            add_asset(m, Stock, hist_prices, future_prices, "test_2", 5)
            @test m["test"] == Float64[1:15...]
            @test m["test_2"] == Float64[1:15...]
            @test m.starting_holdings["test"] == 0
            @test m.starting_holdings["test_2"] == 5
            @test get_type(m, "test") == Stock 
    
            #test that volititly is working...
            end
    end

end

end # SimulationEnvironment tests