local Player = {}
Player.waitingForKill = false

function Player.GetGameObject()
    return player.gameobj
end

function Player.GetHitPointController()
    return Helpers.component(Player.GetGameObject(), "HitPointController")
end

function Player.GetSurvivorConditionComponent()
    return Helpers.component(Player.GetGameObject(), "survivor.SurvivorCondition")
end

function Player.GetCurrentPosition()
    return Player.GetGameObject():get_Transform():get_Position()
end

function Player.WarpToPosition(vectorNew)
    local playerManager = sdk.get_managed_singleton(sdk.game_namespace("PlayerManager"))

    playerManager:setCurrentPosition(vectorNew)
end

function Player.LookAt(transform)
    Player.GetGameObject():get_Transform():lookAt(transform)
end

function Player.Poison()
    local sc = Player.GetSurvivorConditionComponent()

    sc:set_field("_IsPoison", true)
end

function Player.Damage(can_kill)
    local hpc = Player.GetHitPointController()
    local currentHealth = tonumber(hpc:get_field("<CurrentHitPoint>k__BackingField"))
    
    currentHealth = currentHealth - 400 -- 400 between Fine/Caution/Danger

    if currentHealth <= 0 then
        currentHealth = 1 -- don't drop health below 1
    end

    if can_kill == true and currentHealth == 1 then
        Player.Kill()      
    else
        hpc:set_field("<CurrentHitPoint>k__BackingField", currentHealth)
    end
end

function Player.Kill()
    if Scene.isInPause() or Scene.isUsingItemBox() or not Scene.isInGame() then
        Player.waitingForKill = true

        return
    end

    Player.waitingForKill = false
    Scene.goToGameOver()
end

return Player
