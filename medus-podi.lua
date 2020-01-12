local gv = require "gv"

local nullptr = {}

-- Queue class
local Queue = {}
function Queue.new(init)
    local self = setmetatable({
        items = {};
        first = 0;
        last = 0;
    }, Queue)

    if init and type(init) == "table" and #init > 0 then
        self.items = {unpack(init)}
        self.last = #self.items + 1
        self.first = 1
    end

    return self
end

function Queue:Push(item)
    self.items[self.last] = item
    self.last = self.last + 1
end

function Queue:Pop()
    if self.first == self.last then
        return nil
    end
    
    local item = self.items[self.first]
    self.items[self.first] = nil
    self.first = self.first + 1

    if self.first == self.last then
        self.first = 0
        self.last = 0
    end
    
    return item
end

function Queue:IsEmpty()
    return self.first == self.last
end

Queue.__index = Queue
Queue.__newindex = function() error("Attempt to assign new attribute to instance of Queue") end

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
        local v1 = self.vertices[edge[1]]
        local v2 = self.vertices[edge[2]]
        table.insert(self.edges, Edge.new(v1, v2))
        table.insert(self.edges, Edge.new(v2, v1))
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
        gv.setv(e, "dir", "forward")
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
