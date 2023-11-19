
module BlockDiagrams

using ..NodePaths: CircularNode, NodePaths, RectangularNode, StraightPath, TriangularArrow
using ..PlotKitAxes: Axis, AxisDrawable, Box, Color, LineStyle, PlotKitAxes, Point, draw, drawbackground

export BlockDiagram

mutable struct BlockDiagram
    fontsize
    linestyle 
    fillcolor 
    arrow 
    xmin
    xmax 
    ymin 
    ymax 
    axis 
end

blockdiagram_axis_defaults(xmin, xmax, ymin, ymax) = Dict(
        :axisstyle_drawaxisbackground => false,
        :axisstyle_drawxlabels => false,
        :axisstyle_drawylabels => false,
        :widthfromdata => 60,
        :heightfromdata => 60,
        :lmargin => 0,
        :rmargin => 0,
        :tmargin => 0,
        :bmargin => 0,
        :axisbox => Box(xmin, xmax, ymin, ymax),
        :xdatamargin => 0.25,
        :ydatamargin => 0.25
    )

function BlockDiagram(;
                      fontsize = 0.1,
                      linestyle = LineStyle(Color(:black), 1),
                      fillcolor = nothing,
                      arrow = TriangularArrow(;size=0.2),
                      xmin = 0,
                      xmax = 1,
                      ymin = 0,
                      ymax = 1,
                      kw...)
    defaults = blockdiagram_axis_defaults(xmin, xmax, ymin, ymax)
    axis = Axis(Box(xmin, xmax, ymin, ymax);  merge(defaults, kw)...)
    bd = BlockDiagram(fontsize, linestyle, fillcolor, arrow, xmin, xmax, ymin, ymax, axis)
    return bd
end

NodePaths.RectangularNode(bd::BlockDiagram, c, wh; kw...) = RectangularNode(; center = c, widthheight = wh,
                                                       linestyle = bd.linestyle,
                                                       fontsize = bd.fontsize,
                                                       fillcolor = bd.fillcolor, kw...)

NodePaths.CircularNode(bd::BlockDiagram, c, r) = CircularNode(; center = c, radius = r,
                                              linestyle = bd.linestyle,
                                              fillcolor = bd.fillcolor)

NodePaths.StraightPath(bd::BlockDiagram, p1, p2) = StraightPath(; arrows = ((1, bd.arrow),),
                                                   linestyle = bd.linestyle,
                                                   points = [p1, p2])

NodePaths.StraightPath(bd::BlockDiagram, points) = StraightPath(; arrows = ((1, bd.arrow),),
                                                   linestyle = bd.linestyle,
                                                   points)


function PlotKitAxes.draw(bd::BlockDiagram, arest...)
    ad = AxisDrawable(bd.axis)
    drawbackground(ad)
    for x in arest
        draw(ad, x)
    end
    return ad
end



end
