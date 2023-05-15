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


export Graph, drawgraph

getentry(a, i) = a
getentry(a::Array, i) = a[i]

# will depend on diagrams
Base.@kwdef mutable struct Graph
    nodes = Node()
    paths = Path()
end

function drawgraph(ax, ctx, links, x, st)
    for (j, (src,dst)) in enumerate(links)
        path = getentry(st.paths, j)
        draw(ax, ctx, x[src], x[dst], path)
    end
    for i=1:length(x)
        node = getentry(st.nodes, i)
        draw(ax, ctx, x[i], node)
    end
end

function drawgraph(links, x; kwargs...)
    graph = Graph()
    setoptions!(graph, "graph_", kwargs...)

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
        :xdatamargin => 0.25,
        :ydatamargin => 0.25
    )

    ad = AxisDrawable(x; merge(defaults, kwargs)...)
    rect(ad, Point(0,0), Point(d.width, d.height);
         fillcolor = d.axis.windowbackgroundcolor)
    drawgraph(ad.axis.ax, ctx, links, x, graph)
    end
    return d
end


    
end

