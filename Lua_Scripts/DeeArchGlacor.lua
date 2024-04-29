print("Run Lua script DeeArchGlacor.")

local API = require("api")
local UTILS = require("utils")
local projectile = nil
local loopsSinceProj = 0
local clicktile = false
local tile = nil
local location
local inInstance = false
local locations = {
    ["Retreat"] = {
        spawn = WPOINT.new(3294,10127,0),
        portal = WPOINT.new(3289,10152,0),
        portalobject = 121370
    },
    ["Boss"] = {
        spawn = WPOINT.new(1754,1112,0),
        portal = WPOINT.new(1751,1103,0),
        portalobject = 121338
    }
}
local items = {
    1631, -- dragonstones
    51817, -- manuscript of wen
    12176, -- spirit weed seed
    52018, -- glacor remnants
    51809, -- Resonant anima of wen
    12163, -- blue charms
    12160, -- crimson charms
    12159, -- green charms
    12158, -- gold charms
    6693, -- crushed nests
    44813, -- banite stone spirit
    28547, -- crystal trisk frag 1
    32821, -- summoning focus
    1395, -- water battlestaff
    42954, -- onyx dust
    42009, -- sealed elite clue scroll
    1444, -- water talisman
    989, -- crystal key
    52121, -- medium blunt orikalkum salvage
    31867, -- hydrix bolt tips
    29863, -- serenic scale
    53279, -- chaos die reroll token
    28550 -- crystal triskelion key
}


local function checkProjectile()
    local objects = API.ReadAllObjectsArray({5},{-1},{})
    for i = 1, #objects do
        if objects[i].Id ~= 0 then
            if objects[i].Id == 7480 then
                projectile = objects[i]
            end
        end
    end
    if projectile ~= nil then
        projectile.TileX = math.floor(projectile.TileX/512)
        projectile.TileY = math.floor(projectile.TileY/512)
        projectile.TileZ = math.floor(projectile.TileZ/512)

        if API.Dist_FLPW(WPOINT.new(projectile.TileX,projectile.TileY,projectile.TileZ)) >= 20 then
            projectile = nil
        end
        if loopsSinceProj == 0 and projectile ~= nil then
            clicktile = true
            tile = WPOINT.new(projectile.TileX,projectile.TileY,projectile.TileZ)
        end
        if projectile ~= nil then
            loopsSinceProj = 0
        end
    else
        loopsSinceProj = loopsSinceProj + 1
    end
end

local function checkforIceWalls()
    local iceWall = API.GetAllObjArrayInteract({121360,121361,121362,121363,121364}, 3, {0})
    if #iceWall < 1 then
        if clicktile and loopsSinceProj >= 1 then
            API.DoAction_Tile(tile)
            API.RandomSleep2(300, 1000, 2000)
            API.WaitUntilMovingEnds()
            clicktile = false
            local targets = API.GetAllObjArrayInteract({28241}, 30, {1})
            if #targets > 0 then
                print("Found Arch Glacor")
                print("Attacking Arch Glacor...")
                API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, targets[1])
            end
        end    
    end
end

local function checkPrayer()
    if API.GetPray_() <= 100 then
        API.DoAction_Interface(0x2e,0xbd0,1,1430,207,-1,3808)
    end
    
    if API.VB_FindPSettinOrder(3272, 0).state == 0 then
        API.DoAction_Interface(0x2e,0xffffffff,1,1430,220,-1,3808)
        API.RandomSleep2(600, 0, 0)
    end
end

local function lootDrops()
    API.DoAction_Loot_w(items, 20, API.PlayerCoordfloat(), 10)
    API.RandomSleep2(300, 800, 1000)
    API.WaitUntilMovingEnds()
    API.DoAction_LootAll_Button()
    API.RandomSleep2(300, 800, 1000)
end

local function castRetreat()
    local warAB = UTILS.getSkillOnBar("War's Retreat Teleport")
    if warAB ~= nil then
        return API.DoAction_Ability_Direct(warAB, 1, API.OFF_ACT_GeneralInterface_route)
    end
    return false
end

local function bank()
    API.DoAction_Object1(0x2e,80,{114750},50)
    API.RandomSleep2(300, 800, 1000)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(500, 1100, 2570)
    print(API.BankOpen2())
    API.KeyboardPress("1")
    API.RandomSleep2(300, 800, 1000)
end

local function checklocation()
    if API.Dist_FLPW(locations["Retreat"].spawn) <= 20 then
        return "Retreat"
    elseif API.Dist_FLPW(locations["Boss"].spawn) <= 20 then
        return "Boss"
    end
end

local function enterPortal()
    print("Entering Portal")
    API.DoAction_Object1(0x39,0,{locations["Retreat"].portalobject},50)
    API.RandomSleep2(300, 800, 1000)
    API.WaitUntilMovingandAnimEnds()
    API.RandomSleep2(300, 800, 1000)
end

local function isBossAlive()
    local targets = API.GetAllObjArrayInteract({28241}, 30, {1})
    if #targets > 0 then
        return true
    end
    return false
end

local function enterInstance()
    print("Entering Instance")
    API.DoAction_Object1(0x39,0,{locations["Boss"].portalobject},50)
    API.RandomSleep2(500, 2000, 5000)
    API.WaitUntilMovingEnds()
    API.DoAction_Interface(0x24,0xffffffff,1,1591,60,-1,3808)
    API.RandomSleep2(800, 3000, 5600)
    if API.Dist_FLPW(locations.Boss.portal) > 20 then
        local playspawn = API.PlayerCoordfloat()
        API.DoAction_Tile(WPOINT.new(playspawn.x+16,playspawn.y-4,0))
        API.RandomSleep2(300, 800, 1000)
        API.WaitUntilMovingEnds()
        while not isBossAlive() do
            API.RandomSleep2(300, 800, 1000)
        end
        inInstance = true
    end
end


--Exported function list is in API
--main loop
while(API.Read_LoopyLoop())
do-----------------------------------------------------------------------------------
    location = checklocation()
    if inInstance == true then
        checkProjectile()
        checkforIceWalls()
        checkPrayer()
        if not isBossAlive() then
            lootDrops()
            castRetreat()
            API.RandomSleep2(500, 2000, 3000)
            API.WaitUntilMovingandAnimEnds()
            inInstance = false
        end
    else
        if location == "Retreat" then
            API.RandomSleep2(500, 1000, 2500)
            bank()
            print("Walking to Portal...")
            API.DoAction_Tile(locations["Retreat"].portal)
            API.RandomSleep2(300, 800, 1000)
            API.WaitUntilMovingEnds()
            enterPortal()
        elseif location == "Boss" then
            API.RandomSleep2(300, 800, 1000)
            API.DoAction_Tile(locations["Boss"].portal)
            API.RandomSleep2(300, 800, 1000)
            API.WaitUntilMovingEnds()
            enterInstance()
        end
    end

    UTILS:antiIdle()
    API.RandomSleep2(10, 0, 0)
end----------------------------------------------------------------------------------
