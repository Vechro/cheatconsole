local function ShowNotification(text) -- display a notification above the radar
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
    print(text) -- also print in the console for recordkeeping
end

Citizen.CreateThread(function()

    local function KeyboardInput(textentry, exampletext, maxstringlength)

        -- textentry        -->  the text above the typing field in the black square (str)
        -- exampletext      -->  an example text, what it should say in the typing field (str)
        -- maxstringlength  -->  maximum string length (int)

        AddTextEntry('FMMC_KEY_TIP1', textentry)
        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", exampletext, "", "", "", maxstringlength)
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
    
    local function UpgradeVehicle(vehicle)
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

    local statTable = {"MP0_STAMINA", "MP0_STRENGTH", "MP0_LUNG_CAPACITY", "MP0_WHEELIE_ABILITY", "MP0_FLYING_ABILITY", "MP0_SHOOTING_ABILITY", "MP0_STEALTH_ABILITY",}

    local gadgets = {parachute = true, nightvision = true, gadget_parachute = true, gadget_nightvision = true}

    local splitTable = {}
    while true do
        Wait(0)
        if IsControlPressed(1, 21) and IsControlPressed(1, 38) and IsControlPressed(1, 249) then -- shift + e + n

            local command = KeyboardInput("Enter command", "", 32)

            if command then
                for word in command:gmatch("[^%s]+") do -- magic
                    table.insert(splitTable, word)
                end

                local playerPed = PlayerPedId()

                if tonumber(splitTable[1]) and tonumber(splitTable[2]) and tonumber(splitTable[3]) then
                    if IsPedInAnyVehicle(playerPed, false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed) then
                        entity = GetVehiclePedIsIn(playerPed, false)
                    else
                        entity = playerPed
                    end
                    SetEntityCoords(entity, tonumber(splitTable[1]) + 0.0, tonumber(splitTable[2]) + 0.0, tonumber(splitTable[3]) + 0.0, true, false, false, true)
                    ShowNotification("Teleported to X: " .. splitTable[1] .. " Y: " .. splitTable[2] .. " Z: " .. splitTable[3])

                elseif splitTable[1] == "upgrade" then
                    if IsPedInAnyVehicle(playerPed, false) then
                        local model = GetVehiclePedIsIn(playerPed, false)
                        UpgradeVehicle(model)
                        ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(model))) .. " upgraded")
                    else
                        ShowNotification("You're not in a vehicle")
                    end

                elseif splitTable[1] == "suicide" then
                    SetEntityHealth(playerPed, 0)

                elseif splitTable[1] == "max" and splitTable[2] == "stats" then
                    for index, stat in ipairs(statTable) do
                        StatSetInt(GetHashKey(stat), 100, true)
                    end
                    ShowNotification("All stats maxed out")

                elseif splitTable[1] == "check" and splitTable[2] == "stats" then
                    for index, stat in ipairs(statTable) do
                        local _, statValue = StatGetInt(GetHashKey(stat), -1, -1)
                        print(stat .. ": " .. statValue)
                    end
                
                -- elseif splitTable[1] == "fix" or splitTable[2] == "repair" then


                elseif splitTable[1] == "remove" and splitTable[2] == "all" and splitTable[3] == "weapons" then
                    RemoveAllPedWeapons(playerPed, true)
                    ShowNotification("All weapons removed")

                elseif splitTable[1] == "waypoint" then -- 60% of the time, it works every time
                    local WaypointHandle = GetFirstBlipInfoId(8)
                    if DoesBlipExist(WaypointHandle) then
                        wpcoord = Citizen.InvokeNative(0xFA7C7F0AADF25D09, WaypointHandle, Citizen.ResultAsVector())
                        waypoint = true
                    else
                        ShowNotification("No waypoint marked")
                    end

                elseif splitTable[1] == "get" and splitTable[2] == "coords" then
                    local coord = GetEntityCoords(playerPed)
                    ShowNotification(("You're at X: %.4f; Y: %.4f; Z: %.4f"):format(coord.x, coord.y, coord.z))

                else
                    if IsModelValid(GetHashKey(splitTable[1])) then
                        local model = GetHashKey(splitTable[1])
                        local x, y, z = table.unpack(GetEntityCoords(playerPed, true)) -- to be replaced with just accessing a table
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(0)
                        end
                        if IsPedInAnyVehicle(playerPed, false) then
                            local vehicle = GetVehiclePedIsIn(playerPed, false)
                            SetEntityAsMissionEntity(vehicle, true, true)
                            DeleteEntity(vehicle)
                        end
                        local vehicle = CreateVehicle(model, x, y, z, GetEntityHeading(playerPed), true, true)
                        SetPedIntoVehicle(playerPed, vehicle, -1)
                        UpgradeVehicle(vehicle)
                        SetEntityAsNoLongerNeeded(vehicle)
                        ShowNotification(GetLabelText(GetDisplayNameFromVehicleModel(model)) .. " spawned")

                    elseif splitTable[1] and (IsWeaponValid(GetHashKey(splitTable[1])) or IsWeaponValid(GetHashKey("weapon_" .. splitTable[1])) or IsWeaponValid(GetHashKey("gadget_" .. splitTable[1]))) then
                        -- if splitTable[1] == "parachute" or splitTable[1] == "nightvision" or splitTable[1] == "gadget_parachute" or splitTable[1] == "gadget_nightvision" then
                        if gadgets[splitTable[1]] then
                            if IsWeaponValid(GetHashKey(splitTable[1])) then
                                GiveWeaponToPed(playerPed, splitTable[1], 1, false, false)
                                ShowNotification(splitTable[1] .. " given")
                            else
                                GiveWeaponToPed(playerPed, "gadget_" .. splitTable[1], 1, false, false)
                                ShowNotification("gadget_" .. splitTable[1] .. " given")
                            end
                        else
                            if IsWeaponValid(GetHashKey(splitTable[1])) then
                                GiveWeaponToPed(playerPed, splitTable[1], tonumber(splitTable[2]) or 9999, false, false)
                                if splitTable[2] and tonumber(splitTable[2]) < 0 then
                                    ShowNotification(splitTable[1] .. " given with infinite ammo")
                                else
                                    ShowNotification((tonumber(splitTable[2]) and "" .. splitTable[1] .. " given with " .. splitTable[2] .. " ammo") or splitTable[1] .. " given")
                                end
                            else
                                GiveWeaponToPed(playerPed, "weapon_" .. splitTable[1], tonumber(splitTable[2]) or 9999, false, false)
                                if splitTable[2] and tonumber(splitTable[2]) < 0 then
                                    ShowNotification("weapon_" .. splitTable[1] .. " given with infinite ammo")
                                else
                                    ShowNotification((tonumber(splitTable[2]) and "weapon_" .. splitTable[1] .. " given with " .. splitTable[2] .. " ammo") or "weapon_" .. splitTable[1] .. " given")
                                end
                            end
                        end

                    else
                        if not splitTable[1] then
                        else
                            ShowNotification("Failed to interpret command")
                        end
                    end
                end
                splitTable = {}
            end
        end
    end
end)

Citizen.CreateThread(function() -- teleport to waypoint
    local zTestHeight = 0.0
    local height = 1000.0
    local playerPed = PlayerPedId()
	while true do
	Citizen.Wait(5)
        if waypoint then
            if IsPedInAnyVehicle(playerPed, false) and (GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed) then
                entity = GetVehiclePedIsIn(playerPed, false)
            else
                entity = playerPed
            end

            while not RequestCollisionAtCoord(wpcoord.x + 0.0, wpcoord.y + 0.0, height) do 
                Citizen.Wait(5)
            end
            print("stage 1")
            if zTestHeight == 0.0 then
                height = height - 30.0
                while not RequestCollisionAtCoord(wpcoord.x + 0.0, wpcoord.y + 0.0, height) do 
                    Citizen.Wait(5)
                end
                result, zTestHeight = GetGroundZFor_3dCoord(wpcoord.x + 0.0, wpcoord.y + 0.0, height + 0.0, Citizen.ReturnResultAnyway())
                print("stage 2")
            else
                SetEntityCoords(entity, wpcoord.x + 0.0, wpcoord.y + 0.0, zTestHeight)
                waypoint = false
                ShowNotification(("Teleported to X: %.4f; Y: %.4f; Z: %.4f"):format(wpcoord.x, wpcoord.y, zTestHeight))
                zTestHeight = 0.0
                height = 1000.0
            end
        end
    end
end)
