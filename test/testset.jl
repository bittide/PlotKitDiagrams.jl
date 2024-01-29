
plotpath(x) = joinpath(ENV["HOME"], "plots/", x)


function main()
    @testset "PlotKitDiagrams" begin
        @test main1()
        @test main2()
        @test main3()
        @test main4()
        @test main5()
        @test main6()
        @test main7()
    end
end


function main1()
    println("main1")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = Point[(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)]
    ad = draw(Graph(links, x; graph_nodes = Node(;fillcolor=Color(:red))))
    save(ad, plotpath("test_plotkitdiagrams_1.pdf"))
    return true
end

# directed graph
function main2()
    println("main2")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = Point[(0, -2), (1, 0), (2, -2), (0, 1), (1, 1), (2, 1)]
    arrows=((0.5, TriangularArrow(; size = 0.15)),)
    ad = draw(Graph(links, x; graph_paths = Path(; arrows)))
    save(ad, plotpath("test_plotkitdiagrams_2.pdf"))
    return true
end


# curved directed graph
function main3()
    println("main3")
    links = [[1, 2], [2,1], [1, 4], [2, 3], [2, 5], [5,2], [3, 2], [4, 5], [5, 6]]
    x = Point[(0, -2), (1, -0.5), (2, -2), (0, 1), (1, 1), (2, 1)]
    arrows=((0.5, TriangularArrow(; size = 0.15)),)
    ad = draw(Graph(links, x; lmargin=20,
                  graph_paths = CurvedPath(; arrows)))
    save(ad, plotpath("test_plotkitdiagrams_3.pdf"))
    return true
end


# NEEDS to be fixed, slow and bad
# test graph layout
function main4()
    println("main4")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = graphlayout(links, 6)
    ad = draw(Graph(links, x))
    save(ad, plotpath("test_plotkitdiagrams_4.pdf"))
    return true
end



# directed graph with labels
function main5()
    println("main5")
    links = [[1, 2], [1, 4], [2, 3], [2, 5], [3, 6], [4, 5], [5, 6]]
    x = Point[(0, -2), (1, 0), (2, -2), (0, 1), (1, 1), (2, 1)]
    n = length(x)
    m = length(links)
  
    graph_nodes = [Node(; text=string(i), fillcolor = Color(0,0,0.6)) for i=1:n]

    arrows = ((0.8, TriangularArrow(; size = 0.15)),)
    node(i) = (0.5, Node(; fillcolor = Color(:white),
                         textcolor = Color(:black),
                         linestyle = nothing,
                         text=string(i)))
    
    graph_paths = [Path(; arrows, nodes = (node(i),)) for i=1:m]

    ad = draw(Graph(links, x; graph_nodes, graph_paths))
    save(ad, plotpath("test_plotkitdiagrams_5.pdf"))
    return true
end   

# arrows on non-equal axes
function main6()
    println("main6")
    ad = AxisDrawable(Box(0,20,0,3))
    drawaxis(ad)
    setclipbox(ad)
    line(ad, Point(0,0), Point(10,2); linestyle = LineStyle(Color(:red), 1))
    p = Path(;points=[Point(4,1), Point(16,2)], arrows = ((0.5, TriangularArrow(;size = 0.4)),))
    draw(ad, p)
    save(ad, plotpath("test_plotkitdiagrams_6.pdf"))
    return true
end
    

# arrows on non-equal axes
function main7()
    println("main7")
    ad = AxisDrawable(Box(0,20,0,3);
                      axisoptions_yoriginatbottom = false)
    drawaxis(ad)
    setclipbox(ad)
    line(ad, Point(0,0), Point(10,2); linestyle = LineStyle(Color(:red), 1))
    p = Path(;points=[Point(4,1), Point(16,2)], arrows = ((0.5, TriangularArrow(;size = 0.4)),))
    draw(ad, p)
    save(ad, plotpath("test_plotkitdiagrams_7.pdf"))
    return true
end
    
