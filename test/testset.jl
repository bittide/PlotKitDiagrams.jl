
plotpath(x) = joinpath(ENV["HOME"], "plots/", x)


function main()
    @testset "PlotKitGL" begin
        @test main1()
        @test main2()
        @test main3()
        @test main4()
    end
end


function main1()
    println("main1")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = Point[(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
    ad = drawgraph(links, x; graph_nodes = Node(;fillcolor=Color(:red)))
    save(ad, plotpath("test_plotkitdiagrams_1.pdf"))
    return true
end

# directed graph
function main2()
    println("main2")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = Point[(0, -2), (1, 0), (2, -2), (0, 1), (1, 1), (2, 1)]
    arrows=((0.5, TriangularArrow(; size = 0.15)),)
    ad = drawgraph(links, x; graph_paths = Path(; arrows))
    save(ad, plotpath("test_plotkitdiagrams_2.pdf"))
    return true
end


# curved directed graph
function main3()
    println("main3")
    links = [[1, 2], [2,1], [1, 4], [2, 3], [2, 5], [5,2], [3, 2], [4, 5], [5, 6]]
    x = Point[(0, -2), (1, -0.5), (2, -2), (0, 1), (1, 1), (2, 1)]
    arrows=((0.5, TriangularArrow(; size = 0.15)),)
    ad = drawgraph(links, x; lmargin=20,
                  graph_paths = CurvedPath(; arrows))
    save(ad, plotpath("test_plotkitdiagrams_3.pdf"))
    return true
end


# NEEDS to be fixed, slow and bad
# test graph layout
function main4()
    println("main4")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = graphlayout(links, 6)
    ad = drawgraph(links, x)
    save(ad, plotpath("test_plotkitdiagrams_4.pdf"))
    return true
end


# beziers
function main26()
    d = Drawable(800, 600) do ctx
        rect(ctx, Point(0,0), Point(800, 600); fillcolor = Color(:white))
        bps = curve_from_endpoints(Point(100,100), Point(600,200), pi/6, pi/6, 0.3)
        curve(ctx, bps...; linestyle = LineStyle( Color(:black), 2))

        for i=0:0.1:0.5
            p = bezier_point(i, bps...)
            circle(ctx, p, 10;fillcolor = Color(:red))
        end
    end
    qsave(d, "basic26.pdf")
end
