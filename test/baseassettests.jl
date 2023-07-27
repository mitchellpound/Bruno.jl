import InteractiveUtils
using Logging

@testset verbose = true "Widget constructor tests" begin

    @testset verbose = true "ordered argumentes creation tests" begin
        @testset "Stock Creation" begin
            # Test the stock creation with HistoricPrices
            # Test ordered argumentes when only price vector given
            a_stock = Stock(Float64[1, 2, 3, 4, 5, 4, 3, 2, 1])
            @test isapprox(get_volatility(a_stock), 1.322, atol = 0.001)
            @test get_name(a_stock) == ""
            @test price_vec(a_stock) == [1, 2, 3, 4, 5, 4, 3, 2, 1]
            @test timesteps_per_period(a_stock) == 9 # tests defualt value

            # Test ordered argumentes when all given.. will ignore volatility since preference
            # is given to HistoricPrices type
            with_logger(NullLogger()) do
            a_stock = Stock(
                prices = Float64[1, 2, 3, 4, 5, 4, 3, 2, 1],
                volatility = 0.05,
                name = "Example",
                timesteps_per_period = 9
            )
            end

            @test isapprox(get_volatility(a_stock), 1.322, atol = 0.001)
            @test get_name(a_stock) == "Example"
            @test price_vec(a_stock) == [1, 2, 3, 4, 5, 4, 3, 2, 1]
            @test timesteps_per_period(a_stock) == 9 # tests defualt value

            # Test keyword arguments
            a_stock = Stock(;
                prices=Float64[1, 2, 3, 4, 5, 4, 3, 2, 1], 
                timesteps_per_period=9, 
                name="Example"
            )

            @test isapprox(get_volatility(a_stock), 1.322, atol = 0.001)
            @test get_name(a_stock) == "Example"
            @test price_vec(a_stock) == [1, 2, 3, 4, 5, 4, 3, 2, 1]
            @test timesteps_per_period(a_stock) == 9

            # Test stock creation with StaticPrices
            # Creation with price and volatility given
            a_stock = Stock(100, .05)
            @test get_volatility(a_stock) == .05
            @test get_name(a_stock) == ""
            @test price(a_stock) == 100

            # Test stock creation with keyword arguments
            a_stock = Stock(;prices=100, volatility=.05)
            @test get_volatility(a_stock) == .05
            @test get_name(a_stock) == ""
            @test price(a_stock) == 100

        end

        @testset "Commodities Creation" begin
            # Test the Commodity widget creation

            # Test ordered argumentes when only price given
            a_com = Commodity([1, 2, 3, 4, 5, 4, 3, 2, 1])
            @test isapprox(get_volatility(a_com), 1.322, atol = 0.001)
            @test get_name(a_com) == ""
            @test price_vec(a_com) == [1, 2, 3, 4, 5, 4, 3, 2, 1]
            @test timesteps_per_period(a_com) == 9

            # Test ordered argumentes when all given.. will ignore volatility since preference
            # is given to HistoricPrices type

            with_logger(NullLogger()) do
            a_com = Commodity(
                prices = Float64[1, 2, 3, 4, 5, 4, 3, 2, 1],
                volatility = 0.05,
                name = "Example",
                timesteps_per_period = 9
            )

            @test isapprox(get_volatility(a_com), 1.322, atol = 0.001)
            @test get_name(a_com) == "Example"
            @test price_vec(a_com) == [1, 2, 3, 4, 5, 4, 3, 2, 1]
            @test timesteps_per_period(a_com) == 9 # tests defualt value

            # Test keyword arguments
            a_com = Commodity(;
                prices = [1, 2, 3, 4, 5, 4, 3, 2, 1],
                volatility = 0.05,
                name = "Example",
                timesteps_per_period = 9
            )
            @test isapprox(get_volatility(a_com), 1.322, atol = 0.001)
            @test get_name(a_com) == "Example"
            @test price_vec(a_com) == [1, 2, 3, 4, 5, 4, 3, 2, 1]
            @test timesteps_per_period(a_com) == 9
            end

        end

        # @testset "Bonds Creation" begin
        #     # Test the Bond widget creation

        #     # Test ordered argumentes when only price given
        #     a_widget = Bond([1, 2, 3, 4, 5, 4, 3, 2, 1])
        #     @test a_widget.prices == [1, 2, 3, 4, 5, 4, 3, 2, 1]
        #     @test a_widget.name == ""
        #     @test a_widget.time_mat == 1
        #     @test a_widget.coupon_rate == 0.03
        #     # Test ordered argumentes when name not given
        #     a_widget = Bond(prices = [1, 2, 3, 4, 5, 4, 3, 2, 1], time_mat = 2)
        #     @test a_widget.prices == [1, 2, 3, 4, 5, 4, 3, 2, 1]
        #     @test a_widget.name == ""
        #     @test a_widget.time_mat == 2
        #     @test a_widget.coupon_rate == 0.03

        #     # Test ordered argumentes when all given
        #     a_widget = Bond(
        #         prices = [1, 2, 3, 4, 5, 4, 3, 2, 1],
        #         time_mat = 2,
        #         name = "Example",
        #         coupon_rate = 0.5,
        #     )
        #     @test a_widget.prices == [1, 2, 3, 4, 5, 4, 3, 2, 1]
        #     @test a_widget.name == "Example"
        #     @test a_widget.time_mat == 2
        #     @test a_widget.coupon_rate == 0.5

        # end

    end

    @testset "Single price creation $asset" for asset in [Stock, Commodity]

        temp = asset(10.0, 0.3)
        @test price(temp) == 10.0
        @test get_volatility(temp) == 0.3
        @test get_name(temp) == "" 
    end

    @testset "Constructor limits" begin
        widget_subs = InteractiveUtils.subtypes(BaseAsset)
        @testset "Price size for $widget" for widget in widget_subs
            @test_throws ErrorException widget(; prices = Float64[])
        end

        @testset "Single price errors for $widget" for widget in [Stock, Commodity]
            # using kwargs price > 0
            @test_throws ErrorException widget(; prices = -1)
            # using kwargs must give volatility
            @test_throws ErrorException widget(; prices = 1)
            # using position args price < 0
            @test_throws ErrorException widget(-1, 0.03)
        end

        @testset "volatility errors for $widget" for widget in [Stock, Commodity]
            @test_logs (:warn,"If a vector of prices is give, HistoricPrices takes priority and volatility will be ignored") widget(; prices = Float64[1, 2, 3], volatility = -1)
        end

        with_logger(NullLogger()) do
        @testset "timesteps_per_period error for $widget" for widget in [Stock, Commodity]
            @test_throws ErrorException widget(; 
            prices = [1, 2, 3, 4], 
            timesteps_per_period = -1, 
            volatility = .1
        )
        end
        end # NullLogger

        @testset "time_mat error for Bond" begin
            @test_throws ErrorException Bond(; prices = [1, 2, 3], time_mat = 0)
        end

    end
end # master testset for Widget constructors
