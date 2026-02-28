local QBCore = exports['qb-core']:GetCoreObject()

-- Create target zone
CreateThread(function()
    Wait(1000)

    local coords = vector3(-550.68, -192.52, 38.22)

    exports['qb-target']:AddBoxZone("hayabusa_business_registry", coords, 2.0, 2.0, {
        name = "hayabusa_business_registry",
        heading = 0.0,
        debugPoly = false,
        useZ = true,
    }, {
        options = {
            {
                type = "client",
                event = "hayabusa_registry:open",
                icon = "fas fa-building",
                label = "City Business Registry",
            },
        },
        distance = 3.0
    })
end)

-- Open registry
RegisterNetEvent('hayabusa_registry:open', function()
    TriggerServerEvent('hayabusa_registry:open')
end)

-- Receive business list and ownership info
RegisterNetEvent('hayabusa_registry:receive', function(businesses, owned)
    local Menu = {
        { header = "City Business Registry", isMenuHeader = true }
    }

    local myBusinesses = {}

    for name, data in pairs(businesses) do
        if data and data.label and data.price then
            local status = owned and owned[name]

            local header = data.label .. " - $"
            if status then
                header = header .. data.price .. " (OWNED)"
                myBusinesses[name] = true
            else
                header = header .. data.price
            end

            table.insert(Menu, {
                header = header,
                txt = status and "Owned" or "Purchase this business",
                disabled = status ~= nil,
                params = {
                    event = status and "" or "hayabusa_registry:purchase",
                    isServer = not status,
                    args = name
                }
            })
        end
    end

    -- My Businesses section
    table.insert(Menu, { header = "My Businesses", isMenuHeader = true })

    for name, _ in pairs(myBusinesses) do
        local data = businesses[name]
        table.insert(Menu, {
            header = data.label,
            txt = "Manage or sell this business",
            params = {
                event = "hayabusa_registry:mybusiness",
                args = name
            }
        })
    end

    -- close
    table.insert(Menu, {
        header = "Close",
        params = { event = "" }
    })

    exports['qb-menu']:openMenu(Menu)
end)

-- My business management menu
RegisterNetEvent('hayabusa_registry:mybusiness', function(business)
    exports['qb-menu']:openMenu({
        {
            header = "Manage Business",
            isMenuHeader = true
        },
        {
            header = "Transfer Business",
            txt = "Transfer to another player for $" .. Config.TransferFee,
            params = {
                event = "hayabusa_registry:prompttransfer",
                args = business
            }
        },
        {
            header = "Sell Business",
            txt = "Sell this business back to the city",
            params = {
                event = "hayabusa_registry:sell",
                isServer = true
            }
        },
        {
            header = "Back",
            params = { event = "hayabusa_registry:open" }
        }
    })
end)

-- prompt transfer
RegisterNetEvent('hayabusa_registry:prompttransfer', function(business)
    local input = exports['qb-input']:ShowInput({
        header = "Transfer Business",
        submitText = "Transfer",
        inputs = {
            {
                text = "Player ID",
                name = "target",
                type = "number",
                isRequired = true
            }
        }
    })

    if not input then return end

    local target = tonumber(input.target)
    if not target then return end

    TriggerServerEvent('hayabusa_registry:transfer', business, target)
end)