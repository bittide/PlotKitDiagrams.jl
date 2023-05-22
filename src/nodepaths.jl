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
using ..PlotKitAxes: AxisDrawable, AxisMap, Color, Drawable, LineStyle, PlotKitAxes, Point, colormap, curve, draw, get_text_info, getscalefactor, interp, line

export BezierPath, CircularNode, CurvedPath, Node, Path, RectangularNode, StraightPath, TriangularArrow

##############################################################################
# local utils

polar(r, theta) = Point(r*cos(theta), r*sin(theta))


##############################################################################
# paths

abstract type Path end

# straight path through list of points
# TODO: should have "closed" attribute
Base.@kwdef mutable struct StraightPath <: Path
    arrows = ()
    nodes = ()
    linestyle = LineStyle(Color(:black), 1)
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

function PlotKitAxes.draw(dw::Drawable, path::StraightPath)
    line(dw, path.points; linestyle = path.linestyle)
    for (alpha, node) in path.nodes
        x, dir = findpointonline(path.points, alpha)
        node.center = x
        draw(dw, node)
    end
    for (alpha, arrow) in path.arrows
        x, dir  = findpointonline(path.points, alpha)
        draw(dw, x, dir, arrow)
    end
end

function PlotKitAxes.draw(dw, path::CurvedPath)
    bezier_points = curve_from_endpoints(path.points[1], path.points[2],
                                         path.theta1, path.theta2, path.curveparam)
    curve(dw, bezier_points...;
          closed = path.closed, linestyle = path.linestyle,
          fillcolor = path.fillcolor)
    for (alpha, node) in path.nodes
        node.center = bezier_point(alpha, bezier_points...)
        draw(dw, node)
    end
   for (alpha, arrow) in path.arrows
       x, dir = bezier2(alpha, bezier_points...)
       draw(dw, x, dir, arrow)
    end
end

function PlotKitAxes.draw(dw, path::BezierPath)
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
    textcolor = Color(:white)
    fillcolor = colormap(3)
    linestyle = LineStyle(Color(:black), 1)
    radius = nothing # axis units
    scaletype = :x
    center = nothing
end

Base.@kwdef mutable struct RectangularNode <: Node
    text = ""
    fontsize = nothing   # units are axis units
    textcolor = Color(:white)
    fillcolor = colormap(3)  # can be nothing
    linestyle = LineStyle(Color(:black), 1)  # can be nothing
    scaletype = :x
    center = nothing  
    widthheight = nothing
end


Node(args...; kw...) = CircularNode(args...; kw...)


##############################################################################

function PlotKitAxes.draw(ad::AxisDrawable, node::CircularNode)
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
    circle(ad, node.center, radius; scaletype = node.scaletype, 
           linestyle = node.linestyle, fillcolor = node.fillcolor)
    text(ad, node.center, fontsize, node.textcolor, node.text;
         scaletype = node.scaletype, 
         horizontal = "center", vertical = "center")
end

function PlotKitAxes.draw(ad::AxisDrawable, node::RectangularNode)
    scalefactor = getscalefactor(ad; scaletype = node.scaletype)
    leftpx, toppx, txtwidthpx, txtheightpx = get_text_info(ad.ctx, node.fontsize * scalefactor, node.text)
    println((;leftpx, toppx, txtwidthpx, txtheightpx))
    if isnothing(node.widthheight)
        Wleft, Wtop, Wtxtwidthpx, Wtxtheightpx = get_text_info(ad.ctx, node.fontsize * scalefactor, "W")
        w = (txtwidthpx + Wtxtwidthpx) / scalefactor
        h = (txtheightpx + Wtxtheightpx / 2) / scalefactor
    else
        w = node.widthheight.x
        h = node.widthheight.y
    end
    println((;w, h))
    T = [w 0 ; 0 h]
    points = Point[(1,0), (1,1), (0,1), (0,0)]
    points = centerx(points)
    points = [T*a + node.center for a in points]
    println((;points,))
    line(ad, points; closed = true, linestyle = node.linestyle, fillcolor = node.fillcolor)
    text(ad, node.center, node.fontsize, node.textcolor, node.text;
         horizontal = "center", vertical = "center")
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
end

# arrows are sized in axis units
function PlotKitAxes.draw(dw::AxisDrawable, x, dir, arrow::TriangularArrow)
    theta = atan(dir.y, dir.x)
    points = triangle(arrow.angle)
    points = translate(arrow.size .* rotate(points, theta), x)
    line(dw, points; closed = true, fillcolor = arrow.fillcolor)
end

Arrow(args...; kw...) = TriangularArrow(args...; kw...)


##############################################################################
# bezier curves

"""
    curve_from_endpoints(p1, p2, theta1, theta2, r)

Construct bezier control points for a curve from p1 to p2 with departure angles and parameter.
"""
function curve_from_endpoints(p1::Point, p2::Point, theta1, theta2, r)
    u = (p2-p1)/norm(p2-p1)
    T = [u.x -u.y ; u.y  u.x]
    r0 = r * norm(p2-p1)
    c0 = p1
    c1 = p1 + T*polar(r0, theta1)
    c2 = p2 - T*polar(r0, -theta2)
    c3 = p2
    return c0, c1, c2, c3
end

"""
    split_bezier(a::Point, b::Point, c::Point, d::Point, t)

Returns two 4-tuples of Points (a, e, h, k), (k, j, g, d)
such that (a,e,h,k) defines a Bezier curve for the [0,t] segment
of the supplied curve, and (k, j, g, d) the [t,1] segment.

"""
function split_bezier(a::Point, b::Point, c::Point, d::Point, t)
    e = interp(a, b, t)
    f = interp(b, c, t)
    g = interp(c, d, t)
    h = interp(e, f, t)
    j = interp(f, g, t)
    k = interp(h, j, t)
    return (a, e, h, k), (k, j, g, d)
end


"""
     bezier_point(t, p0, p1, p2, p3)

Return the point at position t along the bezier curve with control points p0,p1,p2,p3
"""
function bezier_point(t, p0, p1, p2, p3)
    b = (1-t)^3 * p0 + 3*(1-t)^2*t*p1 + 3*(1-t)*t^2*p2 + t^3 * p3
    return b
end

"""
     bezier_tangent(t, p0, p1, p2, p3)

Return the tangent at position t along the bezier curve with control points p0,p1,p2,p3
"""
function bezier_tangent(t, p0, p1, p2, p3)
    bt = 3*(1-t)^2 *(p1-p0) + 6*(1-t)*t*(p2-p1) + 3*t*t*(p3-p2)
end

"""
     bezier2(t, p0, p1, p2, p3)

Return the position and tangent at position t along the bezier curve with control points p0,p1,p2,p3
"""
bezier2(args...) = bezier_point(args...), bezier_tangent(args...)



##############################################################################


function lineinterp(points, alpha)
    if alpha == 0
        return points[1]
    elseif alpha == 1
        return points[end]
    end
    println("ERROR: cannot interpolate polyline")
end

function lineinterpdirection(points, alpha)
    if alpha == 0
        p1 = points[1]
        p2 = points[2]
        # TODO why is this a Tuple instead of a Point?
        return (x = p2.x-p1.x, y = p2.y-p1.y)
    elseif alpha == 1
        p1 = points[end-1]
        p2 = points[end]
        return (x = p2.x-p1.x, y = p2.y-p1.y)
    end
    println("ERROR: cannot interpolate polyline")
end


##############################################################################

end
