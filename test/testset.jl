
plotpath(x) = joinpath(ENV["HOME"], "plots/", x)


function main()
    @testset "PlotKitGL" begin
        @test main1()
    end
end


function main1()
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = Point[(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
    ad = drawgraph(links, x; graph_nodes = Node(;fillcolor=Color(:red)))
    save(ad, plotpath("test_plotkitdiagrams_1.pdf"))
    return true
end

