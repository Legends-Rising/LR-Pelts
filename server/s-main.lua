local VORPcore = exports.vorp_core:GetCore()

----------------------------------------------------------------
-- Registering usable items
----------------------------------------------------------------

-- Check if the player has the required items to process the pelt
RegisterServerEvent('pelt:checkCanProcess')
AddEventHandler('pelt:checkCanProcess', function(processType, peltType, quantity)
    local _source = source
    local canProcess = true
    local missingItems = {}
    local notEnoughSpace = false
    local peltData

    if processType == "cleaning" then
        peltData = Config.CleanablePelts[peltType]
    elseif processType == "tanning" then
        peltData = Config.TannablePelts[peltType]
    elseif processType == "drying" then
        peltData = Config.DryablePelts[peltType]
    end

    if not peltData then
        TriggerClientEvent('pelt:canProcessResponse', _source, processType, false, peltType, {}, false)
        return
    end

    quantity = tonumber(quantity) or 1

    local resultQuantity = tonumber(peltData.result.quantity) or 0
    local processQuantity = tonumber(quantity) or 1

    if resultQuantity == 0 then
        VORPcore.NotifyLeft(_source, "Processing Aborted", "Processing aborted due to invalid pelt data.", "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
        return
    end

    if processQuantity == 0 then
        VORPcore.NotifyLeft(_source, "Processing Aborted", "Processing aborted due to invalid quantity.", "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
        return
    end

    local totalQuantity = resultQuantity * processQuantity

    if not checkInventorySpace(_source, peltData.result.name, totalQuantity) then
        notEnoughSpace = true
        canProcess = false
    else
        for _, req in ipairs(peltData.requirements) do
            local requiredQuantity = req.quantity * processQuantity
            local playerItemCount = exports.vorp_inventory:getItemCount(_source, nil, req.item, {})
            if playerItemCount < requiredQuantity then
                canProcess = false
                table.insert(missingItems, { item = req.item, required = requiredQuantity, playerHas = playerItemCount })
            end
        end
    end

    TriggerClientEvent('pelt:canProcessResponse', _source, processType, canProcess, peltType, missingItems, notEnoughSpace)
end)


-- Process the pelt
RegisterNetEvent('pelt:processPelt')
AddEventHandler('pelt:processPelt', function(processType, peltType, quantity, success)
    local _source = source
    local peltData

    if processType == "cleaning" then
        peltData = Config.CleanablePelts[peltType]
    elseif processType == "tanning" then
        peltData = Config.TannablePelts[peltType]
    elseif processType == "drying" then
        peltData = Config.DryablePelts[peltType]
    else
        VORPcore.NotifyLeft(_source, "Invalid Process", "Invalid process type. Processing aborted.", "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
        return
    end

    if not peltData then
        VORPcore.NotifyLeft(_source, "Invalid Pelt Type", "Invalid pelt type. Processing aborted.", "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
        return
    end

    local resultQuantity = tonumber(peltData.result.quantity) or 1
    local processQuantity = tonumber(quantity) or 1
    local totalQuantity = resultQuantity * processQuantity

    if success then
        local canCarry = exports.vorp_inventory:canCarryItem(_source, peltData.result.name, totalQuantity)
        if canCarry then
            for _, req in ipairs(peltData.requirements) do
                local requiredQuantity = req.quantity * processQuantity
                exports.vorp_inventory:subItem(_source, req.item, requiredQuantity)
            end

            -- Add the processed items to the player's inventory
            exports.vorp_inventory:addItem(_source, peltData.result.name, totalQuantity)
            local title = "Successfully Processed"
            local subtitle = totalQuantity .. "x " .. peltData.label .. "!"
            VORPcore.NotifyLeft(_source, title, subtitle, "satchel_textures", "provision_boar_skin", 5000, "COLOR_PURE_WHITE")
        else
            VORPcore.NotifyLeft(_source, "Lack of Space", "Not enough space in inventory", "INVENTORY_ITEMS", "clothing_satchel_006", 5000, "COLOR_PURE_WHITE")
        end
    else
        -- Return items if processing fails
        for _, req in ipairs(peltData.requirements) do
            local requiredQuantity = req.quantity * processQuantity
            exports.vorp_inventory:addItem(_source, req.item, requiredQuantity)
        end
        VORPcore.NotifyLeft(_source, "Processing Failed", "Processing failed. Items returned to inventory.", "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
    end
end)


RegisterNetEvent('pelt:returnItemsOnFailure')
AddEventHandler('pelt:returnItemsOnFailure', function(processType, peltType, quantity)
    local _source = source
    local peltData

    if processType == "cleaning" then
        peltData = Config.CleanablePelts[peltType]
    elseif processType == "tanning" then
        peltData = Config.TannablePelts[peltType]
    elseif processType == "drying" then
        peltData = Config.DryablePelts[peltType]
    end

    if not peltData then
        VORPcore.NotifyLeft(_source, "Invalid Pelt Type", "Invalid pelt type. Items not returned.", "INVENTORY_ITEMS", "upgrade_fsh_bait_lure_none", 5000, "COLOR_PURE_WHITE")
        return
    end

    for _, req in ipairs(peltData.requirements) do
        local requiredQuantity = req.quantity * quantity
        exports.vorp_inventory:addItem(_source, req.item, requiredQuantity)
    end


    VORPcore.NotifyLeft(_source, "Dont you worry!", "Items returned to your inventory.", "INVENTORY_ITEMS", "clothing_satchel_006", 5000, "COLOR_PURE_WHITE")
end)


--------------------------------------------------------------------------------
-- Checking inventory for crafting prompts and Inventory space
--------------------------------------------------------------------------------

RegisterServerEvent('checkInventoryForPrompts')
AddEventHandler('checkInventoryForPrompts', function()
    local _source = source
    local hasTanningItems = false
    local hasDryingItems = false
    local hasCleaningItems = false

    -- Check for Tanning Items
    local tanningItemCount = exports.vorp_inventory:getItemCount(_source, nil, 'clean_pelt', {})
    if tanningItemCount > 0 then
        hasTanningItems = true
    end

    -- Check for Drying Items
    local dryingItemCount = exports.vorp_inventory:getItemCount(_source, nil, 'tanned_leather', {})
    if dryingItemCount > 0 then
        hasDryingItems = true
    end

    -- Check for Cleaning Items
    for peltKey, peltValue in pairs(Config.CleanablePelts) do
        local peltItem = peltValue.requirements[1].item
        local itemCount = exports.vorp_inventory:getItemCount(_source, nil, peltItem, {})
        
        if itemCount > 0 then
            hasCleaningItems = true
            break
        end
    end

    TriggerClientEvent('updatePrompts', _source, hasTanningItems, hasDryingItems, hasCleaningItems)
end)

function checkInventorySpace(_source, item, quantity)
    return exports.vorp_inventory:canCarryItem(_source, item, quantity)
end
