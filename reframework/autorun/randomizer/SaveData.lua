local SaveData = {}

-- Don't have a use for this yet, but seemed handy to have, so throwing this here for now.

function SaveData.RequestAutoSave()
    local sdm = Scene.getSaveDataManager()

    sdm:call("requestSaveGameDataAuto")
end

function SaveData.RequestSaveToSlot(slot_id)
    -- slot ids start counting at 1 on the load screen, not counting auto-saves
    -- SaveMode 1 is "SCENARIO"
    local sdm = Scene.getSaveDataManager()

    sdm:call("requestSaveGameData(" .. sdk.game_namespace("gamemastering.SaveDataManager.SaveMode") .. ", System.Int32)", 1, slot_id)
end

return SaveData
