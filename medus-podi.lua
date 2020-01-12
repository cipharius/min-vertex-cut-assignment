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
    --local G = Graph.new(readInputFile("input.dat"))
end
main()
