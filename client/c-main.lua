local VORPcore = exports.vorp_core:GetCore()
local FeatherMenu = exports['feather-menu'].initiate()
local progressbar = exports["feather-progressbar"]:initiate()
local Animations = exports.vorp_animations.initiate()
local cleaningBarrelObject = nil
local hideFrameObject = nil
local blips = {}
local disableinv = false

-----------------------------------------------------------
-- Prompts
-----------------------------------------------------------

local tanningPrompt = nil
local dryingPrompt = nil
local cleaningPrompt = nil
local promptGroupTanning = GetRandomIntInRange(0, 0xffffff)
local promptGroupCleaning = GetRandomIntInRange(0, 0xffffff)

function SetupPrompts()
    -- Tanning Prompt
    tanningPrompt = PromptRegisterBegin()
    PromptSetControlAction(tanningPrompt, Config.keys.E)
    PromptSetText(tanningPrompt, CreateVarString(10, 'LITERAL_STRING', _U('tanningPrompt')))
    PromptSetEnabled(tanningPrompt, false)
    PromptSetVisible(tanningPrompt, false)
    PromptSetHoldMode(tanningPrompt, true)
    PromptSetGroup(tanningPrompt, promptGroupTanning)
    PromptRegisterEnd(tanningPrompt)

    -- Drying Prompt
    dryingPrompt = PromptRegisterBegin()
    PromptSetControlAction(dryingPrompt, Config.keys.R)
    PromptSetText(dryingPrompt, CreateVarString(10, 'LITERAL_STRING', _U('dryingPrompt')))
    PromptSetEnabled(dryingPrompt, false)
    PromptSetVisible(dryingPrompt, false)
    PromptSetHoldMode(dryingPrompt, true)
    PromptSetGroup(dryingPrompt, promptGroupTanning)
    PromptRegisterEnd(dryingPrompt)

    -- Cleaning Prompt
    cleaningPrompt = PromptRegisterBegin()
    PromptSetControlAction(cleaningPrompt, Config.keys.E)
    PromptSetText(cleaningPrompt, CreateVarString(10, 'LITERAL_STRING', _U('cleaningPrompt')))
    PromptSetEnabled(cleaningPrompt, false)
    PromptSetVisible(cleaningPrompt, false)
    PromptSetHoldMode(cleaningPrompt, true)
    PromptSetGroup(cleaningPrompt, promptGroupCleaning)
    PromptRegisterEnd(cleaningPrompt)
end

function CreateBlips()
    for blipName, blipData in pairs(Config.blips) do
        if blipData.enabled then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, blipData.coords.x, blipData.coords.y, blipData.coords.z)

            if blip then
                SetBlipSprite(blip, blipData.sprite, 1)
                SetBlipScale(blip, blipData.scale or 1.0)
                Citizen.InvokeNative(0x03D7FB09E75D6B7E, blip, blipData.color or 1)
                Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey(blipData.name))

                blips[blipName] = blip
            end
        end
    end
end

function cleanupExistingProps()
    local hideFrameHash = GetHashKey(Config.FixedHideProps[1])
    local hideFrameWaterHash = GetHashKey(Config.FixedHideProps2[1])  -- Add this line
    local existingHideFrames = GetGamePool('CObject')
    
    for _, obj in ipairs(existingHideFrames) do
        if GetEntityModel(obj) == hideFrameHash or GetEntityModel(obj) == hideFrameWaterHash then  -- Updated condition
            DeleteObject(obj)
            while DoesEntityExist(obj) do
                Citizen.Wait(1)
                DeleteObject(obj)
            end
        end
    end

    local cleaningBarrelHash = GetHashKey(Config.FixedCleaningBarrelProps[1])
    for _, obj in ipairs(existingHideFrames) do
        if GetEntityModel(obj) == cleaningBarrelHash then
            DeleteObject(obj)
            while DoesEntityExist(obj) do
                Citizen.Wait(1)
                DeleteObject(obj)
            end
        end
    end
end


-----------------------------------------------------------
-- Spawn Props at Configured Locations
-----------------------------------------------------------

Citizen.CreateThread(function()
    cleanupExistingProps()

    SetupPrompts()
    CreateBlips()

    local hideFrameHash = GetHashKey(Config.FixedHideProps[1])
    if not HasModelLoaded(hideFrameHash) then
        RequestModel(hideFrameHash)
        while not HasModelLoaded(hideFrameHash) do
            Citizen.Wait(10)
        end
    end

    for _, coords in ipairs(Config.hideframecoords) do
        Citizen.Wait(0)
        local hideFrame = CreateObject(hideFrameHash, coords.x, coords.y, coords.z, true, true, true)
        SetEntityHeading(hideFrame, coords.h)
        PlaceObjectOnGroundProperly(hideFrame)
        hideFrameObject = hideFrame
    end

    -- Spawn Cleaning Barrel
    local cleaningBarrelHash = GetHashKey(Config.FixedCleaningBarrelProps[1])
    if not HasModelLoaded(cleaningBarrelHash) then
        RequestModel(cleaningBarrelHash)
        while not HasModelLoaded(cleaningBarrelHash) do
            Citizen.Wait(10)
        end
    end

    for _, coords in ipairs(Config.cleaningbarrelcoords) do
        Citizen.Wait(0)
        local cleaningBarrel = CreateObject(cleaningBarrelHash, coords.x, coords.y, coords.z, true, true, true)
        SetEntityHeading(cleaningBarrel, coords.h)
        PlaceObjectOnGroundProperly(cleaningBarrel)
        cleaningBarrelObject = cleaningBarrel
    end

    local hideFrameWaterHash = GetHashKey(Config.FixedHideProps2[1])
    if not HasModelLoaded(hideFrameWaterHash) then
        RequestModel(hideFrameWaterHash)
        while not HasModelLoaded(hideFrameWaterHash) do
            Citizen.Wait(10)
        end
    end

    for _, coords in ipairs(Config.hideframewatercoords) do
        Citizen.Wait(0)
        local hideFrameWater = CreateObject(hideFrameWaterHash, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(hideFrameWater, coords.h)
        PlaceObjectOnGroundProperly(hideFrameWater)
    end
end)

-----------------------------------------------------------
-- Combined Proximity Logic
-----------------------------------------------------------

local isNearHideFrame = false
local wasNearHideFrame = false
local isNearCleaningBarrel = false
local wasNearCleaningBarrel = false

local proximityThreshold = 2.0

Citizen.CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Reset proximity flags
        isNearHideFrame = false
        isNearCleaningBarrel = false

        -- Check proximity to Hide Frame
        for _, coords in ipairs(Config.hideframecoords) do
            local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            if distance <= proximityThreshold then
                isNearHideFrame = true
                break
            end
        end

        -- Check proximity to Cleaning Barrel
        for _, coords in ipairs(Config.cleaningbarrelcoords) do
            local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            if distance <= proximityThreshold then
                isNearCleaningBarrel = true
                break
            end
        end

        -- Handle Hide Frame Prompts
        if isNearHideFrame then
            if not wasNearHideFrame then
                TriggerServerEvent('checkInventoryForPrompts')
                SetPickupLight(hideFrameObject, true)
            end

            local label = CreateVarString(10, 'LITERAL_STRING', "Pelts Rack Actions")
            PromptSetActiveGroupThisFrame(promptGroupTanning, label)

            -- Check if the player has completed holding the tanning or drying prompt
            if PromptHasHoldModeCompleted(tanningPrompt) then
                openTanningMenu()
                Citizen.Wait(100)
                PromptSetEnabled(tanningPrompt, false)
                Citizen.Wait(50)  -- Short delay to ensure prompt resets properly
                PromptSetEnabled(tanningPrompt, true)
            elseif PromptHasHoldModeCompleted(dryingPrompt) then
                openDryingMenu()
                Citizen.Wait(100)
                PromptSetEnabled(dryingPrompt, false)
                Citizen.Wait(50)  -- Short delay to ensure prompt resets properly
                PromptSetEnabled(dryingPrompt, true)
            end
        else
            if wasNearHideFrame then
                SetPickupLight(hideFrameObject, false)
                PromptSetEnabled(tanningPrompt, false)
                PromptSetEnabled(dryingPrompt, false)
            end
        end

        -- Handle Cleaning Barrel Prompts
        if isNearCleaningBarrel then
            if not wasNearCleaningBarrel then
                TriggerServerEvent('checkInventoryForPrompts')
                SetPickupLight(cleaningBarrelObject, true)
            end

            local label = CreateVarString(10, 'LITERAL_STRING', "Cleaning Barrel Actions")
            PromptSetActiveGroupThisFrame(promptGroupCleaning, label)

            -- Check if the player has completed holding the cleaning prompt
            if PromptHasHoldModeCompleted(cleaningPrompt) then
                openCleaningMenu()
                Citizen.Wait(100)
                PromptSetEnabled(cleaningPrompt, false)
                Citizen.Wait(50)  -- Short delay to ensure prompt resets properly
                PromptSetEnabled(cleaningPrompt, true)
            end
        else
            if wasNearCleaningBarrel then
                SetPickupLight(cleaningBarrelObject, false)
                PromptSetEnabled(cleaningPrompt, false)
            end
        end

        -- Update flags
        wasNearHideFrame = isNearHideFrame
        wasNearCleaningBarrel = isNearCleaningBarrel

        Citizen.Wait(5)
    end
end)


-----------------------------------------------------------
-- Prompt Event Handlers
-----------------------------------------------------------

RegisterNetEvent('updatePrompts')
AddEventHandler('updatePrompts', function(hasTanningItems, hasDryingItems, hasCleaningItems)
    -- Tanning and Drying Prompts
    if isNearHideFrame then
        PromptSetVisible(tanningPrompt, true)
        PromptSetVisible(dryingPrompt, true)
        PromptSetEnabled(tanningPrompt, hasTanningItems)
        PromptSetEnabled(dryingPrompt, hasDryingItems)
    else
        PromptSetVisible(tanningPrompt, false)
        PromptSetVisible(dryingPrompt, false)
        PromptSetEnabled(tanningPrompt, false)
        PromptSetEnabled(dryingPrompt, false)
    end

    -- Cleaning Prompt
    if isNearCleaningBarrel then
        PromptSetVisible(cleaningPrompt, true)
        PromptSetEnabled(cleaningPrompt, hasCleaningItems)
    else
        PromptSetVisible(cleaningPrompt, false)
        PromptSetEnabled(cleaningPrompt, false)
    end
end)

-----------------------------------------------------------
-- Disable Inventory
-----------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if disableinv then
            DisableControlAction(0, 0x4CC0E2FE, true)  -- OUR INVENTORY B
        end
    end
end)

local function disableInventory()
    TriggerEvent("vorp_inventory:CloseInv")
    disableinv = true
end

local function enableInventory()
    disableinv = false
end

-----------------------------------------------------------
-- Main Client Event Handlers
-----------------------------------------------------------

RegisterNetEvent('pelt:canProcessResponse')
AddEventHandler('pelt:canProcessResponse', function(processType, canProcess, peltType, missingItems, notEnoughSpace)
    if canProcess then
        print("Triggering pelt:startProcess with quantity:", quantity)
        TriggerEvent('pelt:startProcess', processType, peltType, quantity)
    else
        if notEnoughSpace then
            VORPcore.NotifyLeft("Lack of Space", "Not enough space in inventory", "INVENTORY_ITEMS", "clothing_satchel_006", 5000, "COLOR_PURE_WHITE")
        else
            for _, itemInfo in ipairs(missingItems) do
                local itemName = itemInfo.item
                local requiredQuantity = itemInfo.required
                local playerHas = itemInfo.playerHas
                
                local missingItemMessage = "You need " .. requiredQuantity .. "x " .. itemName .. ", but you only have " .. playerHas .. "."

                VORPcore.NotifyLeft("Missing Item", missingItemMessage, "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 4000, "COLOR_PURE_WHITE")
            end
        end
    end
end)

RegisterNetEvent('pelt:startProcess')
AddEventHandler('pelt:startProcess', function(processType, peltType, quantity)
    if Config.Debug then
        print("Received pelt:startProcess, processType:", processType, "peltType:", peltType, "quantity:", quantity)
    end

    quantity = tonumber(quantity) or 1
    local playerPed = PlayerPedId()
    local processingTime = 20000 * quantity
    local halfwayPoint = processingTime / 2
    local prop = nil

    local function playAnimation(dict, name, flag, duration)
        if Config.Debug then
            print("Loading animation dictionary:", dict)
        end
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(10)
        end
        if Config.Debug then
            print("Playing animation:", name, "from dict:", dict)
        end
        TaskPlayAnim(playerPed, dict, name, 8.0, -8.0, duration, flag, 0, false, false, false)
    end

    local peltConfig = {
        cleaning = {
            anims = {
                enter = {dict = 'amb_work@prop_human_soak_skins@gus@react_look@exit@dismissive', name = 'react_look_front_exit'},
                base = {dict = 'amb_work@prop_human_soak_skins@gus@base', name = 'base'},
                idle = {dict = 'amb_work@prop_human_soak_skins@gus@idle_a', name = 'idle_c'},
                exit = {dict = 'amb_work@prop_human_soak_skins@gus@react_look@enter@low', name = 'react_look_front_enter'}
            },
            prop = 'p_broom03x',
            bone = 'PH_R_Hand',
            position = {x = 0.0, y = 0.0, z = 0.19, rx = 0.0, ry = 0.0, rz = 0.0},
            progressBar = 'Cleaning Pelt...'
        },
        tanning = {
            anims = {
                enter = {dict = 'amb_work@prop_human_tanning_rack_fleshing@male_a@stand_enter', name = 'enter_front_lf'},
                base = {dict = 'amb_work@prop_human_tanning_rack_fleshing@male_a@base', name = 'base'},
                idle = {dict = 'amb_work@prop_human_tanning_rack_fleshing@male_a@idle_c', name = 'idle_h'},
                exit = {dict = 'amb_work@prop_human_tanning_rack_fleshing@male_a@stand_exit', name = 'exit_front'}
            },
            prop = 'w_melee_knife06',
            bone = 'SKEL_R_Hand',
            position = {x = 0.1, y = 0.0, z = -0.02, rx = 100.0, ry = 0.0, rz = 170.0},
            progressBar = 'Tanning Pelt...'
        },
        drying = {
            anims = {
                enter = {dict = 'amb_work@prop_human_tanning_rack_brains@male_a@stand_enter', name = 'enter_front_lf'},
                base = {dict = 'amb_work@prop_human_tanning_rack_brains@male_a@base', name = 'base'},
                idle = {dict = 'amb_work@prop_human_tanning_rack_brains@male_a@idle_c', name = 'idle_g'},
                exit = {dict = 'amb_work@prop_human_tanning_rack_brains@male_a@stand_exit', name = 'stand_exit'}
            },
            prop = false,
            bone = false,
            position = false,
            progressBar = 'Drying Pelt...'
        }
    }

    if peltConfig[processType] then
        local success = exports['mor-lock']:StartLockPickCircle(math.random(2, 4), math.random(10, 15))
        if success then
            local config = peltConfig[processType]

            disableInventory()

            if Config.Debug then
                print("Starting progress bar:", config.progressBar, "for duration:", processingTime)
            end

            progressbar.start(config.progressBar, processingTime, function()
                if Config.Debug then
                    print("Triggering processPelt for peltType:", peltType, "processType:", processType, "quantity:", quantity)
                end
                TriggerServerEvent('pelt:processPelt', processType, peltType, quantity, true)

                if Config.Debug then
                    print("Playing exit animation:", config.anims.exit.name)
                end
                playAnimation(config.anims.exit.dict, config.anims.exit.name, 1, 3500)
                Citizen.Wait(3500)
            
                if Config.Debug then
                    print("Cleaning up after process")
                end
                if prop then
                    DeleteObject(prop)
                    prop = nil
                end
                ClearPedTasksImmediately(PlayerPedId())
                FreezeEntityPosition(playerPed, false)

                enableInventory()

            end, 'linear', 'rgba(255, 255, 255, 1)', '20vw', 'rgba(0, 0, 0, 1)', 'rgba(255, 255, 255, 1)')

            if Config.Debug then
                print("Playing enter animation:", config.anims.enter.name)
            end
            playAnimation(config.anims.enter.dict, config.anims.enter.name, 1, 3000)
            
            if config.prop then
                if Config.Debug then
                    print("Attaching prop:", config.prop, "to bone:", config.bone)
                end
                prop = CreateObject(GetHashKey(config.prop), 0, 0, 0, true, true, true)
                local boneIndex = GetEntityBoneIndexByName(playerPed, config.bone)
                AttachEntityToEntity(prop, playerPed, boneIndex, config.position.x, config.position.y, config.position.z, config.position.rx, config.position.ry, config.position.rz, true, true, false, true, 1, true)
            end

            Citizen.Wait(3000)

            if Config.Debug then
                print("Playing base animation:", config.anims.base.name)
            end
            playAnimation(config.anims.base.dict, config.anims.base.name, 1, -1)

            Citizen.Wait(halfwayPoint)
            if Config.Debug then
                print("Playing idle animation:", config.anims.idle.name)
            end
            playAnimation(config.anims.idle.dict, config.anims.idle.name, 1, 5000)
            Citizen.Wait(5000)

            if Config.Debug then
                print("Resuming base animation:", config.anims.base.name)
            end
            playAnimation(config.anims.base.dict, config.anims.base.name, 1, -1)

        else
            enableInventory()
            VORPcore.NotifyLeft("Processing Failed", 'You failed the processing attempt', "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
            ClearPedTasksImmediately(PlayerPedId())
        end
    else
        enableInventory()
        ClearPedTasksImmediately(playerPed)
        VORPcore.NotifyLeft("Processing Failed", 'Invalid process type.', "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
    end
end)


-------------------------------------------------------
-- Resource Stopping
-------------------------------------------------------

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then 
        local function ensureEntityDeleted(entity)
            if DoesEntityExist(entity) then
                DetachEntity(entity, true, true)
                SetEntityAsMissionEntity(entity, true, true)
                DeleteObject(entity)
                while DoesEntityExist(entity) do
                    Citizen.Wait(1)
                    DeleteObject(entity)
                end
            end
        end

        for _, blip in pairs(blips) do
            if blip then
                RemoveBlip(blip)
            end
        end
        blips = {}

        ensureEntityDeleted(hideFrameObject)
        hideFrameObject = nil

        ensureEntityDeleted(cleaningBarrelObject)
        cleaningBarrelObject = nil

        -- Cleanup for the new object
        ensureEntityDeleted(hideFrameWater)
        hideFrameWater = nil

        local playerPed = PlayerPedId()
        if DoesEntityExist(playerPed) then
            ClearPedTasksImmediately(playerPed)
            FreezeEntityPosition(playerPed, false)
        end

        local broomHash = GetHashKey("p_broom03x")
        local attachedObjects = GetGamePool('CObject')
        for _, obj in ipairs(attachedObjects) do
            if IsEntityAttachedToEntity(obj, playerPed) and GetEntityModel(obj) == broomHash then
                ensureEntityDeleted(obj)
            end
        end

        local stickHash = GetHashKey("w_melee_knife06")
        for _, obj in ipairs(attachedObjects) do
            if IsEntityAttachedToEntity(obj, playerPed) and GetEntityModel(obj) == stickHash then
                ensureEntityDeleted(obj)
            end
        end

        PromptSetEnabled(tanningPrompt, false)
        PromptSetEnabled(dryingPrompt, false)
        PromptSetEnabled(cleaningPrompt, false)
        PromptSetVisible(tanningPrompt, false)
        PromptSetVisible(dryingPrompt, false)
        PromptSetVisible(cleaningPrompt, false)
    end
end)
