## Ewt Scripts

All features in need are performing `LoS`, `range`, `cooldown` and `unit type` checks  
Each analysis doesnt need to have defined unit e.g `target`/`focus`/`arena123`. The script performs checks analysing all map objects  
`No fps`are taken with my scripts, I `optimized` all the code

### Installation

* Make a folder called `script` in your world of warcraft folder  
* Put all .lua files in this folder
* Example of location: `your_wow_folder/script/shared.lua`
* Finally enable it with the ewt-command e.g `.loadfile script/priest_disc.lua`

### Documentation

#### Shared API

Shared-API holds units in variables that are frequently used, use them as well!  
The following functions I'll describe are the most scallable of the Share-API.
See more specific functions directly in the file `shared.lua`

* Apply a `callback(auraId, object, name, position)` when some of the world map units has an aura present in the aura array
````lua
    function KeepEyeOnWorld(auraArray, enabled, callback);
    
    -- Naive Example
    -- This function holds an advanced callback in a shared table 
    -- The callback is gonna cast mass dispel when a player is found with divine shield in the world map
    KeepEyeOnWorld({Auras.DIVINE_SHIELD}, true, -- true to enable the feature
        function(_, object, x, y, z)
            CastSpellByID(PriestSpells.MASS_DISPEL)
            ClickPosition(x, y, z)
         end
    )
````

* Apply a `callback(auraId, unit)` when some of ur units has active aura present in the aura array
````lua
    function KeepEyeOn(units, auraArray, enabled, to_apply);
    
    -- Naive Example
    -- This function holds a simple callback in a shared table
    -- The callback is gonna dispel party1 and party when they are under HOJ
    KeepEyeOn({party1, party2}, {Auras.HOJ}, true, -- true to enable the feature
        function(auraId, unit)
            CastSpellByID(PaladinSpells.CLEANSE, unit)
        end
    )
````

* Listen casted spells in the world map and perform a `callback(event, srcName, targetGuid, targetName, spellId, object, pos)` when one is fired
````lua
    function ListenSpellsAndThen(auraArray, enabled, callback);
    
    -- Naive Example
    -- This function holds a callback in a shared table
    -- This callback is gonna Charge a rogue when he tries to be stealth
    ListenSpellsAndThen({RogueSpells.VANISH, RogueSpells.STEALTH}, true, -- true to enable the feature
        function(event, srcName, targetGuid, targetName, spellId, object, x, y, z)
            CastSpellByID(WarriorSpells.CHARGE, object)
        end
    )
````

* See also 'primitive' functions to register a custom callback
````lua
    -- Take a callback(object, name, position) that gonna be called for each map object.
    -- Return true in the callback to break the loop, false otherwise
    -- /!\ This function doesnt hold the callback, it performs only one loop
    function IterateObjects(enabled, callback)

    -- Register a callback(object, name, position) that gonna be called while iterating world map objects
    function RegisterAdvancedCallback(enabled, callback);

    -- Register a callback() that gonna be called in an loop
    function RegisterSimpleCallback(enabled, callback);
````

#### Priest Scripts

See [Priest Configuration](https://github.com/Romain-P/Ewt-Scripts/blob/master/priest_disc.lua#L8) for more details and customisation

* `Totem tracker`: checks for destroy totems with Shoot/Weapon (depending the range) in order: `Tremor, Cleansing, Earthbind and then others`
```lua
    -- Make this macro and press it to kill a totem
    /script TrackTotems()
```
* `Healing Rotation`: performs an healing rotation on the unit you want e.g `player`, `party1`, `party1pet`
```lua
    -- Make this macro and press it to heal the unit, yourself in this example
    /script Heal(player)
```
* `Stealth Spot`: Analyses the world map objects and spot all stealth players with the defined spellId (class depending)
* `Auto Instant Controls Break`: Breaks any instant control from any object of the world map
* `Auto Friendly Dispel`: Dispels your party members when they got specific auras
* `Auto Mass Dispel`: Automatically cast `Mass Dispel` on players with the defined aura list. This feature has to be reviewed to calculate a new position when the paladin isnt in direct `LoS` or `15 yards away` (15 yards of radius)