# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


module NodePaths

using LinearAlgebra
using Cairo

using PlotKitCairo: Bezier, Color, Drawable, Point, PointList, LineStyle, PlotKitCairo, colormap, curve, draw,   get_text_info, interp, line, point, point_and_tangent, smallest_box_containing_data

using PlotKitAxes: AxisDrawable, AxisMap,  PlotKitAxes, getscalefactor

export BezierPath, CircularNode, CurvedPath, Node, Path, RectangularNode, ShapedArrow, StraightPath, TriangularArrow, arrow, east, north, south, west


##############################################################################
# paths

abstract type Path end

# straight path through list of points
# TODO: should have "closed" attribute
Base.@kwdef mutable struct StraightPath <: Path
    arrows = ()
    nodes = ()
    linestyle = LineStyle(Color(:black), 1)
    fillcolor = nothing
    closed = false
    points = Point[]
end

# curved path between two points
Base.@kwdef mutable struct CurvedPath <: Path
    points = Point[]
    closed = false
    fillcolor = (0,0,1)
    theta1 = -pi/6
    theta2 = -pi/6
    curveparam = 0.3
    arrows = ()
    nodes = ()
    linestyle = LineStyle(Color(:black),1)
end

# curved path with four bezier points
Base.@kwdef mutable struct BezierPath <: Path
    points = Point[]
    closed = false
    fillcolor = Color(:blue)
    nodes = ()
    arrows = ()
    linestyle = LineStyle(Color(:black),1)
end

Path(args...; kw...) = StraightPath(args...; kw...)

function linelength(p)
    if length(p)<2
        return 0
    end
    d = 0.0
    for i=1:length(p)-1
        d += norm(p[i+1] - p[i])
    end
    return d
end

normalize(x) = x / norm(x)

function findpointonline(p, alpha)
    if alpha <= 0
        return p[1],  normalize(p[2] - p[1])
    end
    if alpha >= 1
        return p[end], normalize(p[end] - p[end-1])
    end
    totallength = linelength(p)
    targetdistance = alpha * totallength
    i = 1
    dist_to_pi = 0
    while targetdistance > dist_to_pi + norm(p[i+1] - p[i])
        dist_to_pi += norm(p[i+1] - p[i])
        i += 1
    end
    x =  interp(p[i], p[i+1], (targetdistance - dist_to_pi)/norm(p[i+1] - p[i]))
    dir = normalize(p[i+1] - p[i])
    return x, dir
end

bounding_box(path::StraightPath) = smallest_box_containing_data(PointList(path.points))


function PlotKitCairo.draw(dw::Drawable, path::StraightPath)
    line(dw, path.points; linestyle = path.linestyle, fillcolor = path.fillcolor, closed = path.closed)
    for (alpha, arrow) in path.arrows
        x, dir  = findpointonline(path.points, alpha)
        draw(dw, x, dir, arrow)
    end
    for (alpha, node) in path.nodes
        x, dir = findpointonline(path.points, alpha)
        # u = normalize(dir)
        # uperp = Point(-u.y, u.x)
        # XXX How should the position/offset be stored
        # maybe alpha should have a type
        # or have an object that stores both alpha and node/arrow
        # Given x, dir. Maybe a function (x,dir) -> point
        # Or maybe let the draw_node do the work, by setting node.dir also.
        # Set node.dir also, and 
        #node.center = x
        draw(dw, node, x, dir)
    end
end

function PlotKitCairo.draw(dw, path::CurvedPath)
    bezier = Bezier(path.points[1], path.points[2], path.theta1, path.theta2, path.curveparam)
    curve(dw, bezier; closed = path.closed, linestyle = path.linestyle, fillcolor = path.fillcolor)
    for (alpha, node) in path.nodes
        #node.center = point(bezier, alpha)
        #draw(dw, node)
        x, dir = point_and_tangent(bezier, alpha)
        draw(dw, node, x, dir)
    end
   for (alpha, arrow) in path.arrows
       x, dir = point_and_tangent(bezier, alpha)
       draw(dw, x, dir, arrow)
    end
end

function PlotKitCairo.draw(dw, path::BezierPath)
    curve(dw, path.points...;
          closed = path.closed, linestyle = path.linestyle,
          fillcolor = path.fillcolor)
    for (alpha, node) in path.nodes
        node.center = bezier_point(alpha, bezier_points...)
        draw(ctx, node)
    end
    for (alpha, arrow) in path.arrows
        x, dir = bezier2(pos, bezier_points...)
        draw(ctx, x, dir, arrow)
    end
end




##############################################################################
# nodes

abstract type Node end

Base.@kwdef mutable struct CircularNode <: Node
    text = ""
    fontsize = nothing    # axis units
    fontname = "Sans"
    textcolor = Color(:white)
    fillcolor = colormap(3)
    linestyle = LineStyle(Color(:black), 1)
    radius = nothing # axis units
    scaletype = :x
    offset = nothing
    #center = nothing
end

Base.@kwdef mutable struct RectangularNode <: Node
    text = ""
    fontsize = nothing   # units are axis units
    fontname = "Sans"
    textcolor = Color(:white)
    fillcolor = colormap(3)  # can be nothing
    linestyle = LineStyle(Color(:black), 1)  # can be nothing
    scaletype = :x
    offset = nothing
    #    center = nothing  
    widthheight = nothing
end


Node(args...; kw...) = CircularNode(args...; kw...)


north(r::RectangularNode) = r.center + Point(0, r.widthheight.y / 2)
south(r::RectangularNode) = r.center - Point(0, r.widthheight.y / 2)
west(r::RectangularNode) = r.center - Point(r.widthheight.x / 2, 0)
east(r::RectangularNode) = r.center + Point(r.widthheight.x / 2, 0)

north(c::CircularNode) = c.center + Point(0, c.radius)
south(c::CircularNode) = c.center - Point(0, c.radius)
west(c::CircularNode) = c.center - Point(c.radius, 0)
east(c::CircularNode) = c.center + Point(c.radius, 0)


##############################################################################

function PlotKitCairo.draw(ad::AxisDrawable, node::CircularNode, x, dir)
    scalefactor = getscalefactor(ad; scaletype = node.scaletype)
    if isnothing(node.radius)
        radius = 9 / scalefactor  # aim for 9 pixel radius
    else
        radius = node.radius
    end
    if isnothing(node.fontsize)
        fontsize = 0.88 * radius
    else
        fontsize = node.fontsize
    end
    if isnothing(node.offset)
        pos = x
    else
        udir = dir/norm(dir)
        uperp = Point(-udir.y, udir.x)
        pos = x + node.offset.x * udir + node.offset.y * uperp
    end
        
    circle(ad, pos, radius; scaletype = node.scaletype, 
           linestyle = node.linestyle, fillcolor = node.fillcolor)

    text(ad, pos, fontsize, node.textcolor, node.text;
         scaletype = node.scaletype,
         fname = node.fontname, horizontal = "center", vertical = "center")
end

function PlotKitCairo.draw(ad::AxisDrawable, node::RectangularNode, x, dir)
    scalefactor = getscalefactor(ad; scaletype = node.scaletype)
    leftpx, toppx, txtwidthpx, txtheightpx = get_text_info(ad.ctx, node.fontsize * scalefactor, node.fontname, node.text)
    if isnothing(node.widthheight)
        Wleft, Wtop, Wtxtwidthpx, Wtxtheightpx = get_text_info(ad.ctx, node.fontsize * scalefactor, node.fontname, "W")
        w = (txtwidthpx + Wtxtwidthpx) / scalefactor
        h = (txtheightpx + Wtxtheightpx / 2) / scalefactor
    else
        w = node.widthheight.x
        h = node.widthheight.y
    end

    if isnothing(node.offset)
        pos = x
    else
        udir = dir/norm(dir)
        uperp = Point(-udir.y, udir.x)
        pos = x + node.offset.x * udir + node.offset.y * uperp
    end
   
    T = [w 0 ; 0 h]
    points = Point[(1,0), (1,1), (0,1), (0,0)]
    points = centerx(points)
    points = [T*a + pos for a in points]

    line(ad, points; closed = true, linestyle = node.linestyle, fillcolor = node.fillcolor)
    text(ad, pos, node.fontsize, node.textcolor, node.text;
         fname = node.fontname, horizontal = "center", vertical = "center")
end



##############################################################################
# arrows

"""
    triangle(t)

Return a triangle with half-angle t at the right-hand vertex.

Returns a list of 3 vertices, (a,0,b). Here a and b are related by reflection about the x-axis.
The angle between a and b is 2t.
"""
triangle(t) = Point[ (-cos(t), sin(t)), (0,0), (-cos(t), -sin(t))]


oblong(w, h) = Point[(0,0), (w,0), (w,h), (0,h)]


"""
    rotate(p, theta)

Rotate a list of points p anticlockwise by theta about the origin, in x-right y-up coords.
"""
function rotate(p::Vector{Point}, theta::Number)
    R = [cos(theta) -sin(theta); sin(theta) cos(theta)]
    q = [R*x for x in p]
    return q
end
translate(p::Vector{Point}, c::Point) = [a + c for a in p]

"""
    centerx(p)

Translate a list of points p so that the mean is zero.
"""
function centerx(p::Vector{Point})
    c = sum(p)/length(p)
    return translate(p, -1 * c)
end

abstract type Arrow end

Base.@kwdef mutable struct TriangularArrow <: Arrow
    size = nothing
    angle = pi/8
    fillcolor = Color(:black)
    linestyle = nothing
    scaletype = :x
    center = false
end

Base.@kwdef mutable struct ShapedArrow <: Arrow
    size = nothing
    points = translate(oblong(1,1), Point(-0.5, -0.5))
    fillcolor = Color(:black)
    linestyle = nothing
    scaletype = :x
end

# arrows are sized in axis units
# x, dir are in axis units too
function PlotKitCairo.draw(ad::AxisDrawable, x, dir, arrow::TriangularArrow)
    # convert to pixels
    x_raw = ad.axis.ax(x)
    dir_raw = ad.axis.ax(dir) - ad.axis.ax(Point(0,0))
    scalefactor = getscalefactor(ad; scaletype = arrow.scaletype)
    arrow2 = TriangularArrow(arrow.size * scalefactor, arrow.angle, arrow.fillcolor, arrow.linestyle, arrow.scaletype, arrow.center)
    drawarrow(Drawable(ad), x_raw, dir_raw, arrow2)
end

function drawarrow(dw, x, dir, arrow)
    theta = atan(dir.y, dir.x)
    points = triangle(arrow.angle)
    if arrow.center
        centroid = (1/3) *sum(points)
        points = [a-centroid for a in points]
    end
    points = translate(arrow.size .* rotate(points, theta), x)
    line(dw, points; closed = true, fillcolor = arrow.fillcolor)
end

# this arrows is sized in pixels
function PlotKitCairo.draw(dw::Drawable, x, dir, arrow::TriangularArrow)
    drawarrow(dw, x, dir, arrow)
end

function PlotKitCairo.draw(dw::Drawable, x, dir, arrow::ShapedArrow)
    theta = atan(dir.y, dir.x)
    points = translate(arrow.size .* rotate(arrow.points, theta), x)
    line(dw, points; closed = true, fillcolor = arrow.fillcolor, linestyle = arrow.linestyle)
end

Arrow(args...; kw...) = TriangularArrow(args...; kw...)

function arrow(points::Array; linestyle = LineStyle(Color(:black), 1),
               fillcolor = Color(:black), size = 8, kw...)
    arrows = ((1, TriangularArrow(; size, fillcolor, allowed_kws(TriangularArrow, kw)...)),)
    p = Path(; arrows, points, linestyle)
    return p
end





##############################################################################

end
