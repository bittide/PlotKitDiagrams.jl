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

module Graphs

using ..NodePaths: Node, Path, bounding_box
using ..PlotKitAxes: Axis, AxisDrawable, PlotKitAxes, Point, draw, drawaxis, drawbackground, setoptions!
using ..PlotKitCairo: corners

export Graph, drawgraph

getentry(a, i) = a
getentry(a::Array, i) = a[i]

# will depend on diagrams
Base.@kwdef mutable struct Graph
    extras = []
    nodes = Node()
    paths = Path()
    links = []
    x = []
    axis = nothing
    pathmap = (gr, s, d, xs, xd) -> [xs, xd]
    nodemap = (gr, i, p) -> p
end

function PlotKitAxes.draw(ad::AxisDrawable, gr::Graph)
    for a in gr.extras
        draw(ad, a)
    end

    for (j, (src,dst)) in enumerate(gr.links)
        path = getentry(gr.paths, j)
        path.points = gr.pathmap(gr, src, dst, gr.x[src], gr.x[dst])
        draw(ad, path)
    end
    for i=1:length(gr.x)
        node = getentry(gr.nodes, i)
        node.center = gr.nodemap(gr, i, gr.x[i])
        draw(ad, node)
    end
end

#makelist(a::Vector) = a
#makelist(a) = [a]

graph_axis_defaults() = Dict(
    :axisstyle_drawaxisbackground => false,
    :axisstyle_drawxlabels => false,
    :axisstyle_drawylabels => false,
    :widthfromdata => 60,
    :heightfromdata => 60,
    :lmargin => 0,
    :rmargin => 0,
    :tmargin => 0,
    :bmargin => 0,
    :axisstyle_fontsize => 3,
    :xdatamargin => 0.25,
    :ydatamargin => 0.25
)


function Graph(links, x; kwargs...)

    graph = Graph()
    setoptions!(graph, "graph_", kwargs...)
    corns = vcat([corners(bounding_box(e)) for e in graph.extras]...)
    graph.axis = Axis(Point[x ; corns]; merge(graph_axis_defaults(), kwargs)...)
    graph.links = links
    graph.x = x
    return graph
end

function PlotKitAxes.draw(gr::Graph)
    ad = AxisDrawable(gr.axis)
    drawaxis(ad)
    draw(ad, gr)
    return ad
end


    
end

