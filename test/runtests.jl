
module TestSet

using PlotKitAxes
using PlotKitDiagrams

using Test
include("testset.jl")
end

using .TestSet
TestSet.main()



