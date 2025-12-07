local Scene = {}

Scene.sceneObject = nil
Scene.mainFlowManager = nil
Scene.interactManager = nil
Scene.saveDataManager = nil

function Scene.getSceneObject()
    if Scene.sceneObject ~= nil then
        return Scene.sceneObject
    end

    Scene.sceneObject = sdk.call_native_func(sdk.get_native_singleton("via.SceneManager"), sdk.find_type_definition("via.SceneManager"), "get_CurrentScene()")

    return Scene.sceneObject
end

function Scene.getGameMaster()
    return Scene.getMasterObject("30_GameMaster")
end

function Scene.getGimmickMaster()
    return Scene.getMasterObject("70_GimmickMaster")
end

function Scene.getMasterObject(objectName)
    local masters = Scene.getSceneObject():findGameObjectsWithTag("Masters")
    local foundMaster = nil

    for k, master in pairs(masters) do
        if master:get_Name() == objectName then
            foundMaster = master

            break
        end
    end

    return foundMaster
end

function Scene.getMainFlowManager()
    if Scene.mainFlowManager ~= nil then
        return Scene.mainFlowManager
    end

    local gameMaster = Scene.getGameMaster()

    Scene.mainFlowManager = gameMaster:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gamemastering.MainFlowManager")))

    return Scene.mainFlowManager
end

function Scene.getInteractManager()
    if Scene.interactManager ~= nil then
        return Scene.interactManager
    end

    local gimmickMaster = Scene.getGimmickMaster()

    Scene.interactManager = gimmickMaster:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gimmick.action.InteractManager")))

    return Scene.interactManager
end

function Scene.getSaveDataManager()
    if Scene.saveDataManager ~= nil then
        return Scene.saveDataManager
    end

    local gameMaster = Scene.getGameMaster()

    Scene.saveDataManager = gameMaster:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("gamemastering.SaveDataManager")))

    return Scene.saveDataManager
end

function Scene.getSurvivorType()
    local gameMaster = Scene.getGameMaster()
    local survivorManager = gameMaster:call("getComponent(System.Type)", sdk.typeof(sdk.game_namespace("SurvivorManager")))
    local survivors = survivorManager:get_field("ExistSurvivorInfoList")

    for _, survivor in pairs(survivors:get_field("mItems")) do
        if survivor then
            local isActive = survivor:get_field("<IsActivePlayer>k__BackingField")

            if isActive then
                return survivor:get_field("<SurvivorType>k__BackingField")
            end
        end
    end

    return -1
end

function Scene.getScenarioType()
    local mainFlowManager = Scene.getMainFlowManager();
    
    if mainFlowManager ~= nil then
        local scenarioTypeSetting = mainFlowManager:call("get_CurrentScenarioType")

        if scenarioTypeSetting ~= nil then
            return scenarioTypeSetting
        end

        return -1
    end

    return -1 
end

function Scene.getGUIItemBox()
    if Scene.guiItemBox ~= nil then
        return Scene.guiItemBox
    end

    return Scene.getSceneObject():findGameObject("GUI_ItemBox")
end

function Scene.isTitleScreen()
    return Scene.getMainFlowManager():get_IsInTitle()
end

function Scene.isInGame()
    return Scene.getMainFlowManager():get_IsInGame()
end

function Scene.isInPause()
    return Scene.getMainFlowManager():get_IsInPause()
end

function Scene.isGameOver()
    return Scene.getMainFlowManager():get_IsInGameOver()
end

function Scene.goToGameOver()
    return Scene.getMainFlowManager():call("goGameOver", nil)
end

function Scene.isUsingItemBox()
    return Scene.getGUIItemBox():get_DrawSelf() -- is the ItemBox GUI "drawn"?
end

function Scene.isCharacterLeon()
    return Scene.getSurvivorType() == 0
end

function Scene.isCharacterClaire()
    return Scene.getSurvivorType() == 1
end

function Scene.isCharacterAda()
    return Scene.getSurvivorType() == 2
end

function Scene.isCharacterSherry()
    return Scene.getSurvivorType() == 3
end

function Scene.isScenarioLeonA()
    return Scene.getScenarioType() == 0
end

function Scene.isScenarioLeonB()
    return Scene.getScenarioType() == 2
end

function Scene.isScenarioClaireA()
    return Scene.getScenarioType() == 1
end

function Scene.isScenarioClaireB()
    return Scene.getScenarioType() == 3
end

function Scene.getCurrentLocation()
    return Scene.getMainFlowManager():get_LoadLocation()
end

function Scene.getCurrentArea()
    return Scene.getMainFlowManager():get_LoadArea()
end

function Scene.getGameGUID()
    return Scene.getMainFlowManager():get_GameGUID()
end

function Scene.getSaveGUID()
    return Scene.getMainFlowManager():get_SaveGUID()
end

return Scene
