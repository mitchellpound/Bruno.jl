@testset verbose = true "FinancialInstrument tests" begin 

@testset verbose = true "Option Constructor tests" begin
    
    @testset "All kwargs constructor for $fininst" for fininst in [
        EuroCallOption, 
        EuroPutOption, 
        AmericanCallOption, 
        AmericanPutOption
    ]
        kwargs = Dict(
            :underlying => Stock([1, 2, 3, 4, 5]), 
            :strike_price => 6, 
            :maturity => .5, 
            :risk_free_rate => .08,
            :label => "test"
        )

        test_fininst = fininst(;kwargs...)
        @test test_fininst.strike_price == 6
        @test test_fininst.maturity == 0.5
        @test test_fininst.risk_free_rate == 0.08
        @test test_fininst.label == "test"
    end

    @testset "Only widget and strike_price constructor for $fininst" for fininst in [
        EuroCallOption, 
        EuroPutOption, 
        AmericanCallOption, 
        AmericanPutOption
    ]
        widget = Stock([1, 2, 3, 4, 5])
        test_fininst = fininst(widget, 6)
        @test test_fininst.strike_price == 6
        @test test_fininst.maturity == 1.0
        @test test_fininst.risk_free_rate == 0.02
        @test test_fininst.label == ""
    end
    
    @testset "Constructor limits for $fininst" for fininst in [
        EuroCallOption, 
        EuroPutOption, 
        AmericanCallOption, 
        AmericanPutOption
    ]
        widget = Stock([1, 2, 3, 4, 5])
        
        # check for negative strike price
        @test_throws ErrorException fininst(widget, -1)
        # check for negative maturity
        @test_throws ErrorException fininst(;underlying=widget, strike_price=6, maturity=-1)
    end
end

end # fin inst tests 