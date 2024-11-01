Config = {}

Config.Debug = false
Config.locale = 'en_lang' -- Change this to the language you want to use.
Config.keys = {
    E = 0x41AC83D1,
    R = 0xE3BF959B,
    G = 0xA1ABB953,
    F = 0x26A18F47
}

----------------------------------------------------------------
-- Tanning Configurtions
----------------------------------------------------------------

Config.CleanablePelts = { -- Cleaning Recipes

    AligatorPelt = {
        label = 'Aligator Pelt',
        Imglabel = 'nui://vorp_inventory/html/img/items/aligators.png',
        category = 'Cleanable Pelts',
        subcategory = 'Pelts',
        requirements = {
            {item = 'aligators', label = 'Aligator Pelt', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/aligators.png"},
            {item = 'salt', label = 'Salt', quantity = 3, descImg = "nui://vorp_inventory/html/img/items/salt.png"},
        },
        result = {
            type = 'item',
            name = 'clean_pelt',
            label = 'Clean Pelt',
            quantity = 1
        }
    },
    WolfFur = {
        label = 'Wolf Pelt',
        Imglabel = 'nui://vorp_inventory/html/img/items/wolfpelt.png',
        category = 'Cleanable Pelts',
        subcategory = 'Pelts',
        requirements = {
            {item = 'wolfpelt', label = 'Wolf Pelt', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/wolfpelt.png"},
            {item = 'salt', label = 'Salt', quantity = 3, descImg = "nui://vorp_inventory/html/img/items/salt.png"},
        },
        result = {
            type = 'item',
            name = 'clean_pelt',
            label = 'Clean Pelt',
            quantity = 1
        }
    }
}

Config.TannablePelts = { -- Tanning Pelts
    CleanPelt = {
        label = 'Tanned Leather',
        Imglabel = 'nui://vorp_inventory/html/img/items/tanned_leather.png',
        category = 'Weaving',
        subcategory = 'Leather',
        requirements = {
            {item = 'clean_pelt', label = 'Clean Pelt', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/clean_pelt.png"},
            {item = 'salt', label = 'Salt', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/salt.png"},
            {item = 'water', label = 'Water', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/water.png"},
            {item = 'brain_oil', label = 'Brain Oil', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/brain_oil.png"}
        },
        result = {
            type = 'item',
            name = 'tanned_leather',
            label = 'Tanned Leather',
            quantity = 1
        }
    },
}

Config.DryablePelts = { -- Drying recipes
    TannedLeather = {
        label = 'Dry Leather',
        Imglabel = 'nui://vorp_inventory/html/img/items/leather.png',
        category = 'Weaving',
        subcategory = 'Leather',
        requirements = {
            {item = 'tanned_leather', label = 'Tanned Leather', quantity = 1, descImg = "nui://vorp_inventory/html/img/items/tanned_leather.png"},
        },
        result = {
            type = 'item',
            name = 'leather',
            label = 'Leather',
            quantity = 1
        }
    }
}

Config.FixedHideProps = {
    'mp005_p_mp_hideframe02x',
}

Config.FixedHideProps2 = {
    'p_basinwater01x'
}

Config.FixedCleaningBarrelProps = {
    'p_washtub02x',
}

Config.hideframecoords = { -- Hideframe coords used for tanning, drying
    {x = 488.04, y = 2207.88, z = 245.91, h = -21.52},
    {x = -3604.763671875, y = -2614.5908203125, z = -14.69622707366943},
}

Config.cleaningbarrelcoords = { -- Cleaning barrel coords used for cleaning pelts
    {x = 490.97, y = 2207.82, z = 245.9, h = 25.99},
    {x = -3606.5615234375, y = -2612.35107421875, z = -14.6571683883667}
}

Config.hideframewatercoords = { -- Water next to the hideframe
    {x = 487.9388122558594, y = 2208.575439453125, z = 245.88665771484375, h = -21.52},
    {x = -3605.1923828125, y = -2614.122802734375, z = -14.67568302154541},

}


Config.blips = {
    ["1"] = { -- Ambranino
        enabled = true,
        coords = {x = 486.69, y = 2211.47, z = 247.01},
        sprite = 218395012,
        scale = 1.0,
        color = 'BLIP_MODIFIER_AREA',
    },
    ["2"] = { -- Armadillo
        enabled = true,
        coords = {x = -3603.26, y = -2611.43, z = -13.8},
        sprite = 218395012,
        scale = 1.0,
        color = 'BLIP_MODIFIER_AREA',
    },
}
