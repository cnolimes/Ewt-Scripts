-- Created by romain-p
-- see updates on http://github.com/romain-p

if not shared then shared = true
    SharedConfiguration = {
        melee_range = 7,
        gcd_value = 1.5,

        Totems = {
            TREMOR = "Tremor Totem",
            EARTHBIND = "Earthbind Totem",
            CLEANSING = "Cleansing Totem",
            TOTEM_OCCURENCE = "Totem"
        },

        StealthSpells = {
            RogueSpells.VANISH,
            RogueSpells.STEALTH,
            DruidSpells.PROWL,
            RaceSpells.SHADOWMELD
        }
    }

    enemy = "enemy"
    ally = "ally"
    target = "target"
    party1 = "party1"
    party1pet = "party1pet"
    party2 = "party2"
    party2pet = "party2pet"
    party3 = "party3"
    party3pet = "party3pet"
    player = "player"
    pet = "pet"
    player_name = UnitName(player)
    objectTimer = -1
    analizeTimer = -1
    simpleTimer = -1
    enabled = false

    WorldObjects = {}
    FrameCallbacks = {}

    aCallbacks = {}
    sCallbacks = {}

    Party = {
        "party1",
        "party2",
        "party3",
        "party1pet",
        "party2pet",
        "party3pet"
    }

    ArenaEnemies = {
        "arenapet1",
        "arenapet2",
        "arenapet3",
        "arena1",
        "arena2",
        "arena1pet",
        "arena2pet",
        "arena3pet",
        "target",
        "mouseover",
        "focus",
    }

    WorldEnemies = {
        "target",
        "targettarget",
        "focustarget",
        "focus",
        "mouseover"
    }

    function TableConcat(t1, t2)
        for k, v in pairs(t2) do
            t1[k] = v
        end
        return t1
    end

    Spells = {}
    SpellNames = {}
    SpellIds = {}

    TableConcat(Spells, PriestSpells)
    TableConcat(Spells, RogueSpells)
    TableConcat(Spells, DruidSpells)
    TableConcat(Spells, HunterSpells)
    TableConcat(Spells, WarriorSpells)
    TableConcat(Spells, MageSpells)
    TableConcat(Spells, WarlockSpells)
    TableConcat(Spells, ShamanSpells)
    TableConcat(Spells, PaladinSpells)
    TableConcat(Spells, DkSpells)
    TableConcat(Spells, RaceSpells)

    function HoldSpells(table)
        local var
        for _, v in pairs(table) do
            var = select(1, GetSpellInfo(v))
            if var ~= nil then
                SpellNames[v] = var
                SpellIds[strlower(var)] = v
            end
        end
    end

    HoldSpells(Spells)
    HoldSpells(Auras)

    -- Returns the spell id of a given spell name
    function GetSpellId(spellname)
        return SpellIds[strlower(spellname)]
    end

    -- Return true if the player is playing in Arena
    function IsArena()
        return select(1, IsActiveBattlefieldArena()) == 1
    end

    -- Return an enemy array depending on the current area of the player
    function GetEnemies()
        if IsArena() then
            return ArenaEnemies
        else
            return WorldEnemies
        end
    end

    -- Return true if unit is in los with otherunit
    function InLos(unit, otherUnit)
        if not otherUnit then otherUnit = player end
        if not UnitExists(otherUnit) then return end

        if UnitIsVisible(unit) or 1 == 1 then
            local X1, Y1, Z1 = ObjectPosition(unit);
            local X2, Y2, Z2 = ObjectPosition(otherUnit);

            return not TraceLine(X1, Y1, Z1 + 2, X2, Y2, Z2 + 2, 0x10);
        end
    end

    -- Return true if a given type is checked
    function ValidUnitType(unitType, unit)
        local isEnemyUnit = UnitCanAttack(player, unit) == 1
        return (isEnemyUnit and unitType == enemy)
                or (not isEnemyUnit and unitType == ally)
    end

    -- Return if a given unit exists, isn't dead
    function ValidUnit(unit, unitType)
        return UnitExists(unit) == 1 and ValidUnitType(unitType, unit)
    end

    -- Return true if the Cooldown of a given spell is reset (with gcd or not)
    function CdRemains(spellId, gcd)
        if gcd == nil then gcd = true end
        local duration = select(2, GetSpellCooldown(spellId))

        if gcd then
            return not (duration
                    + (select(1, GetSpellCooldown(spellId)) - GetTime()) >= 0)
        else
            return SharedConfiguration.gcd_value - duration >= 0
        end
    end

    -- Return true if a given spell can be casted
    function Cast(id, unit, type)
        unit = unit or player
        type = type or ally

        if CdRemains(id, false)
                and ValidUnit(unit, type)
                and InLos(player, unit)
                and (unit == player or IsSpellInRange(SpellNames[id], unit) == 1) then
            CastSpellByID(id, unit)
            return true
        end
        return false
    end

    -- Return the current player stance
    function GetStance()
        return GetShapeshiftForm()
    end

    -- Return true if a given unit is under <id> dot for more than 3 seconds
    function HasDot(id, unit)
        local dot = select(7, UnitDebuff("target", GetSpellInfo(id)))
        return dot ~= nil and dot - GetTime() >= 3
    end

    -- Return true if a given aura is present on a given unit
    function HasAura(id, unit)
        return UnitDebuff(unit, SpellNames[id]) ~= nil or
                select(11, UnitAura(unit, SpellNames[id])) == id
    end

    -- same as HasAura but with an array, returns array of spellIds that matched, empty if none
    function HasAuraInArray(array, unit)
        local matched = {}

        for j=1, #array do
            local id = array[j]

            if HasAura(id, unit) then
                matched[#matched + 1] = id
            end
        end

        return matched
    end

    -- Return true if a given unit health is under a given percent
    function HealthIsUnder(unit, percent)
        return (((100 * UnitHealth(unit) / UnitHealthMax(unit))) < percent)
    end

    -- Return true if the whole party has health > x
    function HealthTeamNotUnder(percent)
        for _, unit in ipairs(Friends) do
            if UnitExists(unit) and HealthIsUnder(unit, percent) then
                return false
            end
        end
        return true
    end

    -- Return true if a given unit isn't dmg protected
    function IsDamageProtected(unit)
        return HasAura(Auras.DIVINE_SHIELD, unit)
                or HasAura(Auras.HAND_PROTECTION, unit)
                or HasAura(Auras.CYCLONE, unit)
                or HasAura(Auras.ICEBLOCK, unit)
                or HasAura(Auras.DETERRENCE, unit)
                or HasAura(Auras.GROUNDING_TOTEM, unit)
                or HasAura(Auras.BEAST, unit)
                or HasAura(Auras.MAGIC_SHIELD, unit)
    end

    -- Return true if in melee range with a given unit
    function MeleeRange(unit)
        return GetDistanceBetweenObjects(player, unit) < SharedConfiguration.melee_range
    end

    -- Return true if a target is stealthed
    function IsStealth(unit)
        return HasAura(RogueSpells.VANISH, unit) or
                HasAura(RogueSpells.STEALTH, unit) or
                HasAura(DruidSpells.PROWL, unit) or
                HasAura(RaceSpells.SHADOWMELD, unit)
    end

    -- Take a callback(object, name, position) that gonna be called iterating map objects.
    -- Return true in the callback to break the loop, false otherwise
    function IterateObjects(enabled, callback)
        if not enabled then return end

        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local name = ObjectName(object)
            local x, y, z = ObjectPosition(object)

            if callback(object, name, x, y, z) then
                break
            end
        end
    end

    -- Listen spells and performs your callback(event, srcName, targetGuid, targetName, spellId, object, pos) when one is fired
    function ListenSpellsAndThen(auraArray, enabled, callback)
        if not enabled then return end

        for i=1, #auraArray do
            FrameCallbacks[auraArray[i]] = callback;
        end
    end

    -- Register a callback(object, name, position) that gonna be called while iterating world map objects
    function RegisterAdvancedCallback(enabled, callback)
        if not enabled then return end

        aCallbacks[#aCallbacks + 1] = callback
    end

    -- Register a callback() that gonna be called in an loop
    function RegisterSimpleCallback(enabled, callback)
        if not enabled then return end

        sCallbacks[#sCallbacks + 1] = callback
    end

    -- Applies ur callback(auraId, object, name, position) when some of the world map units has active aura present in the aura array
    function KeepEyeOnWorld(auraArray, enabled, to_apply)
        if not enabled then return end

        local callback =
            function(object, name, x, y, z)
                local active_auras = HasAuraInArray(auraArray, object)

                for j=1, #active_auras do
                    to_apply(active_auras[j], object, name, x, y, z)
                end
            end

        RegisterAdvancedCallback(true, callback)
    end

    -- Applies ur callback(auraId, unit) when some of ur units has active aura present in the aura array
    function KeepEyeOn(units, auraArray, enabled, to_apply)
        if not enabled then return end

        local callback = function()
            for i=1, #units do
                local unit = units[i]
                if UnitExists(unit) then
                    local active_auras = HasAuraInArray(auraArray, unit)

                    for j=1, #active_auras do
                        to_apply(active_auras[j], unit)
                    end
                end
            end
        end

        RegisterSimpleCallback(true, callback)
    end

    function stopTimers(timers)
        for i=1, #timers do
            local timer = timers[i]
            if timer ~= nil then
                StopTimer(timer)
            end
        end
    end

    -- Spots instant trying to stealth
    ListenSpellsAndThen(SharedConfiguration.StealthSpells, Configuration.STEALTH_SPOT.ENABLED,
        function(_, _, _, _, _, object, _, _, _)
            SpellStopCasting()
            Cast(Configuration.STEALTH_SPOT.SPELL_ID, object, enemy)
            TargetUnit(found)
        end
    )

    -- Break stealth of world targets
    KeepEyeOnWorld(SharedConfiguration.StealthSpells, Configuration.STEALTH_SPOT.ENABLED,
        function(_, object, _, _, _, _)
            if not HasAuraInArray(SharedConfiguration.StealthSpells, object) then return end

            Cast(Configuration.STEALTH_SPOT.SPELL_ID, object, enemy)
            TargetUnit(object)
        end
    )

    -- Call registered simple callbacks
    function SimpleLoop()
        for i=1, #sCallbacks do
            sCallbacks[i]()
        end
    end

    -- Analize all world map objects, calling registed iterate callbacks
    function AnalizeWorld()
        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local name = ObjectName(object)
            local x, y, z = ObjectPosition(object)

            for j = 1, #aCallbacks do
                aCallbacks[j](object, name, x, y, z)
            end
        end
    end

    -- Refresh all objects table indexed by name
    function RefreshObjects()
        for i = 1, ObjectCount() do
            local object = ObjectWithIndex(i)
            local objectName = ObjectName(object)

            local hold = WorldObjects[objectName]
            if hold ~= object then
                WorldObjects[objectName] = object;
            end
        end
    end

    sharedFrame = CreateFrame("FRAME", nil, UIParent)
    sharedFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    sharedFrame:RegisterEvent("PLAYER_LOGIN")
    sharedFrame:SetScript("OnEvent",
        function(self, event, _, type, srcGuid, srcName, _, targetGuid, targetName, _, spellId)

            if type == "PLAYER_LOGIN" then
                stopTimers({objectTimer, analizeTimer, simpleTimer})
                do return end
            end

            local object = WorldObjects[srcName]

            for k,v in pairs(FrameCallbacks) do
                if k == spellId then
                    local x, y, z = ObjectPosition(object)
                    v(event, srcName, targetGuid, targetName, spellId, object, x, y, z)
                end
            end
        end
    )

    function OnDisable()
        sharedFrame:SetScript("OnEvent", nil)
        stopTimers({objectTimer, analizeTimer, simpleTimer})
        print("[Shared-API] succesfully disabled")
        PlaySound("TalentScreenClose", "master")
    end

    function OnEnable()
        objectTimer = CreateTimer(500, RefreshObjects)
        analizeTimer = CreateTimer(20, AnalizeWorld)
        simpleTimer = CreateTimer(20, SimpleLoop)

        if objectTimer ~= nil and analizeTimer ~= nil and simpleTimer ~= nil then
            print("[Shared-API] successfully enabled")
            PlaySound("AuctionWindowClose", "master")
            return true
        else
            print(objectTimer, analizeTimer, simpleTimer)
            print("[Shared-API] an error occured, please /reload")
            return false
        end
    end
end