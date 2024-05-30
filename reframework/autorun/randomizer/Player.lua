local Player = {}
Player.waitingForKill = false

function Player.GetGameObject()
    return player.gameobj
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

function Player.Kill()
    if Scene.isInPause() or Scene.isUsingItemBox() or not Scene.isInGame() then
        Player.waitingForKill = true

        return
    end

    Player.waitingForKill = false
    Scene.goToGameOver()
end

return Player
