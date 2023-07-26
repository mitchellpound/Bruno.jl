using Pkg
Pkg.activate()
using Bruno 

prices = convert(Vector{Float64}, collect(1:10))
widget = Stock(prices)

list_of_widgets = factory(widget, Stationary, 2)
println("done!")