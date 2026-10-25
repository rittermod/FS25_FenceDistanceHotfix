--[[
    main.lua

    Main loader for FenceDistanceHotfix mod.
    Loads all dependencies in the correct order.

    ============================================================
    IMPORTANT: This file is a LOADER ONLY.
    ============================================================
    - It loads dependencies via source() in the correct order
    - All mod logic belongs in scripts/RmFenceDistanceHotfix.lua
    - Do NOT add module definitions (FenceDistanceHotfix = {}) here
    - Do NOT add business logic or game hooks here
    ============================================================

    Author: Ritter
]]

local modDirectory = g_currentModDirectory

-- =============================================================================
-- INFRASTRUCTURE
-- =============================================================================

source(modDirectory .. "scripts/rmlib/RmLogging.lua")
local Log = RmLogging.getLogger("FenceDistanceHotfix")

source(modDirectory .. "scripts/rmlib/RmVersion.lua")
local Ver = RmVersion.forMod(g_currentModName, Log)
Log:info("Build: %s", Ver:describe())
-- DEBUG unless this is a released stable version (>= 1.0.0.0 with no -dev suffix), so a
-- new mod at 0.0.x.x logs verbosely without anyone remembering to switch it on. Version
-- tiers, NOT the build helper's --release-type flag.
Ver:applyBuildLogLevel()
-- Log:setLevel(RmLogging.LOG_LEVEL.DEBUG) -- Manual override of log level


-- =============================================================================
-- CORE
-- =============================================================================

source(modDirectory .. "scripts/RmFenceDistanceHotfix.lua")

-- =============================================================================
-- TESTING (conditional - tests are excluded from release builds)
-- =============================================================================

local testRunnerPath = modDirectory .. "scripts/tests/RmTestRunner.lua"
if fileExists(testRunnerPath) then
    source(testRunnerPath)
end
