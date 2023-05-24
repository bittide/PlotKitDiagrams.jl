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

using ..NodePaths: Node, Path
using ..PlotKitAxes: AxisDrawable, Point, draw, drawaxis, drawbackground, setoptions!

export Graph, drawgraph

getentry(a, i) = a
getentry(a::Array, i) = a[i]

# will depend on diagrams
Base.@kwdef mutable struct Graph
    nodes = Node()
    paths = Path()
end

function drawgraph(ad::AxisDrawable, links, x, st)
    for (j, (src,dst)) in enumerate(links)
        path = getentry(st.paths, j)
        path.points = [x[src], x[dst]]
        draw(ad, path)
    end
    for i=1:length(x)
        node = getentry(st.nodes, i)
        node.center = x[i]
        draw(ad, node)
    end
end
makelist(a::Vector) = a
makelist(a) = [a]

function drawgraph(links, x; kwargs...)
    graph = Graph()
    setoptions!(graph, "graph_", kwargs...)
    for a in makelist(graph.nodes)
        if isnothing(a.radius)
            a.radius = 0.15
        end
        if isnothing(a.fontsize)
            a.fontsize = 0.1
        end
    end
    
    
    defaults = Dict(
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

    ad = AxisDrawable(x; merge(defaults, kwargs)...)
    drawaxis(ad)
    drawgraph(ad, links, x, graph)
    close(ad)
end


    
end

