local bossPed = nil
local bossBlip = nil

local activeMission = nil
local targetPed = nil
local targetVehicle = nil
local targetBlip = nil
local searchBlip = nil
local missionThread = nil

local nuiOpen = false

local function DebugPrint(message)
    if Config.Debug then
        print(('[%s:client] %s'):format(Config.ResourceName, message))
    end
end

local function Notify(message, status, duration)
    status = status or 'info'
    duration = duration or 5000

    if Config.Notify.useDistortionzNotify and GetResourceState('distortionz_notify') == 'started' then
        local ok = pcall(function()
            exports['distortionz_notify']:Notify(message, status, duration)
        end)

        if ok then return end

        ok = pcall(function()
            exports['distortionz_notify']:Send(message, status, duration)
        end)

        if ok then return end

        ok = pcall(function()
            TriggerEvent('distortionz_notify:client:notify', message, status, duration)
        end)

        if ok then return end
    end

    lib.notify({
        title = Config.Notify.title,
        description = message,
        type = status,
        duration = duration
    })
end

RegisterNetEvent('distortionz_assassin:client:notify', function(message, status, duration)
    Notify(message, status, duration)
end)

local function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if not IsModelInCdimage(hash) then
        DebugPrint(('Invalid model: %s'):format(tostring(model)))
        return nil
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 10000

    while not HasModelLoaded(hash) do
        Wait(25)

        if GetGameTimer() > timeout then
            DebugPrint(('Model load timeout: %s'):format(tostring(model)))
            return nil
        end
    end

    return hash
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 8000

    while not HasAnimDictLoaded(dict) do
        Wait(25)

        if GetGameTimer() > timeout then
            DebugPrint(('Anim dict timeout: %s'):format(dict))
            return false
        end
    end

    return true
end

local function DeleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

local function RemoveBlipSafe(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

local function CoordsToVector4(coords)
    return vector4(
        tonumber(coords.x) or 0.0,
        tonumber(coords.y) or 0.0,
        tonumber(coords.z) or 0.0,
        tonumber(coords.w) or 0.0
    )
end

local function CloseContractUI()
    nuiOpen = false
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })
end

local function PlayBossBriefingAnimation()
    if not bossPed or not DoesEntityExist(bossPed) then return end

    ClearPedTasksImmediately(bossPed)

    if LoadAnimDict('gestures@m@standing@casual') then
        TaskPlayAnim(
            bossPed,
            'gestures@m@standing@casual',
            'gesture_point',
            8.0,
            -8.0,
            2500,
            48,
            0.0,
            false,
            false,
            false
        )
    end

    CreateThread(function()
        Wait(2600)

        if bossPed and DoesEntityExist(bossPed) then
            ClearPedTasksImmediately(bossPed)

            if Config.Boss.scenario and Config.Boss.scenario ~= '' then
                TaskStartScenarioInPlace(bossPed, Config.Boss.scenario, 0, true)
            end
        end
    end)
end

local function CreateBossBlip()
    if not Config.Boss.blip.enabled then return end

    RemoveBlipSafe(bossBlip)

    local coords = Config.Boss.coords

    bossBlip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(bossBlip, Config.Boss.blip.sprite)
    SetBlipColour(bossBlip, Config.Boss.blip.color)
    SetBlipScale(bossBlip, Config.Boss.blip.scale)
    SetBlipAsShortRange(bossBlip, Config.Boss.blip.shortRange)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Boss.blip.label)
    EndTextCommandSetBlipName(bossBlip)
end

local function CleanupMission()
    RemoveBlipSafe(targetBlip)
    RemoveBlipSafe(searchBlip)

    if activeMission and activeMission.centerBlip then
        RemoveBlipSafe(activeMission.centerBlip)
        activeMission.centerBlip = nil
    end

    targetBlip = nil
    searchBlip = nil

    DeleteEntitySafe(targetPed)
    DeleteEntitySafe(targetVehicle)

    targetPed = nil
    targetVehicle = nil
    activeMission = nil
    missionThread = nil

    SendNUIMessage({
        action = 'activeClose'
    })
end

local function CreateSearchBlip(coords)
    RemoveBlipSafe(searchBlip)

    if activeMission and activeMission.centerBlip then
        RemoveBlipSafe(activeMission.centerBlip)
        activeMission.centerBlip = nil
    end

    searchBlip = AddBlipForRadius(coords.x, coords.y, coords.z, Config.Contract.searchRadius + 0.0)
    SetBlipColour(searchBlip, 1)
    SetBlipAlpha(searchBlip, 100)

    local centerBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(centerBlip, 310)
    SetBlipColour(centerBlip, 1)
    SetBlipScale(centerBlip, 0.75)
    SetBlipAsShortRange(centerBlip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Contract Search Area')
    EndTextCommandSetBlipName(centerBlip)

    activeMission.centerBlip = centerBlip
    activeMission.lastSearchUpdate = GetGameTimer()
end

local function UpdateMovingSearchArea()
    if not Config.Contract.movingSearchArea then return end
    if not activeMission then return end
    if not targetPed or not DoesEntityExist(targetPed) then return end
    if not searchBlip or not DoesBlipExist(searchBlip) then return end

    local now = GetGameTimer()
    local interval = Config.Contract.movingSearchUpdateInterval or 3000

    if activeMission.lastSearchUpdate and now - activeMission.lastSearchUpdate < interval then
        return
    end

    activeMission.lastSearchUpdate = now

    local targetCoords = GetEntityCoords(targetPed)

    SetBlipCoords(searchBlip, targetCoords.x, targetCoords.y, targetCoords.z)

    if activeMission.centerBlip and DoesBlipExist(activeMission.centerBlip) then
        SetBlipCoords(activeMission.centerBlip, targetCoords.x, targetCoords.y, targetCoords.z)
    end
end

local function CreateTargetBlip(entity)
    if not Config.Contract.showExactTargetBlip then return end

    RemoveBlipSafe(targetBlip)

    targetBlip = AddBlipForEntity(entity)

    SetBlipSprite(targetBlip, 432)
    SetBlipColour(targetBlip, 1)
    SetBlipScale(targetBlip, 0.85)
    SetBlipAsShortRange(targetBlip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Contract Target')
    EndTextCommandSetBlipName(targetBlip)
end

local function SetupTargetCombat(ped)
    local groupHash = joaat(Config.Target.relationshipGroup)

    AddRelationshipGroup(Config.Target.relationshipGroup)
    SetPedRelationshipGroupHash(ped, groupHash)

    SetRelationshipBetweenGroups(5, groupHash, joaat('PLAYER'))
    SetRelationshipBetweenGroups(5, joaat('PLAYER'), groupHash)

    SetPedMaxHealth(ped, Config.Target.health)
    SetEntityHealth(ped, Config.Target.health)
    SetPedArmour(ped, Config.Target.armor)
    SetPedAccuracy(ped, Config.Target.accuracy)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAbility(ped, 1)
    SetPedCombatRange(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetBlockingOfNonTemporaryEvents(ped, false)

    if Config.Target.canFightBack then
        local weapon = Config.Target.weapons[math.random(#Config.Target.weapons)]
        GiveWeaponToPed(ped, joaat(weapon), 120, false, true)
    end
end

local function SpawnStandingTarget(contract)
    local model = LoadModel(contract.model)
    if not model then return false end

    local coords = CoordsToVector4(contract.coords)

    targetPed = CreatePed(
        4,
        model,
        coords.x,
        coords.y,
        coords.z,
        coords.w,
        true,
        true
    )

    SetEntityAsMissionEntity(targetPed, true, true)
    PlaceObjectOnGroundProperly(targetPed)
    SetupTargetCombat(targetPed)

    local scenario = Config.Target.standingScenarios[math.random(#Config.Target.standingScenarios)]
    TaskStartScenarioInPlace(targetPed, scenario, 0, true)

    SetModelAsNoLongerNeeded(model)
    return true
end

local function SpawnWalkingTarget(contract)
    local model = LoadModel(contract.model)
    if not model then return false end

    local coords = CoordsToVector4(contract.coords)

    targetPed = CreatePed(
        4,
        model,
        coords.x,
        coords.y,
        coords.z,
        coords.w,
        true,
        true
    )

    SetEntityAsMissionEntity(targetPed, true, true)
    PlaceObjectOnGroundProperly(targetPed)
    SetupTargetCombat(targetPed)

    TaskWanderStandard(targetPed, 10.0, 10)

    SetModelAsNoLongerNeeded(model)
    return true
end

local function SpawnBuildingTarget(contract)
    local model = LoadModel(contract.model)
    if not model then return false end

    local coords = CoordsToVector4(contract.coords)

    targetPed = CreatePed(
        4,
        model,
        coords.x,
        coords.y,
        coords.z,
        coords.w,
        true,
        true
    )

    SetEntityAsMissionEntity(targetPed, true, true)
    PlaceObjectOnGroundProperly(targetPed)
    SetupTargetCombat(targetPed)

    local scenario = Config.Target.buildingScenarios[math.random(#Config.Target.buildingScenarios)]
    TaskStartScenarioInPlace(targetPed, scenario, 0, true)

    SetModelAsNoLongerNeeded(model)
    return true
end

local function SpawnDrivingTarget(contract)
    local pedModel = LoadModel(contract.model)
    if not pedModel then return false end

    local vehicleModelName = Config.Target.drivingVehicles[math.random(#Config.Target.drivingVehicles)]
    local vehicleModel = LoadModel(vehicleModelName)

    if not vehicleModel then
        SetModelAsNoLongerNeeded(pedModel)
        return false
    end

    local coords = CoordsToVector4(contract.coords)

    targetVehicle = CreateVehicle(
        vehicleModel,
        coords.x,
        coords.y,
        coords.z,
        coords.w,
        true,
        true
    )

    SetEntityAsMissionEntity(targetVehicle, true, true)
    SetVehicleOnGroundProperly(targetVehicle)
    SetVehicleEngineOn(targetVehicle, true, true, false)
    SetVehicleDoorsLocked(targetVehicle, 1)

    targetPed = CreatePedInsideVehicle(
        targetVehicle,
        4,
        pedModel,
        -1,
        true,
        true
    )

    SetEntityAsMissionEntity(targetPed, true, true)
    SetupTargetCombat(targetPed)

    TaskVehicleDriveWander(targetPed, targetVehicle, 22.0, 786603)

    SetModelAsNoLongerNeeded(pedModel)
    SetModelAsNoLongerNeeded(vehicleModel)

    return true
end

local function SpawnTarget(contract)
    if contract.behavior == 'standing' then
        return SpawnStandingTarget(contract)
    elseif contract.behavior == 'walking' then
        return SpawnWalkingTarget(contract)
    elseif contract.behavior == 'driving' then
        return SpawnDrivingTarget(contract)
    elseif contract.behavior == 'building' then
        return SpawnBuildingTarget(contract)
    end

    return SpawnStandingTarget(contract)
end

local function UpdateActiveContractUI()
    if not activeMission then return end

    local remainingMs = activeMission.expiresAt - GetGameTimer()
    local remainingSeconds = math.max(0, math.floor(remainingMs / 1000))

    SendNUIMessage({
        action = 'activeUpdate',
        data = {
            targetAlias = activeMission.targetAlias,
            targetZone = activeMission.targetZone,
            behavior = activeMission.behavior,
            rewardAmount = activeMission.rewardAmount,
            rewardItemLabel = activeMission.rewardItemLabel,
            remainingSeconds = remainingSeconds
        }
    })
end

local function StartMissionMonitor()
    if missionThread then return end

    missionThread = CreateThread(function()
        while activeMission do
            Wait(1000)

            UpdateActiveContractUI()
            UpdateMovingSearchArea()

            if not targetPed or not DoesEntityExist(targetPed) then
                Notify('The target disappeared. Contract failed.', 'error')
                TriggerServerEvent('distortionz_assassin:server:failContract')
                CleanupMission()
                break
            end

            local now = GetGameTimer()

            if now >= activeMission.expiresAt then
                Notify('Contract expired. The target got away.', 'error')
                TriggerServerEvent('distortionz_assassin:server:failContract')
                CleanupMission()
                break
            end

            if IsPedDeadOrDying(targetPed, true) then
                local killer = GetPedSourceOfDeath(targetPed)
                local playerPed = PlayerPedId()
                local playerVehicle = GetVehiclePedIsIn(playerPed, false)

                if killer == playerPed or killer == playerVehicle then
                    Notify('Target eliminated. Payment is being processed.', 'success')
                    TriggerServerEvent('distortionz_assassin:server:completeContract', activeMission.contractId)
                    CleanupMission()
                    break
                else
                    Notify('Target died, but you did not complete the hit. Contract failed.', 'error')
                    TriggerServerEvent('distortionz_assassin:server:failContract')
                    CleanupMission()
                    break
                end
            end
        end
    end)
end

local function BeginContract(contract)
    if activeMission then
        Notify('You already have an active contract.', 'warning')
        return
    end

    activeMission = {
        contractId = contract.contractId,
        targetAlias = contract.targetAlias,
        targetZone = contract.targetZone,
        behavior = contract.behavior,
        rewardAmount = contract.rewardAmount,
        rewardItemLabel = contract.rewardItemLabel,
        expiresAt = GetGameTimer() + ((tonumber(contract.timeLimit) or Config.Contract.timeLimit) * 1000),
        centerBlip = nil,
        lastSearchUpdate = nil
    }

    local spawned = SpawnTarget(contract)

    if not spawned then
        Notify('Failed to locate the target. Contract cancelled.', 'error')
        TriggerServerEvent('distortionz_assassin:server:failContract')
        CleanupMission()
        return
    end

    local coords = CoordsToVector4(contract.coords)

    if Config.Contract.useSearchRadius then
        CreateSearchBlip(coords)
    end

    CreateTargetBlip(targetPed)

    SendNUIMessage({
        action = 'activeOpen',
        data = {
            targetAlias = contract.targetAlias,
            targetZone = contract.targetZone,
            behavior = contract.behavior,
            rewardAmount = contract.rewardAmount,
            rewardItemLabel = contract.rewardItemLabel,
            remainingSeconds = tonumber(contract.timeLimit) or Config.Contract.timeLimit
        }
    })

    Notify(contract.intel, 'info', 9000)
    Notify(('You have %s minutes to finish the contract.'):format(math.floor((tonumber(contract.timeLimit) or Config.Contract.timeLimit) / 60)), 'warning', 7000)

    StartMissionMonitor()
end

local function OpenContractUI()
    if activeMission then
        Notify('You already have an active contract.', 'warning')
        return
    end

    local data = lib.callback.await('distortionz_assassin:server:getContractPreview', false)

    if not data then
        Notify('The boss has no work for you right now.', 'error')
        return
    end

    if not data.success then
        Notify(data.message or 'Contract unavailable.', data.status or 'error')
        return
    end

    nuiOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        data = data.contract
    })
end

local function SpawnBoss()
    if bossPed and DoesEntityExist(bossPed) then return end

    local model = LoadModel(Config.Boss.model)
    if not model then return end

    local coords = Config.Boss.coords

    bossPed = CreatePed(
        0,
        model,
        coords.x,
        coords.y,
        coords.z,
        coords.w,
        false,
        false
    )
    Entity(bossPed).state:set('distortionz_protected_ped', true, true)
    Entity(bossPed).state:set('distortionz_boss_ped', true, true)
    Entity(bossPed).state:set('distortionz_assassin_boss', true, true)
    
    SetEntityAsMissionEntity(bossPed, true, true)
    PlaceObjectOnGroundProperly(bossPed)
    SetBlockingOfNonTemporaryEvents(bossPed, true)
    SetPedCanRagdoll(bossPed, false)
    SetEntityInvincible(bossPed, true)
    FreezeEntityPosition(bossPed, true)

    if Config.Boss.scenario and Config.Boss.scenario ~= '' then
        TaskStartScenarioInPlace(bossPed, Config.Boss.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(bossPed, {
        {
            name = 'distortionz_assassin_open_contract_board',
            icon = Config.Boss.target.icon,
            label = Config.Boss.target.label,
            distance = Config.Boss.target.distance,
            onSelect = function()
                OpenContractUI()
            end
        }
    })

    SetModelAsNoLongerNeeded(model)
    CreateBossBlip()
end

RegisterNUICallback('close', function(_, cb)
    CloseContractUI()
    cb({ success = true })
end)

RegisterNUICallback('acceptContract', function(_, cb)
    if activeMission then
        cb({
            success = false,
            message = 'You already have an active contract.'
        })

        return
    end

    local result = lib.callback.await('distortionz_assassin:server:acceptContract', false)

    if not result then
        cb({
            success = false,
            message = 'The boss refused the contract.'
        })

        return
    end

    cb(result)

    if not result.success then
        return
    end

    CloseContractUI()
    PlayBossBriefingAnimation()

    CreateThread(function()
        Wait(800)
        BeginContract(result.contract)
    end)
end)

RegisterNUICallback('cancelContract', function(_, cb)
    TriggerServerEvent('distortionz_assassin:server:clearPendingContract')
    CloseContractUI()
    cb({ success = true })
end)

RegisterNetEvent('distortionz_assassin:client:policeAlert', function(alertData)
    local coords = alertData.coords

    Notify(alertData.message or 'Suspicious activity reported.', 'warning', 7500)

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, Config.Police.alertBlip.sprite)
    SetBlipColour(blip, Config.Police.alertBlip.color)
    SetBlipScale(blip, Config.Police.alertBlip.scale)
    SetBlipAsShortRange(blip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Suspicious Activity')
    EndTextCommandSetBlipName(blip)

    CreateThread(function()
        Wait(Config.Police.alertBlip.duration * 1000)
        RemoveBlipSafe(blip)
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CloseContractUI()
    CleanupMission()

    DeleteEntitySafe(bossPed)
    RemoveBlipSafe(bossBlip)
end)

CreateThread(function()
    Wait(1000)
    SpawnBoss()
end)