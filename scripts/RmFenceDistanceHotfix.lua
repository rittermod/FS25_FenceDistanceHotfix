--[[
    RmFenceDistanceHotfix.lua

    Main module for FenceDistanceHotfix mod.
    Contains all mod logic, state, and game integration hooks.

    This file is loaded by scripts/main.lua.

    Author: Ritter
    Version: 0.0.1.0

    ARCHITECTURE:
    - Module declaration and state management
    - Game lifecycle hooks (loadMapFinished, delete)
    - Fence validation hooks and their helpers
]]

-- Module declaration
-- Note: Dependencies (RmLogging) are loaded via scripts/main.lua
RmFenceDistanceHotfix = {}
RmFenceDistanceHotfix.modDirectory = g_currentModDirectory
RmFenceDistanceHotfix.modName = g_currentModName

-- Per-mod logger instance with automatic multiplayer context
local Log = RmLogging.getLogger("FenceDistanceHotfix")

-- Module constants
-- Horizontal length in meters below which a too-short refusal counts as zero-length and is kept
RmFenceDistanceHotfix.ZERO_LENGTH_LIMIT = 0.1

-- Above 0 while a husbandry placeable validates its built-in fence
local pastureValidationDepth = 0
-- Segment -> last length logged as a fallback, so the per-frame preview logs each length once
local loggedFallbacks = setmetatable({}, { __mode = "k" })

-- ============================================================================
-- INITIALIZATION: Lifecycle hooks
-- ============================================================================

---Called when map finishes loading
---This is the main entry point for mod initialization
local function onLoadMapFinished()
    Log:info("Map loaded, initializing FenceDistanceHotfix")

    Log:info("FenceDistanceHotfix initialization complete")
end

-- Hook into map loading completion
BaseMission.loadMapFinished = Utils.appendedFunction(
    BaseMission.loadMapFinished,
    onLoadMapFinished
)

-- ============================================================================
-- CLEANUP: Map unload
-- ============================================================================

---Called when map is being deleted/unloaded
---Logs the unload; the mod holds no subscriptions or per-map state to clean up
local function onDeleteMap()
    Log:debug("Cleaning up FenceDistanceHotfix")
end

BaseMission.delete = Utils.appendedFunction(
    BaseMission.delete,
    onDeleteMap
)


-- ============================================================================
-- CORE FUNCTIONALITY
-- ============================================================================


local function getHorizontalLength(segment)
    return MathUtil.vector2Length(segment.endPosX - segment.startPosX, segment.endPosZ - segment.startPosZ)
end

local function logFallback(segment)
    local lengthText = string.format("%.4f", getHorizontalLength(segment))
    if loggedFallbacks[segment] == lengthText then
        return
    end
    loggedFallbacks[segment] = lengthText

    local metadata = segment.metadata or {}
    local shortestPanelLength = nil
    if metadata.panels ~= nil and #metadata.panels > 0 then
        shortestPanelLength = metadata.panels[#metadata.panels].length
    end
    Log:debug("FALLBACK: segment %s (%s) length %s m, shortest panel %s m, panel maxScale %s"
        .. " - building it without placement validation",
        tostring(segment.id), tostring(metadata.id), lengthText,
        tostring(shortestPanelLength), tostring(metadata.panelsMaxScale))
end

---Whether a failed segment build was refused only for being shorter than one fence panel
---@param segment table FenceSegment after a failed updateMeshes call
---@return boolean isPanelMinimumRefusal True for the panel-length refusal, false for any other failure
function RmFenceDistanceHotfix.getIsPanelMinimumRefusal(segment)
    if segment.lastError ~= FenceSegment.ERROR_TOO_SHORT then
        Log:trace("    getIsPanelMinimumRefusal(%s): lastError %s is not too-short",
            tostring(segment.id), tostring(segment.lastError))
        return false
    end
    if segment.startPosX == nil or segment.endPosX == nil then
        Log:trace("    getIsPanelMinimumRefusal(%s): positions not set", tostring(segment.id))
        return false
    end
    local lengthXZ = getHorizontalLength(segment)
    if lengthXZ < RmFenceDistanceHotfix.ZERO_LENGTH_LIMIT then
        Log:trace("    getIsPanelMinimumRefusal(%s): length %s is a zero-length refusal",
            tostring(segment.id), tostring(lengthXZ))
        return false
    end
    return true
end

---Runs the original build; in pasture validation, reruns a panel-length refusal without placement validation
---@param segment table FenceSegment being built
---@param superFunc function Original FenceSegment.updateMeshes
---@param force boolean|nil Rebuild even when the segment is not dirty
---@param validatePlacement boolean|nil Apply placement checks; nil means true
---@return boolean success True when the segment was built
function RmFenceDistanceHotfix.updateMeshes(segment, superFunc, force, validatePlacement)
    local success = superFunc(segment, force, validatePlacement)
    if success then
        Log:trace("<<< updateMeshes(%s) = %s", tostring(segment.id), tostring(success))
        return success
    end
    if pastureValidationDepth == 0 then
        Log:trace("<<< updateMeshes(%s) = %s, outside pasture validation", tostring(segment.id), tostring(success))
        return success
    end
    if not RmFenceDistanceHotfix.getIsPanelMinimumRefusal(segment) then
        Log:trace("<<< updateMeshes(%s) = %s, not a panel-length refusal", tostring(segment.id), tostring(success))
        return success
    end

    logFallback(segment)
    local rerunSuccess = superFunc(segment, true, false)
    Log:trace("<<< updateMeshes(%s) = %s after rerun without validation, lastError %s",
        tostring(segment.id), tostring(rerunSuccess), tostring(segment.lastError))
    return rerunSuccess
end

---Marks the original updateHusbandryFence call as pasture fence validation while it runs
---@param placeable table Husbandry placeable validating its built-in fence
---@param superFunc function Original PlaceableHusbandryFence.updateHusbandryFence
---@return boolean canBePlaced Result of the original call
function RmFenceDistanceHotfix.updateHusbandryFence(placeable, superFunc)
    pastureValidationDepth = pastureValidationDepth + 1
    Log:trace(">>> updateHusbandryFence(%s) depth %s",
        tostring(placeable.configFileName), tostring(pastureValidationDepth))
    local result = superFunc(placeable)
    pastureValidationDepth = pastureValidationDepth - 1
    Log:trace("<<< updateHusbandryFence = %s, depth %s", tostring(result), tostring(pastureValidationDepth))
    return result
end

-- ============================================================================
-- GAME HOOKS
-- ============================================================================

local installedHooks = {}

if type(FenceSegment) == "table" and type(FenceSegment.updateMeshes) == "function" then
    FenceSegment.updateMeshes = Utils.overwrittenFunction(FenceSegment.updateMeshes,
        RmFenceDistanceHotfix.updateMeshes)
    table.insert(installedHooks, "FenceSegment.updateMeshes")
else
    Log:warning("FenceSegment.updateMeshes not found - pasture fence fallback not installed")
end

-- Placeable types copy this function into their own function tables when types are finalized,
-- which happens after every mod is loaded, so the hook must be installed while this file is sourced.
if type(PlaceableHusbandryFence) == "table"
    and type(PlaceableHusbandryFence.updateHusbandryFence) == "function" then
    PlaceableHusbandryFence.updateHusbandryFence = Utils.overwrittenFunction(
        PlaceableHusbandryFence.updateHusbandryFence, RmFenceDistanceHotfix.updateHusbandryFence)
    table.insert(installedHooks, "PlaceableHusbandryFence.updateHusbandryFence")
else
    Log:warning("PlaceableHusbandryFence.updateHusbandryFence not found - pasture fence fallback not installed")
end

if #installedHooks > 0 then
    Log:info("Fence hooks installed: %s", table.concat(installedHooks, ", "))
else
    Log:info("Fence hooks installed: none")
end

-- ============================================================================
-- INITIALIZATION COMPLETE
-- ============================================================================

Log:info("FenceDistanceHotfix mod loaded (v%s)",
    g_modManager:getModByName(RmFenceDistanceHotfix.modName).version)
