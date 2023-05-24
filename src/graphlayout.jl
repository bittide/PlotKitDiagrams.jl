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


module GraphLayout

using ..PlotKitAxes: Point
using LinearAlgebra

export graphlayout, meshlayout

#, meshlayout, shaded_graph, edgeweights_graph

function gradientalg(f, df, epochs, x0)
    minstepsize = 1e-16
    eta = 0.05
    theta = x0
    oldrisk = f(theta)
    newrisk = 0.0
    for k = 1:epochs
        g = df(theta)
       # g2 = gradient(f, theta)[1]
        #println(" g  = ")
        #display(round.(g, digits=2))
        #println(" g2 = ")
        #display(round.(g2, digits=2))
        #println("gdiff = ", norm(g-g2))
        while true
            dtheta = eta * g
            theta .-= dtheta
            newrisk = f(theta)
            if newrisk <= oldrisk
                eta = 1.2 * eta
                break
            else
                eta = 0.5 * eta
                theta .+= dtheta
            end
            if sum(abs.(dtheta)) < minstepsize
                return theta
            end
        end
        oldrisk = newrisk
    end
    return theta
end

function graphlayout(links, n, adjacent_nodes, B,
                     f_adj, f_adj_grad, 
                     f_nonadj, f_nonadj_grad)
    L = B*B'
    D, V = eigen(L)
    v1 = V[:,2]
    v2 = V[:,3]
    x0 = [v1 v2]'*size(B,1)
    f = x -> energy2(x, links, n, adjacent_nodes, f_adj, f_nonadj)
    df = x -> gradenergy(x, links, n, adjacent_nodes, f_adj_grad, f_nonadj_grad)
    x = gradientalg(f, df, 1800, x0)
    z = Point[(a[1],a[2]) for a in eachcol(x0)]
    return z
end

function meshlayout(nx, ny)
     n = nx * ny
     xlist = Point[]
     for i = 1:n
         xc = (i-1) % nx
         yc = div(i-1, nx)
         push!(xlist, Point(xc, yc))
     end
     return xlist
end


# d energy/dx[:,i]
function gradenergyi(i, x, links, n, adjacent_nodes, f_adjacent_grad, f_nonadjacent_grad)
    m = length(links)
    de = zeros(2)
    deltapos(i,j) = x[1,i] - x[1,j], x[2,i] - x[2,j]
    for j=1:n
        if j != i
            dx, dy = deltapos(i,j)
            sd = dx*dx + dy*dy
            if j in adjacent_nodes[i]
                de += 2*f_adjacent_grad(sd)*[dx, dy]
            else
                de += 2*f_nonadjacent_grad(sd)*[dx, dy]
            end
        end
    end
    return de
end

function gradenergy(x, links, n, adjacent_nodes, f_adjacent_grad, f_nonadjacent_grad)
    dx = zeros(2, n)
    for i=1:n
        dx[:,i] = gradenergyi(i, x, links, n, adjacent_nodes, f_adjacent_grad, f_nonadjacent_grad)
    end
    return dx
end

function energy2(x, links, n, adjacent_nodes, f_adjacent, f_nonadjacent)
    m = length(links)
    e = 0.0
    deltapos(i,j) = x[1,i] - x[1,j], x[2,i] - x[2,j]
    for i=1:n
        for j=1:i-1
            dx, dy = deltapos(i,j)
            sd = dx*dx + dy*dy
            if j in adjacent_nodes[i]
                e += f_adjacent(sd)
            else
                e += f_nonadjacent(sd)
            end
        end
    end
    return e
end

#
# todo. fix get_incidence so it returns
# incidence for an oriented graph
#
function graphlayout(links, n)
    f_adj = x -> (sqrt(x)-1)^2
    f_adj_grad = x -> 1 - 1/sqrt(x)
    f_nonadj = x -> 1/x
    f_nonadj_grad = x -> -1/(x*x)
    adjacent_nodes = get_adjacent_nodes(links, n)
    B = get_incidence(links, n)
    return graphlayout(links, n, adjacent_nodes, B,
                       f_adj, f_adj_grad, 
                       f_nonadj, f_nonadj_grad)
end
##############################################################################

function get_adjacent_nodes(edges, n)
    adjacent_nodes = [ Int64[] for i=1:n ]
    for (src, dst) in edges
        push!(adjacent_nodes[src], dst)
        push!(adjacent_nodes[dst], src)
    end
    return adjacent_nodes
end

function get_incidence(edges, n)
    m = length(edges)
    B = zeros(Int64, n, m)
    for (j, (src, dst)) in enumerate(edges)
        B[src, j] = 1
        B[dst, j] =-1
    end
    return B
end


end



