local Enemy = {}

Enemy.isInit = false -- keeps track of whether init things like hook need to run
Enemy.debug = false -- show enemy JSON when the game fires the "applyDead" method on the enemy

function Enemy.Init()
    if not Enemy.isInit then
        Enemy.isInit = true

        Enemy.SetupEnemyDeadHook()
    end
end

function Enemy.SetupEnemyDeadHook()
    local hpType = sdk.find_type_definition(sdk.game_namespace("EnemyController"))
    local dead_method = hpType:get_method("applyDead")

    sdk.hook(dead_method, function(args)
        local compEnemy = sdk.to_managed_object(args[2])
        local goEnemy = sdk.to_managed_object(compEnemy:call("get_GameObject"))
        local occComp = compEnemy:get_field("<OwnerContextController>k__BackingField")
        local ownerContext = compEnemy:get_field("<OwnerContext>k__BackingField")
        local initialKind = nil
        local montageId = nil

        if occComp ~= nil then
            initialKind = occComp:get_field("InitialKind")
        end

        if ownerContext ~= nil then
            montageId = ownerContext:call("get_MontageID")
        end

        local item_name = goEnemy:call("get_Name()")
        local item_folder = goEnemy:call("get_Folder()")
        local item_folder_path = nil

        if item_folder then
            item_folder_path = item_folder:call("get_Path()")
        end

        local item_parent_name = tostring(compEnemy:call("get_AssignLocationID")) .. "-" .. 
                                tostring(compEnemy:call("get_AssignMapID")) .. "-" .. 
                                tostring(compEnemy:call("get_AssignAreaID")) .. "-" ..
                                tostring(initialKind) .. "-" ..
                                tostring(montageId)
        if Enemy.debug then
            log.debug("---- DEAD ENEMY ----")
            log.debug("{\n\t\"name\": \"\",\n\t\"region\": \"\",\n\t\"original_item\": \"\",")
            log.debug("\t\"item_object\": \"" .. item_name .. "\",")
            log.debug("\t\"parent_object\": \"" .. item_parent_name .. "\",")
            log.debug("\t\"folder_path\": \"" .. item_folder_path .. "\"\n},")
            log.debug("") -- intentional empty line
            log.debug("---------------------")
        end

        local location_to_check = {}
        location_to_check['item_object'] = item_name
        location_to_check['parent_object'] = item_parent_name
        location_to_check['folder_path'] = item_folder_path

        -- nothing to do with AP if not connected
        if not Archipelago.IsConnected() then
            log.debug("Archipelago is not connected.")

            if Archipelago.hasConnectedPrior then
                GUI.AddText("Archipelago is not connected.")
            end

            return
        end

        local isLocationRandomized = Archipelago.IsLocationRandomized(location_to_check)

        if Archipelago.IsItemLocation(location_to_check) then
            local locationSentSuccess = Archipelago.SendLocationCheck(location_to_check, false)
            
            Archipelago.waitingForInvincibilityOff = true

            if locationSentSuccess == nil then -- both true and false responses are valid for removing the location, nil is not
                GUI.AddText("Location did not send because of a connection issue. Please verify that your AP room is up and try again.")
                
                -- TODO: Add the failed enemy location to Storage so it tries to send it again on reconnect.

                return
            end
        end
    end)
end

return Enemy
