print("Run Lua script DeeArchGlacor.")

local API = require("api")
local UTILS = require("utils")
local projectile = nil
local loopsSinceProj = 0
local clicktile = false
local tile = nil
local location
local inInstance = false
local dodgedIce = false
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
    local player = API.PlayerCoord()
    local objects = API.ReadAllObjectsArray({5},{7480},{})
    local ArchGlacor = API.ReadAllObjectsArray({1}, {28241}, {})

    if #objects > 0 then
        for i = 1, #objects do
            for i=1, #objects, 1 do
                local glacor = ArchGlacor[1]
                local projectile = objects[i]
                local destTile = API.GetProjectileDestination(projectile)
                local sourceTile = WPOINT.new(math.floor(projectile.TileX / 512), math.floor(projectile.TileY / 512), player.z)
                local walkTile
                if sourceTile.x ~= 0 and sourceTile.x ~= destTile.x then
                    if sourceTile.x > destTile.x then
                        walkTile = WPOINT.new(destTile.x - 5, player.y, player.z)
                    else
                        walkTile = WPOINT.new(destTile.x + 5, player.y, player.z)
                    end
                    if (API.Math_DistanceW(player, walkTile) > 4) and not dodgedIce then
                        if sourceTile.x > destTile.x then
                            print(sourceTile.x, destTile.x)
                            print("Dodging Right")
                        else
                            print(sourceTile.x, destTile.x)
                            print("Dodging Left")
                        end
                        API.DoAction_Tile(walkTile)
                        UTILS.countTicks(2)
                        API.WaitUntilMovingEnds()
                        dodgedIce = true
                        API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, glacor)
                    end
                end
            end
        end
    else
        dodgedIce = false
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
    API.DoAction_Object1(0x3d,0,{114748},50)
    API.RandomSleep2(300, 800, 1000)
    API.WaitUntilMovingandAnimEnds()
    API.RandomSleep2(500, 1100, 2570)
    API.DoAction_Object1(0x2e,80,{114750},50)
    API.RandomSleep2(300, 800, 1000)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(500, 1100, 2570)
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
        local targets = API.GetAllObjArrayInteract({28241}, 30, {1})
        API.DoAction_NPC__Direct(0x2a, API.OFF_ACT_AttackNPC_route, targets[1])
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
