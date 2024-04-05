
# run using Pkg.test("PlotKitDiagrams")
#
#
# or using
#
#  cd PlotKitDiagrams.jl/test
#  julia
#  include("runtests.jl")
#
module TestSet

using PlotKitCairo
using PlotKitAxes
using PlotKitDiagrams

using Test
include("testset.jl")
end

using .TestSet
TestSet.main()



