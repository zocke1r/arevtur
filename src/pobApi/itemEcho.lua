local _, _, scriptPath = string.find(arg[0], '(.+[/\\]).-')
package.path = package.path .. ';' .. scriptPath .. '?.lua'
package.path = package.path .. ';' .. [[./lua/?.lua]]
require('HeadlessWrapper')
local inspect = require('inspect')

local function readFile(path)
    local fileHandle = io.open(path, 'r')
    if not fileHandle then return nil end
    local fileText = fileHandle:read('*a')
    fileHandle:close()
    return fileText
end

FakeTooltip = {
	text = ''
}

function FakeTooltip:new()
	o = {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function FakeTooltip:AddLine(_, text)
	self.text = self.text .. text .. '\n'
end

function FakeTooltip:AddSeparator()
    self.text = self.text .. '\n'
end

function findModEffect(modLine, statField)
    -- Construct an empty passive socket node to test in
    local testNode = {id="temporary-test-node", type="Socket", alloc=false, sd={"Temp Test Socket"}, modList={}}

    -- Construct jewel with the mod just to use its mods in the passive node
    local itemText = "Test Jewel\nCobalt Jewel\n"..modLine
    local item
    if build.targetVersionData then -- handle code changes in 1.4.170.17
        item = new("Item", build.targetVersion, itemText)
    else
        item = new("Item", itemText)
    end
    testNode.modList = item.modList

    -- Calculate stat differences
    local calcFunc, baseStats = build.calcsTab:GetMiscCalculator()
    local newStats = calcFunc({ addNodes={ [testNode]=true } })   

    -- Pull out the difference in DPS
    local statVal1 = newStats[statField] or 0
    local statVal2 = baseStats[statField] or 0
    local diff = statVal1 - statVal2
    print(diff)
    return diff
end

-- our loop

io.write('ready ::end::')
io.flush()

while true do
    local input = io.read()
    local _, _, cmd = input:find('<(%w+)>')
    local _, _, value = input:find('<%w+> (.*)')
    print(cmd)
    if cmd == 'exit' then
        os.exit()
    elseif cmd == 'build' then
        loadBuildFromXML(readFile(value))
    elseif cmd == 'item' then
        local itemText = value:gsub([[\n]], "\n")
        local item = new('Item', itemText)
        item:BuildModList()
        local tooltip = FakeTooltip:new()
        build.itemsTab:AddItemTooltip(tooltip, item)
        io.write(tooltip.text .. '::end::')
        io.flush()
    elseif cmd == 'mod' then
       local itemText = [[
           Rarity: normal
           Vine Circlet
       ]] .. value
       local item = new('Item', itemText)
       item:BuildModList()
       local calcFunc, calcBase =  build.calcsTab:GetNodeCalculator()
    --    print('modlist')
    --    print(inspect(item.modList))
       local output = calcFunc({{modList = item.modList}})
       local tooltip = FakeTooltip:new()
    --    print('output')
    --    print(inspect(output))
       build:AddStatComparesToTooltip(tooltip, calcBase, output, "")
       print('tooltip')
       print(tooltip.text)
       io.write(tooltip.text .. '::end::')
       io.flush()
    end
end


