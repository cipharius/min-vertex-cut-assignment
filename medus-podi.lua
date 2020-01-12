local gv = require "gv"

local nullptr = {}

-- Vertex class
local Vertex = {}
function Vertex.new(idx)
    return setmetatable({
        idx = idx;
        dist = math.huge;
        owner = nullptr;
        eIn = {};
        eOut = {};
    }, Vertex)
end
Vertex.__newindex = function() error("Attempt to assign new attribute to instance of Vertex") end

-- Edge class
local Edge = {}
function Edge.new(v1, v2)
    return setmetatable({
        vIn = v1;
        vOut = v2;
        flow = 0;
        capacity = math.huge;
        reverse = nullptr;
    }, Edge)
end
Edge.__newindex = function() error("Attempt to assign new attribute to instance of Edge") end

-- Graph class
local Graph = {}
function Graph.new(n, edges)
    local self = setmetatable({
        vertices = {};
        edges = {};
    }, Graph)

    -- Create vertices
    for i=1,n do
        table.insert(self.vertices, Vertex.new(i))
    end

    -- Create edges
    for _,edge in pairs(edges) do
        table.insert(self.edges, Edge.new(edge[1], edge[2]))
    end

    return self
end
Graph.__index = Graph
Graph.__newindex = function() error("Attempt to assign new attribute to instance of Graph") end

-- Utilities

function drawGraph(graph, filename)
    local g = gv.graph(filename)
    local nodes = {}

    for _,vertex in pairs(graph.vertices) do
        table.insert(nodes, gv.node(g, vertex.idx))
    end

    for _,edge in pairs(graph.edges) do
        local v1 = edge.vIn
        local v2 = edge.vOut
        local e = gv.edge(nodes[v1.idx], nodes[v2.idx])
    end

    gv.layout(g, "neato")
    gv.render(g, "pdf", filename..".pdf")
end

function readInputFile(filename)
    local file = io.open(filename)
    if not file then error("Couldn't open file \""..filename.."\"") end

    local n = file:read("n*")
    local result = {}

    while true do
        local v1 = file:read("n*")
        local v2 = file:read("n*")

        if v1 == nil or v2 == nil then break end
        result[#result+1] = {v1, v2}
    end

    return n, result
end

function main()
    readInputFile("input.dat")
    local G = Graph.new(readInputFile("input.dat"))

    drawGraph(G, "before")
end
main()
