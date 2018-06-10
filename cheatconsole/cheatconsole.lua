Citizen.CreateThread(function()

    local function keyboardInput(textentry, maxstringlength)
        AddTextEntry('FMMC_KEY_TIP1', textentry)
        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", "", "", "", "", maxstringlength)
        blockInput = true
    
        while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
            Wait(0)
        end
    
        if UpdateOnscreenKeyboard() ~= 2 then
            local result = GetOnscreenKeyboardResult()
            Wait(50)
            blockInput = false
            return result
    
        else
            Wait(50)
            blockInput = false
            return nil
        end
    end

    local function ShowNotification(text) -- display a notification above the radar
        SetNotificationTextEntry("STRING")
        AddTextComponentString(text)
        DrawNotification(false, false)
        print(text)
    end

    local function teleportOnGround(ped, x, y) -- teleport to waypoint
        Citizen.CreateThread(function()
            local zTestHeight = 0.0
            local height = 1000.0
            while true do
            Wait(5)

                if IsPedInAnyVehicle(ped, false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped) then
                    entity = GetVehiclePedIsIn(ped, false)
                else
                    entity = ped
                end

                while not RequestCollisionAtCoord(x + 0.0, y + 0.0, height) do 
                    Wait(5)
                end

                if zTestHeight == 0.0 then
                    height = height - 40.0
                    while not RequestCollisionAtCoord(x + 0.0, y + 0.0, height) do 
                        Wait(5)
                    end
                    result, zTestHeight = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, height + 0.0, Citizen.ReturnResultAnyway())
                else
                    SetEntityCoords(entity, x + 0.0, y + 0.0, zTestHeight)
                    ShowNotification(("Teleported to X: %.4f; Y: %.4f; Z: %.4f"):format(x, y, zTestHeight))
                    return
                end
            end
        end)
    end
    
    local function upgradeVehicle(vehicle)
        local class = GetVehicleClass(vehicle)
        SetVehicleModKit(vehicle, 0) -- enable vehicle modding
        SetVehicleMod(vehicle, 11, 4) -- engine
        SetVehicleMod(vehicle, 12, 4) -- brakes
        SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1) -- transmission
        SetVehicleMod(vehicle, 16, 4) -- armor
        ToggleVehicleMod(vehicle, 18, true) -- turbo
        SetVehicleTyresCanBurst(vehicle, false) -- bulletproof tires
        if class ~= 9 and class ~= 10 and class ~= 19 then
            SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1) -- suspension
        end
    end

    local function validateComponents(weapon, componentTable) -- expects first value in table to be a weapon and last to be ammo count (but should manage fine without ammo count), should make it so "component_" can be omitted
        if IsWeaponValid(GetHashKey(componentTable[1])) or IsWeaponValid(GetHashKey(componentTable[1])) then
            table.remove(componentTable, 1)
        end
        if type(tonumber(componentTable[#componentTable])) == "number" then
            table.remove(componentTable)
        end
        local correctComponents = {}
        for _, component in ipairs(componentTable) do
            if DoesWeaponTakeWeaponComponent(weapon, GetHashKey(component)) then
                table.insert(correctComponents, GetHashKey(component))
            end
        end
        return correctComponents
    end

    local function giveComponents(ped, weaponHash, componentTable)
        for _, component in ipairs(componentTable) do
            GiveWeaponComponentToPed(ped, weaponHash, component)
        end
    end

    local statTable = {"MP0_STAMINA", "MP0_STRENGTH", "MP0_LUNG_CAPACITY", "MP0_WHEELIE_ABILITY", "MP0_FLYING_ABILITY", "MP0_SHOOTING_ABILITY", "MP0_STEALTH_ABILITY",}

    local splitTable = {}
    while true do
        Wait(0)
        if IsControlPressed(1, 21) and IsControlPressed(1, 38) and IsControlPressed(1, 249) then -- shift + e + n

            local command = keyboardInput("Enter command", 800) -- should check the limits of the text box

            if command then
                string.lower(command)
                for word in command:gmatch("[^%s]+") do -- magic
                    table.insert(splitTable, word)
                end

                local first, second, third = table.unpack(splitTable)
                -- print("Table entries: " .. tostring(first) .. " & " .. tostring(second) .. " & " .. tostring(third))
                local playerPed = PlayerPedId()
                local playerID = PlayerId()

                if tonumber(first) and tonumber(second) and tonumber(third) then
                    if IsPedInAnyVehicle(playerPed, false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed) then
                        entity = GetVehiclePedIsIn(playerPed, false)
                    else
                        entity = playerPed
                    end
                    SetEntityCoords(entity, tonumber(first) + 0.0, tonumber(second) + 0.0, tonumber(third) + 0.0, true, false, false, true)
                    ShowNotification("Teleported to X: " .. first .. "; Y: " .. second .. "; Z: " .. third)

                elseif first == "invincible" then
                    if not GetPlayerInvincible(playerID) then
                        SetEntityInvincible(playerPed, true)
                        SetPlayerInvincible(playerID, true)
                        SetPedCanRagdoll(playerPed, false)
                        ClearPedBloodDamage(playerPed)
                        ResetPedVisibleDamage(playerPed)
                        SetEntityProofs(playerPed, true, true, true, true, true, true, true, true)
                        SetEntityCanBeDamaged(playerPed, false)
                        ShowNotification("You're now invincible")
                    else
                        SetEntityInvincible(playerPed, false)
                        SetPlayerInvincible(playerID, false)
                        SetPedCanRagdoll(playerPed, true)
                        SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
                        SetEntityCanBeDamaged(playerPed, true)
                        ShowNotification("You're no longer invincible")
                    end
--[[
                elseif first == "indestructible" then
                    if 
                    SetVehicleCanBeVisiblyDamaged(vehicle, true)
                    SetVehicleTyresCanBurst(vehicle, true)
                    SetEntityInvincible(vehicle, false)
                    SetEntityProofs(vehicle, false, false, false, false, false, false, false, false)
                    SetVehicleWheelsCanBreak(vehicle, true)
                    SetVehicleExplodesOnHighExplosionDamage(vehicle, true)
                    SetEntityOnlyDamagedByPlayer(vehicle, true)
                    SetEntityCanBeDamaged(vehicle, true)
                    -- SetVehicleStrong(vehicle, true)
                    -- SetVehiclePetrolTankHealth(vehicle, 1000.0)
                    -- SetVehicleHasStrongAxles(vehicle, true)
]]
                elseif first == "heal" then
                    SetEntityHealth(playerPed, 200)
                    ClearPedBloodDamage(playerPed)
                    ResetPedVisibleDamage(playerPed)
                    ShowNotification("You've been healed")
                
                elseif first == "armor" then
                    AddArmourToPed(playerPed, 100)
                    ShowNotification("You've been given armor")

                elseif first == "timecycle" then
                    if second then
                        SetTimecycleModifier(second)
                        SetTimecycleModifierStrength(0.95)
                        PushTimecycleModifier()
                        ShowNotification("Timecycle set to " .. second)
                    else
                        ClearTimecycleModifier()
                        ShowNotification("Timecycle cleared")
                    end


                elseif tonumber(first) and (tonumber(first) < 6 and tonumber(first) >= 0 and second == "stars") or (tonumber(first) == 1 and second == "star") then -- make it work with "1 star" too
                    SetPlayerWantedLevel(playerID,  tonumber(first), false)
                    SetPlayerWantedLevelNow(playerID, false)
                    ShowNotification("Wanted level set to " .. first .. " star(s)")

                elseif first == "upgrade" then
                    if IsPedInAnyVehicle(playerPed, false) then
                        local model = GetVehiclePedIsIn(playerPed, false)
                        upgradeVehicle(model)
                        ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(model))) .. " upgraded")
                        ShowNotification(GetDisplayNameFromVehicleModel(GetEntityModel(model)) .. " upgraded")
                    else
                        ShowNotification("You're not in a vehicle")
                    end

                elseif first == "suicide" then
                    SetEntityHealth(playerPed, 0)

                elseif first == "max" and second == "stats" then
                    for index, stat in ipairs(statTable) do
                        StatSetInt(GetHashKey(stat), 100, true)
                    end
                    SetEntityMaxHealth(playerPed, 200)
                    ShowNotification("All stats maxed out")

                elseif first == "stats" then -- totally unnecessary
                    for index, stat in ipairs(statTable) do
                        local _, statValue = StatGetInt(GetHashKey(stat), -1, -1)
                        print(stat .. ": " .. statValue)
                    end
                
                elseif first == "fix" or first == "repair" then
                    if IsPedInAnyVehicle(playerPed, false) then
                        local vehicle = GetVehiclePedIsIn(playerPed, false)
                        SetVehicleFixed(vehicle)
                        SetVehicleDirtLevel(vehicle, 0.0)
                        ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) .. " cleaned and repaired")
                    else
                        ShowNotification("You're not in a vehicle")
                    end

                elseif first == "remove" and second and ((second == "all" or second == "current") or IsWeaponValid(GetHashKey(second)) or IsWeaponValid(GetHashKey("weapon_" .. second))) then
                    if second == "all" then
                        RemoveAllPedWeapons(playerPed, true)
                        ShowNotification("All weapons removed")

                    elseif second == "current" then
                        local _, currentWeapon = GetCurrentPedWeapon(playerPed)
                        RemoveWeaponFromPed(playerPed, currentWeapon, true)
                        ShowNotification("Current weapon removed")

                    elseif IsWeaponValid(GetHashKey(second)) then
                        RemoveWeaponFromPed(playerPed, GetHashKey(second))
                        ShowNotification(second .. " removed")

                    elseif IsWeaponValid(GetHashKey("weapon_" .. second)) then
                        RemoveWeaponFromPed(playerPed, GetHashKey("weapon_" .. second))
                        ShowNotification("weapon_" .. second .. " removed")
                    end

                elseif first == "flip" then
                    if IsPedInAnyVehicle(playerPed, false) then
                        local vehicle = GetVehiclePedIsIn(playerPed, false)
                        local flipped = SetVehicleOnGroundProperly(vehicle)
                        if flipped then
                            ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) .. " flipped")
                        else
                            ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))) .. " failed to be flipped")
                        end
                    else
                        ShowNotification("You're not in a vehicle")
                    end

                elseif first == "waypoint" then
                    local WaypointHandle = GetFirstBlipInfoId(8)
                    if DoesBlipExist(WaypointHandle) then
                        wpcoord = Citizen.InvokeNative(0xFA7C7F0AADF25D09, WaypointHandle, Citizen.ResultAsVector())
                        teleportOnGround(playerPed, wpcoord.x, wpcoord.y)
                    else
                        ShowNotification("No waypoint marked")
                    end

                elseif first == "get" and (second == "coord" or second == "coords") then
                    local coord = GetEntityCoords(playerPed)
                    ShowNotification(("You're at X: %.4f; Y: %.4f; Z: %.4f"):format(coord.x, coord.y, coord.z))

                else
                    -- local _, currentWeapon = GetCurrentPedWeapon(playerPed)
                    if IsModelValid(GetHashKey(first)) then
                        local model = GetHashKey(first)
                        local coord = GetEntityCoords(playerPed, true)
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        if IsPedInAnyVehicle(playerPed, false) then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)
                            SetEntityAsMissionEntity(vehicle, true, true)
                            DeleteEntity(vehicle)
                        end
                        local vehicle = CreateVehicle(model, coord.x, coord.y, coord.z, GetEntityHeading(playerPed), true, true)
                        SetPedIntoVehicle(playerPed, vehicle, -1)
                        upgradeVehicle(vehicle)
                        SetEntityAsNoLongerNeeded(vehicle)
                        ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(model)) .. " spawned")

                    -- elseif DoesWeaponTakeWeaponComponent(currentWeapon, GetHashKey(first)) then
                    elseif DoesWeaponTakeWeaponComponent(({GetCurrentPedWeapon(playerPed)})[2], GetHashKey(first)) then -- untested, maybe check the whole table
                        print(({GetCurrentPedWeapon(playerPed)})[2])
                        local _, currentWeapon = GetCurrentPedWeapon(playerPed)
                        print(currentWeapon)
                        local ammo = GetAmmoInPedWeapon(playerPed, weapon)
                        print(ammo)
                        local correctComponents = validateComponents(currentWeapon, splitTable)
                        giveComponents(playerPed, currentWeapon, correctComponents)
                        print(GetAmmoInPedWeapon(playerPed, weapon))
                        if ammo ~= GetAmmoInPedWeapon(playerPed, weapon) then
                            AddAmmoToPed(playerPed, currentWeapon, ammo)
                        end
                        ShowNotification("Weapon components attached to current weapon")
                    
                    elseif first and (IsWeaponValid(GetHashKey(first)) or IsWeaponValid(GetHashKey("weapon_" .. first)) or IsWeaponValid(GetHashKey("gadget_" .. first))) then
                        if first == "parachute" or first == "nightvision" or first == "gadget_parachute" or first == "gadget_nightvision" then
                            if IsWeaponValid(GetHashKey(first)) then
                                GiveWeaponToPed(playerPed, first, 1, false, false)
                                ShowNotification(first .. " given")
                            else
                                GiveWeaponToPed(playerPed, "gadget_" .. first, 1, false, false)
                                ShowNotification("gadget_" .. first .. " given")
                            end
                        else
                            local ammo = tonumber(splitTable[#splitTable]) or 9999
                            if ammo then
                                if ammo > 9999 then
                                    ammo = 9999
                                elseif ammo < -1 then
                                    ammo = -1
                                end
                            end
                            if not IsWeaponValid(GetHashKey(first)) then
                                first = "weapon_" .. first
                                weapon = GetHashKey(first)
                            end
                            GiveWeaponToPed(playerPed, weapon, ammo, false, false)
                            local correctComponents = validateComponents(weapon, splitTable)
                            giveComponents(playerPed, weapon, correctComponents)
                            if GetAmmoInPedWeapon(playerPed, weapon) >= 0 and ammo ~= 0 then
                                AddAmmoToPed(playerPed, weapon, ammo)
                            end
                            if ammo == -1 then
                                ShowNotification(first .. " given with infinite ammo")
                            else
                                ShowNotification(first .. " given with " .. ammo .. " ammo")
                            end
                        end

                    else
                        ShowNotification("Failed to interpret command")
                    end
                end
                splitTable = {}
            end
        end
    end
end)