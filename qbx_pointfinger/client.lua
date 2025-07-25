local pointing = false
local keybind = 29 -- INPUT_B (keyboard 'B')

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local function startPointing()
    local ped = PlayerPedId()
    loadAnimDict("anim@mp_point")
    SetPedCurrentWeaponVisible(ped, false, true, true, true)
    SetPedConfigFlag(ped, 36, true)
    TaskMoveNetworkByName(ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    pointing = true
    CreateThread(updatePointing)
end

local function stopPointing()
    local ped = PlayerPedId()
    StopAnimTask(ped, "anim@mp_point", "task_mp_pointing", 1.0)
    SetPedConfigFlag(ped, 36, false)
    ClearPedSecondaryTask(ped)
    SetPedCurrentWeaponVisible(ped, true, true, true, true)
    pointing = false
end

function math.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function updatePointing()
    while pointing do
        Wait(0)
        local ped = PlayerPedId()
        local pitch = math.clamp(GetGameplayCamRelativePitch(), -70.0, 42.0)
        local heading = math.clamp(GetGameplayCamRelativeHeading(), -180.0, 180.0)
        pitch = (pitch + 70.0) / 112.0
        heading = (heading + 180.0) / 360.0

        local blocked = 0
        local from = GetPedBoneCoords(ped, 0x796E, 0.5, 0.0, 0.0)
        local to = GetPedBoneCoords(ped, 0x796E, 1.0, 0.0, 0.0)
        local ray = StartShapeTestRay(from, to, -1, ped, 0)
        local _, hit = GetShapeTestResult(ray)
        if hit then blocked = 1 end

        SetTaskMoveNetworkSignalFloat(ped, "Pitch", pitch)
        SetTaskMoveNetworkSignalFloat(ped, "Heading", -heading + 1.0)
        SetTaskMoveNetworkSignalBool(ped, "isBlocked", blocked)
        SetTaskMoveNetworkSignalBool(ped, "isFirstPerson", GetFollowPedCamViewMode() == 4)
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, keybind) then
            if pointing then stopPointing() else startPointing() end
        end
    end
end)
