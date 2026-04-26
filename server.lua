print('[distortionz_assassin] server.lua is loading...')

local pendingContracts = {}
local activeContracts = {}
local cooldowns = {}

local function DebugPrint(message)
    if Config.Debug then
        print(('[%s:server] %s'):format(Config.ResourceName, message))
    end
end

local function Notify(src, message, status, duration)
    TriggerClientEvent('distortionz_assassin:client:notify', src, message, status or 'info', duration or 5000)
end

local function GetPlayer(src)
    if GetResourceState('qbx_core') == 'started' then
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)

        if ok and player then
            return player
        end
    end

    if GetResourceState('qb-core') == 'started' then
        local ok, QBCore = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)

        if ok and QBCore then
            return QBCore.Functions.GetPlayer(src)
        end
    end

    return nil
end

local function GetCitizenId(src)
    local player = GetPlayer(src)

    if not player then
        return ('source:%s'):format(src)
    end

    if player.PlayerData and player.PlayerData.citizenid then
        return player.PlayerData.citizenid
    end

    if player.citizenid then
        return player.citizenid
    end

    return ('source:%s'):format(src)
end

local function GetPlayerJob(src)
    local player = GetPlayer(src)

    if not player then return nil end

    if player.PlayerData and player.PlayerData.job and player.PlayerData.job.name then
        return player.PlayerData.job.name
    end

    if player.job and player.job.name then
        return player.job.name
    end

    return nil
end

local function FormatTime(seconds)
    seconds = tonumber(seconds) or 0

    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60

    if minutes <= 0 then
        return ('%ss'):format(remainingSeconds)
    end

    return ('%sm %ss'):format(minutes, remainingSeconds)
end

local function IsOnCooldown(citizenId)
    if not Config.Cooldown.enabled then
        return false, 0
    end

    local expires = cooldowns[citizenId]

    if not expires then
        return false, 0
    end

    local now = os.time()

    if now >= expires then
        cooldowns[citizenId] = nil
        return false, 0
    end

    return true, expires - now
end

local function SetCooldown(citizenId)
    if not Config.Cooldown.enabled then return end

    cooldowns[citizenId] = os.time() + Config.Cooldown.seconds
end

local function HasRequiredItem(src)
    if not Config.Contract.requireItem then
        return true
    end

    local ok, count = pcall(function()
        return exports.ox_inventory:Search(src, 'count', Config.Contract.requiredItem)
    end)

    if not ok then
        return false
    end

    return count and count > 0
end

local function RemoveRequiredItem(src)
    if not Config.Contract.requireItem then
        return true
    end

    if not Config.Contract.removeRequiredItem then
        return true
    end

    local ok, removed = pcall(function()
        return exports.ox_inventory:RemoveItem(src, Config.Contract.requiredItem, 1)
    end)

    return ok and removed
end

local function AddReward(src, item, amount)
    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then return false end

    local ok, added = pcall(function()
        return exports.ox_inventory:AddItem(src, item, amount)
    end)

    if not ok then
        print(('[%s] ox_inventory AddItem failed for source %s'):format(Config.ResourceName, src))
        return false
    end

    return added ~= false
end

local function GenerateContractId(src)
    return ('dzassassin_%s_%s_%s'):format(src, os.time(), math.random(1000, 9999))
end

local function GetRandomTargetSpawn()
    return Config.TargetSpawns[math.random(#Config.TargetSpawns)]
end

local function GetRandomBehavior(spawnData)
    local possible = {}

    for _, behavior in ipairs(spawnData.behaviors or {}) do
        if Config.Target.behaviors[behavior] then
            possible[#possible + 1] = behavior
        end
    end

    if #possible <= 0 then
        possible = { 'standing' }
    end

    return possible[math.random(#possible)]
end

local function GetRandomTargetModel()
    return Config.Target.models[math.random(#Config.Target.models)]
end

local function GetRandomAlias()
    return Config.Target.aliases[math.random(#Config.Target.aliases)]
end

local function BuildIntel(spawnData, behavior)
    local lines = Config.IntelLines[behavior] or Config.IntelLines.standing
    local line = lines[math.random(#lines)]

    return line:format(spawnData.label)
end

local function GetRewardAmount(behavior)
    local reward = math.random(Config.Contract.reward.min, Config.Contract.reward.max)

    if behavior == 'driving' and Config.Contract.drivingBonus.enabled then
        reward = reward + math.random(Config.Contract.drivingBonus.min, Config.Contract.drivingBonus.max)
    end

    return reward
end

local function GetPoliceRiskLabel()
    local chance = Config.Police.alertChance

    if chance <= 20 then
        return 'Low'
    elseif chance <= 50 then
        return 'Medium'
    end

    return 'High'
end

local function Vector4ToTable(coords)
    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w
    }
end

local function AlertPolice(coords)
    if not Config.Police.enabled then return end

    local roll = math.random(1, 100)

    if roll > Config.Police.alertChance then return end

    local players = GetPlayers()

    for _, playerId in ipairs(players) do
        local playerSrc = tonumber(playerId)
        local job = GetPlayerJob(playerSrc)

        if job and Config.Police.jobs[job] then
            TriggerClientEvent('distortionz_assassin:client:policeAlert', playerSrc, {
                coords = Vector4ToTable(coords),
                message = 'Anonymous call: suspicious armed activity reported.'
            })
        end
    end
end

local function BuildContract(src)
    local spawnData = GetRandomTargetSpawn()
    local behavior = GetRandomBehavior(spawnData)
    local rewardAmount = GetRewardAmount(behavior)

    return {
        contractId = GenerateContractId(src),
        targetAlias = GetRandomAlias(),
        targetZone = spawnData.label,
        behavior = behavior,
        model = GetRandomTargetModel(),
        coords = Vector4ToTable(spawnData.coords),
        rawCoords = spawnData.coords,
        rewardItem = Config.Contract.rewardItem,
        rewardItemLabel = 'Dirty Money',
        rewardAmount = rewardAmount,
        policeRisk = GetPoliceRiskLabel(),
        policeAlertChance = Config.Police.alertChance,
        timeLimit = Config.Contract.timeLimit,
        searchRadius = Config.Contract.searchRadius,
        intel = BuildIntel(spawnData, behavior)
    }
end

lib.callback.register('distortionz_assassin:server:getContractPreview', function(src)
    local citizenId = GetCitizenId(src)

    if activeContracts[src] then
        return {
            success = false,
            status = 'warning',
            message = 'You already have an active contract.'
        }
    end

    local onCooldown, remaining = IsOnCooldown(citizenId)

    if onCooldown then
        return {
            success = false,
            status = 'warning',
            message = ('The boss is laying low. Come back in %s.'):format(FormatTime(remaining))
        }
    end

    if not HasRequiredItem(src) then
        return {
            success = false,
            status = 'error',
            message = ('You need a %s to request a contract.'):format(Config.Contract.requiredItem)
        }
    end

    local contract = BuildContract(src)

    pendingContracts[src] = {
        citizenId = citizenId,
        contract = contract,
        createdAt = os.time()
    }

    return {
        success = true,
        contract = {
            contractId = contract.contractId,
            targetAlias = contract.targetAlias,
            targetZone = contract.targetZone,
            behavior = contract.behavior,
            rewardItem = contract.rewardItem,
            rewardItemLabel = contract.rewardItemLabel,
            rewardAmount = contract.rewardAmount,
            policeRisk = contract.policeRisk,
            policeAlertChance = contract.policeAlertChance,
            timeLimit = contract.timeLimit,
            searchRadius = contract.searchRadius,
            intel = contract.intel
        }
    }
end)

lib.callback.register('distortionz_assassin:server:acceptContract', function(src)
    local pending = pendingContracts[src]

    if not pending then
        return {
            success = false,
            status = 'error',
            message = 'No pending contract found.'
        }
    end

    if activeContracts[src] then
        pendingContracts[src] = nil

        return {
            success = false,
            status = 'warning',
            message = 'You already have an active contract.'
        }
    end

    local citizenId = GetCitizenId(src)
    local onCooldown, remaining = IsOnCooldown(citizenId)

    if onCooldown then
        pendingContracts[src] = nil

        return {
            success = false,
            status = 'warning',
            message = ('The boss is laying low. Come back in %s.'):format(FormatTime(remaining))
        }
    end

    if not HasRequiredItem(src) then
        pendingContracts[src] = nil

        return {
            success = false,
            status = 'error',
            message = ('You need a %s to accept this contract.'):format(Config.Contract.requiredItem)
        }
    end

    if not RemoveRequiredItem(src) then
        pendingContracts[src] = nil

        return {
            success = false,
            status = 'error',
            message = 'The boss refused the contract request.'
        }
    end

    local contract = pending.contract

    activeContracts[src] = {
        contractId = contract.contractId,
        citizenId = citizenId,
        behavior = contract.behavior,
        rewardItem = contract.rewardItem,
        rewardAmount = contract.rewardAmount,
        startedAt = os.time(),
        expiresAt = os.time() + contract.timeLimit
    }

    pendingContracts[src] = nil

    AlertPolice(contract.rawCoords)

    DebugPrint(('Contract accepted by %s | %s | reward %s %s'):format(
        src,
        contract.contractId,
        contract.rewardAmount,
        contract.rewardItem
    ))

    return {
        success = true,
        contract = {
            contractId = contract.contractId,
            targetAlias = contract.targetAlias,
            targetZone = contract.targetZone,
            behavior = contract.behavior,
            model = contract.model,
            coords = contract.coords,
            rewardItem = contract.rewardItem,
            rewardItemLabel = contract.rewardItemLabel,
            rewardAmount = contract.rewardAmount,
            policeRisk = contract.policeRisk,
            policeAlertChance = contract.policeAlertChance,
            timeLimit = contract.timeLimit,
            searchRadius = contract.searchRadius,
            intel = contract.intel
        }
    }
end)

RegisterNetEvent('distortionz_assassin:server:clearPendingContract', function()
    local src = source
    pendingContracts[src] = nil
end)

RegisterNetEvent('distortionz_assassin:server:completeContract', function(contractId)
    local src = source
    local contract = activeContracts[src]

    if not contract then
        Notify(src, 'No active contract found.', 'error')
        return
    end

    if contract.contractId ~= contractId then
        Notify(src, 'Contract verification failed.', 'error')
        return
    end

    if os.time() > contract.expiresAt then
        activeContracts[src] = nil
        SetCooldown(contract.citizenId)
        Notify(src, 'Contract expired before payment could be processed.', 'error')
        return
    end

    local added = AddReward(src, contract.rewardItem, contract.rewardAmount)

    if not added then
        Notify(src, 'Your pockets are too full for the payment.', 'error')
        return
    end

    activeContracts[src] = nil
    SetCooldown(contract.citizenId)

    Notify(src, ('Contract complete. You received $%s dirty money.'):format(contract.rewardAmount), 'success', 7500)

    DebugPrint(('Contract completed by %s | paid %s %s'):format(
        src,
        contract.rewardAmount,
        contract.rewardItem
    ))
end)

RegisterNetEvent('distortionz_assassin:server:failContract', function()
    local src = source
    local contract = activeContracts[src]

    if not contract then return end

    activeContracts[src] = nil
    SetCooldown(contract.citizenId)

    DebugPrint(('Contract failed by %s'):format(src))
end)

AddEventHandler('playerDropped', function()
    local src = source

    pendingContracts[src] = nil
    activeContracts[src] = nil
end)

CreateThread(function()
    Wait(1000)
    print(('[%s] Server callbacks loaded successfully.'):format(Config.ResourceName))
end)