helpers = require("lib.helpers")
unitxt = require("lib.Unitxt")
monsters = require("Monster HP.Monsters")

cfgFontColor = 0xFFFFFFFF
cfgFontSize = 1.0

_PlayerArray = 0x00A94254
_PlayerIndex = 0x00A9C4F4
_PlayerCount = 0x00AAE168
_Difficulty = 0x00A9CD68

_PosX = 0x38
_PosY = 0x3C
_PosZ = 0x40

_EntityCount = 0x00AAE164
_EntityArray = 0x00AAD720

_MonsterUnitxtID = 0x378
_MonsterHP = 0x334
_MonsterHPMax = 0x2BC

function GetMonsterList()
    monsterList = {}

    difficulty = pso.read_u32(_Difficulty)
    ultimate = difficulty == 3

    playerCount = pso.read_u32(_PlayerCount)
    entityCount = pso.read_u32(_EntityCount)

    pIndex = pso.read_u32(_PlayerIndex)
    pAddr = pso.read_u32(_PlayerArray + 4 * pIndex)

    -- If we don't have address (maybe warping or something)
    -- return the empty list
    if pAddr == 0 then
        return monsterList
    end

    -- Get player position
    pPosX = pso.read_f32(pAddr + _PosX)
    pPosZ = pso.read_f32(pAddr + _PosZ)

    for i=1,entityCount,1 do
        mAddr = pso.read_u32(_EntityArray + 4 * (i - 1 + playerCount))

        -- If we got a pointer, then read from it
        if mAddr ~= 0 then
            -- Get monster data
            mUnitxtID = pso.read_u32(mAddr + _MonsterUnitxtID)
            mHP = pso.read_u16(mAddr + _MonsterHP)
            mHPMax = pso.read_u16(mAddr + _MonsterHPMax)
            mPosX = pso.read_f32(mAddr + _PosX)
            mPosZ = pso.read_f32(mAddr + _PosZ)
            
            -- Calculate the distance between it and the player
            xDist = math.abs(pPosX - mPosX)
            zDist = math.abs(pPosZ - mPosZ)
            tDist = math.sqrt(xDist ^ 2 + zDist ^ 2)

            -- Other data
            mName = unitxt.GetMonsterName(mUnitxtID, ultimate)
            mColor = 0xFFFFFFFF
            mDisplay = true
            
            if monsters.m[mUnitxtID] ~= nil then
                mColor = monsters.m[mUnitxtID][1]
                mDisplay = monsters.m[mUnitxtID][2]
            end

            if monsters.maxDistance ~= 0 and tDist > monsters.maxDistance then
                mDisplay = false
            end

            table.insert(monsterList, { show = mDisplay, name = mName, HP = mHP, HPMax = mHPMax, color = mColor })
        end
    end

    return monsterList
end

function PrintMonsters()
    monsterList = GetMonsterList()
    monsterListCount = table.getn(monsterList)
    
    imgui.Columns(2)
    --helpers.imguiTextLine("Monster", 0xFFFFFFFF)
    --imgui.NextColumn()
    --helpers.imguiTextLine("HP", 0xFFFFFFFF)
    --imgui.NextColumn()

    for i=1,monsterListCount,1 do
        if monsterList[i].show then
            mHP = monsterList[i].HP
            mHPMax = monsterList[i].HPMax
            
            helpers.imguiTextLine(monsterList[i].name, monsterList[i].color)
            imgui.NextColumn()
            helpers.imguiProgressBar(mHP/mHPMax, -1.0, 13.0 * cfgFontSize, mHP, helpers.HPToGreenRedGradient(mHP/mHPMax), cfgFontColor)
            imgui.NextColumn()
        end
    end
end

function present()
    imgui.Begin("Monsters")
    imgui.SetWindowFontScale(cfgFontSize)
    PrintMonsters()
    imgui.End()
end

function init()
    return 
    {
        name = "Monster HP",
        version = "1.0.1",
        author = "Solybum"
    }
end

pso.on_init(init)
pso.on_present(present)

return {
    init = init,
    present = present,
}
