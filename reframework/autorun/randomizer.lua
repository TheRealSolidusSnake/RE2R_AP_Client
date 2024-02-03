local game_name = reframework:get_game_name()
if game_name ~= "re2" then
    re.msg("This script is only for RE2")
    return
end


-- START globals
APGameName = "Resident Evil 2 Remake"

Manifest = require("randomizer/Manifest")
Lookups = require("randomizer/Lookups")

Archipelago = require("randomizer/Archipelago")
GUI = require("randomizer/GUI")
Helpers = require("randomizer/Helpers")
Inventory = require("randomizer/Inventory")
ItemBox = require("randomizer/ItemBox")
Items = require("randomizer/Items")
Player = require("randomizer/Player")
Scene = require("randomizer/Scene")
Storage = require("randomizer/Storage")
Typewriters = require("randomizer/Typewriters")
-- END globals


-- For debugging / trying out functionality:
-- Player.GetInventorySlots()
-- ItemBox.GetItems()

-- Door gimmicks (like Door_2_1_003_gimmick) have a GimmickDoor comp
--   that has references to "MyRooms" and "MyLocations", and something about "IsPairComplete"


re.on_pre_application_entry("UpdateBehavior", function()
    if not Scene:isInGame() then
        DisableInGameClient("Start a new game or load a file before connecting to AP.");
    else
        EnableInGameClient();
    end

    if Scene:isInGame() then 
        Archipelago.Init()
        Items.Init()

        if Archipelago.waitingForSync then
            Archipelago.waitingForSync = false
            APSync()
        end
    elseif Scene:isGameOver() and not Archipelago.waitingForSync then
        Archipelago.waitingForSync = true
    end
end)

re.on_frame(function ()
    -- ... one day OpieOP
    -- if Scene:isTitleScreen() then
    --     GUI.ShowRandomizerLogo()
    -- end

    if Scene:isInGame() then 
        GUI.CheckForAndDisplayMessages()
        
        -- only show the typewriter window when the user presses the reframework hotkey
        if reframework:is_drawing_ui() then
            Typewriters.DisplayWarpMenu()
        end
    end
end)

re.on_draw_ui(function () -- this is only called when Script Generated UI is visible
    -- nothing, but could add some debug stuff here one day
end)
