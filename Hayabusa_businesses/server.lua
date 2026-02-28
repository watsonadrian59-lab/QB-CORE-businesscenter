local QBCore = exports['qb-core']:GetCoreObject()

-- open registry (send businesses + ownership)
RegisterNetEvent('hayabusa_registry:open', function()
    local src = source
    exports.oxmysql:query('SELECT * FROM hayabusa_businesses', {}, function(result)
        local owned = {}
        for _, v in pairs(result) do
            owned[v.business] = v.owner
        end
        TriggerClientEvent('hayabusa_registry:receive', src, Config.Businesses, owned)
    end)
end)

-- purchase business (max two)
RegisterNetEvent('hayabusa_registry:purchase', function(business)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local data = Config.Businesses[business]
    if not data then return end

    -- check how many owned
    exports.oxmysql:query('SELECT COUNT(*) as total FROM hayabusa_businesses WHERE owner = ?', {cid}, function(res)
        local count = res[1].total or 0
        if count >= Config.MaxBusinessesPerPlayer then
            TriggerClientEvent('QBCore:Notify', src, "You can only own " .. Config.MaxBusinessesPerPlayer .. " businesses.", "error")
            return
        end

        -- already owned?
        exports.oxmysql:single('SELECT * FROM hayabusa_businesses WHERE business = ?', {business}, function(existing)
            if existing then
                TriggerClientEvent('QBCore:Notify', src, "This business is already owned.", "error")
                return
            end

            if Player.Functions.RemoveMoney('bank', data.price) then
                Player.Functions.SetJob(data.job, data.ownerGrade)
                exports.oxmysql:insert('INSERT INTO hayabusa_businesses (business, owner) VALUES (?, ?)', { business, cid })
                TriggerClientEvent('QBCore:Notify', src, "You purchased " .. data.label, "success")
            else
                TriggerClientEvent('QBCore:Notify', src, "Not enough money.", "error")
            end
        end)
    end)
end)

-- sell business (owned by player)
RegisterNetEvent('hayabusa_registry:sell', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid

    exports.oxmysql:single('SELECT * FROM hayabusa_businesses WHERE owner = ?', {cid}, function(existing)
        if not existing then
            print("^1[SELL] No business owned by cid: " .. cid .. "^0")
            TriggerClientEvent('QBCore:Notify', src, "You do not own a business.", "error")
            return
        end

        local business = existing.business
        local data = Config.Businesses[business]
        if not data then return end

        local sellPrice = math.floor(data.price * 0.6)

        Player.Functions.AddMoney('bank', sellPrice)
        Player.Functions.SetJob("unemployed", 0)

        exports.oxmysql:query('DELETE FROM hayabusa_businesses WHERE owner = ?', {cid})

        print("^2[SELL] Business sold: " .. business .. " by " .. cid .. "^0")

        TriggerClientEvent('QBCore:Notify', src, "Business sold for $" .. sellPrice, "success")
    end)
end)

-- transfer business to another player
RegisterNetEvent('hayabusa_registry:transfer', function(business, targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    if not Target then
        TriggerClientEvent('QBCore:Notify', src, "Player not found.", "error")
        return
    end

    local cid = Player.PlayerData.citizenid
    local targetCid = Target.PlayerData.citizenid

    exports.oxmysql:single('SELECT * FROM hayabusa_businesses WHERE business = ? AND owner = ?', {business, cid}, function(existing)
        if not existing then
            TriggerClientEvent('QBCore:Notify', src, "You do not own this business.", "error")
            return
        end

        Player.Functions.RemoveMoney('bank', Config.TransferFee)
        exports.oxmysql:query('UPDATE hayabusa_businesses SET owner = ? WHERE business = ?', {targetCid, business})
        Target.Functions.SetJob(Config.Businesses[business].job, Config.Businesses[business].ownerGrade)

        TriggerClientEvent('QBCore:Notify', src, "Business transferred.", "success")
    end)
end)