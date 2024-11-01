local VORPcore = exports.vorp_core:GetCore()
local FeatherMenu = exports['feather-menu'].initiate()
local selectedCleaningQuantity = 1
local selectedTanningQuantity = 1
local selectedDryingQuantity = 1

-------------------------------------------------------
-- Pelt Cleaning Process (1) -- Menu
-------------------------------------------------------

function openCleaningMenu()
    isMenuOpen = false
    local CleaningMenu = FeatherMenu:RegisterMenu('cleaning:main:menu', {
        top = '40%',
        left = '20%',
        ['720width'] = '500px',
        ['1080width'] = '600px',
        ['2kwidth'] = '700px',
        ['4kwidth'] = '900px',
        draggable = true,
        contentslot = {
            style = {
                ['height'] = '500px',
                ['min-height'] = '500px'
            }
        }
    }, {
    })

    local MainPage = CleaningMenu:RegisterPage('main:page')
    MainPage:RegisterElement('header', {value = 'Hide Cleaning Menu', slot = "header"})

    MainPage:RegisterElement('subheader', {
        value = "Select A Hide to Clean",
        slot = "header",
        style = {}
    })

    MainPage:RegisterElement('bottomline', {
        slot = "content"
    })

    -- First, create a table to hold the sorted elements
    local sortedPelts = {}

    -- Populate the table with labels as keys and peltType as values
    for peltType, peltInfo in pairs(Config.CleanablePelts) do
        table.insert(sortedPelts, {label = peltInfo.label, peltType = peltType})
    end

    -- Sort the table by label
    table.sort(sortedPelts, function(a, b)
        return a.label:lower() < b.label:lower() -- Sort alphabetically, case-insensitive
    end)

    -- Iterate through the sorted table
    for _, entry in ipairs(sortedPelts) do
        local peltType = entry.peltType
        local peltInfo = Config.CleanablePelts[peltType]

        MainPage:RegisterElement('button', {
            label = peltInfo.label,
            slot = "content"
        }, function()
            openPeltCleaningPage(CleaningMenu, peltType)
        end)
    end

    MainPage:RegisterElement('line', {
        slot = "footer"
    })

    MainPage:RegisterElement('subheader', {
        value = "Information",
        slot = "footer",
        style = {}
    })

    MainPage:RegisterElement('line', {
        slot = "footer"
    })

    MainPage:RegisterElement("html", {
        slot = "footer",
        value = {
            [[
                <img width="100px" height="100px" style="margin: 0 auto;" src="nui://vorp_inventory/html/img/items/prongs.png" />
            ]]
        }
    })


    MainPage:RegisterElement("html", {
        slot = "footer",
        value = {
            [[
                <div style="text-align: justify; margin: 0 auto; max-width: 80%; padding: 10px;">
                    Gather 'round, folks! Should y'all have a particular animal hide in mind, 
                    or need to clean a certain number of 'em, just pick the pelt that catches your fancy 
                    from the list yonder above.
                </div>
            ]]
        }
    })

    CleaningMenu:Open({startupPage = MainPage})
end

function openPeltCleaningPage(CleaningMenu, peltType)
    local peltInfo = Config.CleanablePelts[peltType]
    local PeltCleaningPage = CleaningMenu:RegisterPage('pelt_cleaning_page_' .. peltType)

    PeltCleaningPage:RegisterElement('header', {
        value = "Pelt Cleaning Details",
        slot = "header"
    })

    PeltCleaningPage:RegisterElement('subheader', {
        value = "Cleaning: " .. peltInfo.label,
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('line', {
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('subheader', {
        value = "Required Ingredients",
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('bottomline', {
        slot = "content"
    })

    local htmlValue = "<div style='display: flex; justify-content: space-around;'>"
    for _, ingredient in ipairs(peltInfo.requirements) do
        htmlValue = htmlValue .. "<div style='text-align: center;'>"
        htmlValue = htmlValue .. "<p>" .. ingredient.label .. "</p>"
        htmlValue = htmlValue .. "<img src='" .. ingredient.descImg .. "' style='width: 64px; height: 64px; display: block; margin: auto;'>"
        htmlValue = htmlValue .. "<p>x" .. tostring(ingredient.quantity) .. "</p>"
        htmlValue = htmlValue .. "</div>"
    end
    htmlValue = htmlValue .. "</div>"

    ingredientsHtmlElement = PeltCleaningPage:RegisterElement('html', {
        value = htmlValue,
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('line', {
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('subheader', {
        value = "Results",
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('bottomline', {
        slot = "content"
    })

    local resultHtml = "<div style='text-align: center;'>"
    resultHtml = resultHtml .. "<p>" .. peltInfo.label .. "</p>"
    resultHtml = resultHtml .. "<img src='" .. peltInfo.Imglabel .. "' style='width: 128px; height: 128px; display: block; margin: auto;'>"
    resultHtml = resultHtml .. "<p>x1</p>" -- Default quantity is 1
    resultHtml = resultHtml .. "</div>"

    resultHtmlElement = PeltCleaningPage:RegisterElement('html', {
        value = resultHtml,
        slot = "content"
    })

    PeltCleaningPage:RegisterElement('slider', {
        label = "Adjust Quantity",
        start = 1,
        min = 1,
        max = 10,
        steps = 1,
        slot = "footer"
    }, function(data)
        quantity = tonumber(data.value)
        updatePeltCleaningDetails(quantity, peltInfo)
    end)
    
    PeltCleaningPage:RegisterElement('button', {
        label = "Start Cleaning",
        slot = "footer"
    }, function()
        TriggerServerEvent('pelt:checkCanProcess', 'cleaning', peltType, quantity)
        CleaningMenu:Close()
    end)
    

    PeltCleaningPage:RegisterElement('button', {
        label = "Back",
        slot = "footer"
    }, function()
        openCleaningMenu()
    end)

    CleaningMenu:Open({startupPage = PeltCleaningPage})
end

function updatePeltCleaningDetails(quantity, peltInfo)
    local newIngredientsHtml = "<div style='display: flex; justify-content: space-around;'>"
    for _, ingredient in ipairs(peltInfo.requirements) do
        newIngredientsHtml = newIngredientsHtml .. "<div style='text-align: center;'>"
        newIngredientsHtml = newIngredientsHtml .. "<p>" .. ingredient.label .. "</p>"
        newIngredientsHtml = newIngredientsHtml .. "<img src='" .. ingredient.descImg .. "' style='width: 64px; height: 64px; display: block; margin: auto;'>"
        newIngredientsHtml = newIngredientsHtml .. "<p>x" .. tostring(ingredient.quantity * quantity) .. "</p>"
        newIngredientsHtml = newIngredientsHtml .. "</div>"
    end
    newIngredientsHtml = newIngredientsHtml .. "</div>"
    ingredientsHtmlElement:update({ value = newIngredientsHtml })

    local newResultHtml = "<div style='text-align: center;'>"
    newResultHtml = newResultHtml .. "<p>" .. peltInfo.label .. "</p>"
    newResultHtml = newResultHtml .. "<img src='" .. peltInfo.Imglabel .. "' style='width: 128px; height: 128px; display: block; margin: auto;'>"
    newResultHtml = newResultHtml .. "<p>x" .. tostring(quantity) .. "</p>"
    newResultHtml = newResultHtml .. "</div>"

    resultHtmlElement:update({ value = newResultHtml })
end

-------------------------------------------------------
-- Pelt Tanning Process (2) -- Menu
-------------------------------------------------------

function openTanningMenu()

    local TanningMenu = FeatherMenu:RegisterMenu('tanning:main:menu', {
        top = '40%',
        left = '20%',
        ['720width'] = '500px',
        ['1080width'] = '600px',
        ['2kwidth'] = '700px',
        ['4kwidth'] = '900px',
        draggable = true,
        contentslot = {
            style = {
                ['height'] = '500px',
                ['min-height'] = '500px'
            }
        }
    }, {
    })

    local MainPage = TanningMenu:RegisterPage('main:page')
    MainPage:RegisterElement('header', {value = 'Hide Tanning Menu', slot = "header"})

    MainPage:RegisterElement('subheader', {
        value = "Select Hide to Tan",
        slot = "header",
        style = {}
    })

    MainPage:RegisterElement('bottomline', {
        slot = "content"
    })

    -- First, create a table to hold the sorted elements
    local sortedPelts = {}

    -- Populate the table with labels as keys and peltType as values
    for peltType, peltInfo in pairs(Config.TannablePelts) do
        table.insert(sortedPelts, {label = peltInfo.label, peltType = peltType})
    end

    -- Sort the table by label
    table.sort(sortedPelts, function(a, b)
        return a.label:lower() < b.label:lower() -- Sort alphabetically, case-insensitive
    end)

    for peltType, peltInfo in pairs(Config.TannablePelts) do
        MainPage:RegisterElement('button', {
            label = peltInfo.label,
            slot = "content"
        }, function()
            openTanningPage(TanningMenu, peltType)
        end)
    end

    MainPage:RegisterElement('line', {
        slot = "footer"
    })

    MainPage:RegisterElement('subheader', {
        value = "Information",
        slot = "footer",
        style = {}
    })

    MainPage:RegisterElement('line', {
        slot = "footer"
    })

    MainPage:RegisterElement("html", {
        slot = "footer",
        value = {
            [[
                <img width="100px" height="100px" style="margin: 0 auto;" src="nui://vorp_inventory/html/img/items/prongs.png" />
            ]]
        }
    })


    MainPage:RegisterElement("html", {
        slot = "footer",
        value = {
            [[
                <div style="text-align: justify; margin: 0 auto; max-width: 80%; padding: 10px;">
                    Well met, partner! Your hides are cleaned and ready for the next step, I reckon. 
                    If you've got a mind to specify the quantities.
                </div>
            ]]
        }
    })

    TanningMenu:Open({startupPage = MainPage})
end

function openTanningPage(TanningMenu, peltType)
    local peltInfo = Config.TannablePelts[peltType]
    local PeltTanningPage = TanningMenu:RegisterPage('pelt_tanning_page_' .. peltType)

    PeltTanningPage:RegisterElement('header', {
        value = "Hide Tanning Details",
        slot = "header"
    })

    PeltTanningPage:RegisterElement('subheader', {
        value = "Tanning: " .. peltInfo.label,
        slot = "content"
    })

    PeltTanningPage:RegisterElement('line', {
        slot = "content"
    })

    PeltTanningPage:RegisterElement('subheader', {
        value = "Required Ingredients",
        slot = "content"
    })

    PeltTanningPage:RegisterElement('bottomline', {
        slot = "content"
    })

    local htmlValue = "<div style='display: flex; justify-content: space-around;'>"
    for _, ingredient in ipairs(peltInfo.requirements) do
        htmlValue = htmlValue .. "<div style='text-align: center;'>"
        htmlValue = htmlValue .. "<p>" .. ingredient.label .. "</p>"
        htmlValue = htmlValue .. "<img src='" .. ingredient.descImg .. "' style='width: 64px; height: 64px; display: block; margin: auto;'>"
        htmlValue = htmlValue .. "<p>x" .. tostring(ingredient.quantity) .. "</p>"
        htmlValue = htmlValue .. "</div>"
    end
    htmlValue = htmlValue .. "</div>"

    ingredientsHtmlElement = PeltTanningPage:RegisterElement('html', {
        value = htmlValue,
        slot = "content"
    })

    PeltTanningPage:RegisterElement('line', {
        slot = "content"
    })

    PeltTanningPage:RegisterElement('subheader', {
        value = "Results",
        slot = "content"
    })

    PeltTanningPage:RegisterElement('bottomline', {
        slot = "content"
    })

    local resultHtml = "<div style='text-align: center;'>"
    resultHtml = resultHtml .. "<p>" .. peltInfo.label .. "</p>"
    resultHtml = resultHtml .. "<img src='" .. peltInfo.Imglabel .. "' style='width: 128px; height: 128px; display: block; margin: auto;'>"
    resultHtml = resultHtml .. "<p>x1</p>" -- Default quantity is 1
    resultHtml = resultHtml .. "</div>"

    resultHtmlElement = PeltTanningPage:RegisterElement('html', {
        value = resultHtml,
        slot = "content"
    })

    PeltTanningPage:RegisterElement('slider', {
        label = "Adjust Quantity",
        start = 1,
        min = 1,
        max = 10,
        steps = 1,
        slot = "footer"
    }, function(data)
        quantity = tonumber(data.value)
        updatePeltTanningDetails(quantity, peltInfo)
    end)

    PeltTanningPage:RegisterElement('button', {
        label = "Start Tanning",
        slot = "footer"
    }, function()
        TriggerServerEvent('pelt:checkCanProcess', 'tanning', peltType, quantity)
        TanningMenu:Close()
    end)

    PeltTanningPage:RegisterElement('button', {
        label = "Back",
        slot = "footer"
    }, function()
        openTanningMenu()
    end)

    TanningMenu:Open({startupPage = PeltTanningPage})
end

function updatePeltTanningDetails(quantity, peltInfo)
    local newIngredientsHtml = "<div style='display: flex; justify-content: space-around;'>"
    for _, ingredient in ipairs(peltInfo.requirements) do
        newIngredientsHtml = newIngredientsHtml .. "<div style='text-align: center;'>"
        newIngredientsHtml = newIngredientsHtml .. "<p>" .. ingredient.label .. "</p>"
        newIngredientsHtml = newIngredientsHtml .. "<img src='" .. ingredient.descImg .. "' style='width: 64px; height: 64px; display: block; margin: auto;'>"
        newIngredientsHtml = newIngredientsHtml .. "<p>x" .. tostring(ingredient.quantity * quantity) .. "</p>"
        newIngredientsHtml = newIngredientsHtml .. "</div>"
    end
    newIngredientsHtml = newIngredientsHtml .. "</div>"
    ingredientsHtmlElement:update({ value = newIngredientsHtml })

    local newResultHtml = "<div style='text-align: center;'>"
    newResultHtml = newResultHtml .. "<p>" .. peltInfo.label .. "</p>"
    newResultHtml = newResultHtml .. "<img src='" .. peltInfo.Imglabel .. "' style='width: 128px; height: 128px; display: block; margin: auto;'>"
    newResultHtml = newResultHtml .. "<p>x" .. tostring(quantity) .. "</p>"
    newResultHtml = newResultHtml .. "</div>"

    resultHtmlElement:update({ value = newResultHtml })
end

-------------------------------------------------------
-- Pelt Drying Process (3) -- Menu
-------------------------------------------------------

function openDryingMenu()

    local DryingMenu = FeatherMenu:RegisterMenu('drying:main:menu', {
        top = '40%',
        left = '20%',
        ['720width'] = '500px',
        ['1080width'] = '600px',
        ['2kwidth'] = '700px',
        ['4kwidth'] = '900px',
        draggable = true,
        contentslot = {
            style = {
                ['height'] = '500px',
                ['min-height'] = '500px'
            }
        }
    }, {
    })

    local MainPage = DryingMenu:RegisterPage('main:page')
    MainPage:RegisterElement('header', {value = 'Hide Drying Menu', slot = "header"})

    MainPage:RegisterElement('subheader', {
        value = "Select Hide to Dry",
        slot = "header",
        style = {}
    })

    MainPage:RegisterElement('bottomline', {
        slot = "content"
    })

    -- First, create a table to hold the sorted elements
    local sortedPelts = {}

    -- Populate the table with labels as keys and peltType as values
    for peltType, peltInfo in pairs(Config.DryablePelts) do
        table.insert(sortedPelts, {label = peltInfo.label, peltType = peltType})
    end

    -- Sort the table by label
    table.sort(sortedPelts, function(a, b)
        return a.label:lower() < b.label:lower() -- Sort alphabetically, case-insensitive
    end)

    for peltType, peltInfo in pairs(Config.DryablePelts) do
        MainPage:RegisterElement('button', {
            label = peltInfo.label,
            slot = "content"
        }, function()
            openDryingPage(DryingMenu, peltType)
        end)
    end

    MainPage:RegisterElement('line', {
        slot = "footer"
    })

    MainPage:RegisterElement('subheader', {
        value = "Information",
        slot = "footer",
        style = {}
    })

    MainPage:RegisterElement('line', {
        slot = "footer"
    })

    MainPage:RegisterElement("html", {
        slot = "footer",
        value = {
            [[
                <img width="100px" height="100px" style="margin: 0 auto;" src="nui://vorp_inventory/html/img/items/prongs.png" />
            ]]
        }
    })


    MainPage:RegisterElement("html", {
        slot = "footer",
        value = {
            [[
                <div style="text-align: justify; margin: 0 auto; max-width: 80%; padding: 10px;">
                    Your hides are tanned as fine as a sunny day in Dodge, ready for the next stretch. Now, if you're inclined to pick 
                    and choose the number to dry, wander over to the selection on the menu.
                </div>
            ]]
        }
    })

    DryingMenu:Open({startupPage = MainPage})
end

function openDryingPage(DryingMenu, peltType)
    local peltInfo = Config.DryablePelts[peltType]

    if not peltInfo then
        return
    end

    local PeltDryingPage = DryingMenu:RegisterPage('pelt_drying_page_' .. peltType)

    PeltDryingPage:RegisterElement('header', {
        value = "Hide Drying Details",
        slot = "header"
    })

    PeltDryingPage:RegisterElement('subheader', {
        value = "Drying: " .. peltInfo.label,
        slot = "content"
    })

    PeltDryingPage:RegisterElement('line', {
        slot = "content"
    })

    PeltDryingPage:RegisterElement('subheader', {
        value = "Required Ingredients",
        slot = "content"
    })

    PeltDryingPage:RegisterElement('bottomline', {
        slot = "content"
    })

    local htmlValue = "<div style='display: flex; justify-content: space-around;'>"
    for _, ingredient in ipairs(peltInfo.requirements) do
        htmlValue = htmlValue .. "<div style='text-align: center;'>"
        htmlValue = htmlValue .. "<p>" .. ingredient.label .. "</p>"
        htmlValue = htmlValue .. "<img src='" .. ingredient.descImg .. "' style='width: 64px; height: 64px; display: block; margin: auto;'>"
        htmlValue = htmlValue .. "<p>x" .. tostring(ingredient.quantity) .. "</p>"
        htmlValue = htmlValue .. "</div>"
    end
    htmlValue = htmlValue .. "</div>"

    ingredientsHtmlElement = PeltDryingPage:RegisterElement('html', {
        value = htmlValue,
        slot = "content"
    })

    PeltDryingPage:RegisterElement('line', {
        slot = "content"
    })

    PeltDryingPage:RegisterElement('subheader', {
        value = "Results",
        slot = "content"
    })

    PeltDryingPage:RegisterElement('bottomline', {
        slot = "content"
    })

    local resultHtml = "<div style='text-align: center;'>"
    resultHtml = resultHtml .. "<p>" .. peltInfo.label .. "</p>"
    resultHtml = resultHtml .. "<img src='" .. peltInfo.Imglabel .. "' style='width: 128px; height: 128px; display: block; margin: auto;'>"
    resultHtml = resultHtml .. "<p>x1</p>" -- Default quantity is 1
    resultHtml = resultHtml .. "</div>"

    resultHtmlElement = PeltDryingPage:RegisterElement('html', {
        value = resultHtml,
        slot = "content"
    })

    PeltDryingPage:RegisterElement('slider', {
        label = "Adjust Quantity",
        start = 1,
        min = 1,
        max = 10,
        steps = 1,
        slot = "footer"
    }, function(data)
        quantity = tonumber(data.value)
        updatePeltDryingDetails(quantity, peltInfo)
    end)

    PeltDryingPage:RegisterElement('button', {
        label = "Start Drying",
        slot = "footer"
    }, function()
        TriggerServerEvent('pelt:checkCanProcess', 'drying', peltType, quantity)
        DryingMenu:Close()
    end)

    PeltDryingPage:RegisterElement('button', {
        label = "Back",
        slot = "footer"
    }, function()
        openDryingMenu()
    end)

    DryingMenu:Open({startupPage = PeltDryingPage})
end

function updatePeltDryingDetails(quantity, peltInfo)
    local newIngredientsHtml = "<div style='display: flex; justify-content: space-around;'>"
    for _, ingredient in ipairs(peltInfo.requirements) do
        newIngredientsHtml = newIngredientsHtml .. "<div style='text-align: center;'>"
        newIngredientsHtml = newIngredientsHtml .. "<p>" .. ingredient.label .. "</p>"
        newIngredientsHtml = newIngredientsHtml .. "<img src='" .. ingredient.descImg .. "' style='width: 64px; height: 64px; display: block; margin: auto;'>"
        newIngredientsHtml = newIngredientsHtml .. "<p>x" .. tostring(ingredient.quantity * quantity) .. "</p>"
        newIngredientsHtml = newIngredientsHtml .. "</div>"
    end
    newIngredientsHtml = newIngredientsHtml .. "</div>"
    ingredientsHtmlElement:update({ value = newIngredientsHtml })

    local newResultHtml = "<div style='text-align: center;'>"
    newResultHtml = newResultHtml .. "<p>" .. peltInfo.label .. "</p>"
    newResultHtml = newResultHtml .. "<img src='" .. peltInfo.Imglabel .. "' style='width: 128px; height: 128px; display: block; margin: auto;'>"
    newResultHtml = newResultHtml .. "<p>x" .. tostring(quantity) .. "</p>"
    newResultHtml = newResultHtml .. "</div>"

    resultHtmlElement:update({ value = newResultHtml })
end