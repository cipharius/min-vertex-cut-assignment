local gv = require "gv"

local nullptr = setmetatable({}, {
    __index = function() error("Attempt to index nullptr") end;
    __newindex = function() error("Attempt to assign to nullptr") end;
})

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
        parent = nullptr;
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
        source = nullptr;
        sink = nullptr;
    }, Graph)

    -- Create vertices
    for i=1,n do
        table.insert(self.vertices, Vertex.new(i))
    end
    self.source = self.vertices[1]
    self.sink = self.vertices[n]

    -- Create edges
    for _,edge in pairs(edges) do
        local v1 = self.vertices[edge[1]]
        local v2 = self.vertices[edge[2]]
        self:AddEdge(v1, v2)
    end

    return self
end

function Graph:AddEdge(v1, v2)
    local e1 = Edge.new(v1, v2)
    local e2 = Edge.new(v2, v1)

    e1.reverse = e2
    e2.reverse = e1
    
    table.insert(v1.eOut, e1)
    table.insert(v1.eIn, e2)
    table.insert(v2.eIn, e1)
    table.insert(v2.eOut, e2)
    
    table.insert(self.edges, e1)
    table.insert(self.edges, e2)

    return e1, e2
end

function Graph:UpdateDists(notLimited)
    for _,vertex in pairs(self.vertices) do
        vertex.dist = math.huge
        vertex.parent = nullptr
    end
    self.source.dist = 0
    
    local queue = Queue.new({self.source})
    while not queue:IsEmpty() do
        local v = queue:Pop()

        for _,edge in pairs(v.eOut) do
            local vNext = edge.vOut
            local residual = edge.capacity - edge.flow
            
            if (notLimited or residual > 0) and vNext.dist > v.dist then
                vNext.parent = v
                vNext.dist = v.dist + 1
                queue:Push(vNext)
            end
        end
    end
end

function Graph:DoubleVertices()
    self:UpdateDists(true)
    local n = #self.vertices
    local vPairs = {}

    for i=2,n-1 do
        local v1 = self.vertices[i]
        local v2 = Vertex.new(n+i-1)
        v2.dist = v1.dist

        local inbound = {}
        for i=#v1.eIn,1,-1 do
            if v1.eIn[i].vIn.dist > v1.dist then
                inbound[#inbound+1] = v1.eIn[i]
                v1.eIn[i] = v1.eIn[#v1.eIn]
                v1.eIn[#v1.eIn] = nil
            end
        end

        local outbound = {}
        for i=#v1.eOut,1,-1 do
            if v1.eOut[i].vOut.dist > v1.dist then
                outbound[#outbound+1] = v1.eOut[i]
                v1.eOut[i] = v1.eOut[#v1.eOut]
                v1.eOut[#v1.eOut] = nil
            end
        end

        for _,edge in pairs(inbound) do
            table.insert(v2.eIn, edge)
            edge.vOut = v2
        end

        for _,edge in pairs(outbound) do
            table.insert(v2.eOut, edge)
            edge.vIn = v2
        end

        table.insert(self.vertices, v2)

        local e1,e2 = self:AddEdge(v1, v2)
        e1.capacity = 1
        e2.capacity = 1

        table.insert(vPairs, {v1, v2})
    end

    return vPairs
end

function Graph:SendFlow(v)
    if v == self.sink then return 1 end
    
    for _,edge in pairs(v.eOut) do
        if edge.capacity > edge.flow and edge.vOut.dist == v.dist + 1 then
            if self:SendFlow(edge.vOut) > 0 then
                edge.flow = 1
                edge.reverse.flow = 0
                return 1
            end
        end
    end
    
    return 0
end

function Graph:MaximizeFlow()
    self:UpdateDists()

    while self.sink.dist < math.huge do
        repeat until self:SendFlow(self.source) == 0
        self:UpdateDists()
    end
end

Graph.__index = Graph
Graph.__newindex = function() error("Attempt to assign new attribute to instance of Graph") end

-- Utilities

function drawGraph(graph, filename)
    local g = gv.graph(filename)
    local nodes = {}

    for _,vertex in pairs(graph.vertices) do
        local n = gv.node(g, vertex.idx)
        gv.setv(n, "shape", "circle")
        table.insert(nodes, n)
    end
    gv.setv(nodes[graph.source.idx], "color", "blue")
    gv.setv(nodes[graph.sink.idx], "color", "green")

    for _,edge in pairs(graph.edges) do
        local v1 = edge.vIn
        local v2 = edge.vOut
        local e = gv.edge(nodes[v1.idx], nodes[v2.idx])

        if (v1.dist + v2.dist == math.huge) and v1.dist ~= v2.dist then
            gv.setv(e, "color", "red")

            if v1.dist < math.huge then
                gv.setv(nodes[v1.idx], "color", "red")
                gv.setv(nodes[v2.idx], "color", "red")
            end
        end

        if edge.capacity == 1 then
            gv.setv(e, "len", 0.5)
            
            if v1.idx < graph.sink.idx then
                gv.setv(nodes[v2.idx], "label", edge.vIn.idx.."'")
            end
        end
        
        gv.setv(e, "dir", "forward")
    end

    gv.layout(g, "neato")
    gv.render(g, "pdf", filename..".pdf")
end

function printTable(t, maxDepth, depth)
    local maxDepth = maxDepth or 3
    local depth = depth or 0
    local indent = ("  "):rep(depth)
    
    for k,v in pairs(t) do
        if type(v) == "table" then
            if depth == maxDepth then
                print(indent..tostring(k)..": "..tostring(t).."; len="..#t)
            elseif next(v) == nil then
                print(indent..tostring(k)..": {}")
            else
                print(indent..tostring(k)..":")
                printTable(v, maxDepth, depth+1)
            end
        else
            print(indent..tostring(k)..": "..tostring(v))
        end
    end
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

    local vPairs = G:DoubleVertices()
    G:MaximizeFlow()

    local result = {}
    for _,vPair in pairs(vPairs) do
        -- Boundary before blocking flows
        if vPair[1].dist < math.huge and vPair[2].dist == math.huge then
            table.insert(result, vPair[1].idx)
        end
    end
   
    drawGraph(G, "after")
    print(#result, table.unpack(result))
end
main()
