local Archipelago = {}
Archipelago.hasConnectedPrior = false -- keeps track of whether the player has connected at all so players don't have to remove AP mod to play vanilla
Archipelago.isInit = false -- keeps track of whether init things like handlers need to run
Archipelago.waitingForSync = false -- randomizer calls APSync when "waiting for sync"; i.e., when you die

function Archipelago.Init()
    if not Archipelago.isInit then
        Archipelago.isInit = true
    end
end

function Archipelago.GetPlayer()
    local player = {}

    player["slot"] = APGetSlot()
    player["seed"] = APGetSeed()
    player["number"] = APGetPlayerNumber()
    player["alias"] = APGetPlayerAlias(player.number)

    return player
end

-- server sends slot data when slot is connected
function APSlotConnectedHandler(slot_data)
    Archipelago.hasConnectedPrior = true
    GUI.AddText('Connected.')
    Storage.Load()
    
    return Archipelago.SlotDataHandler(slot_data)
end

function APSlotDisconnectedHandler()
    GUI.AddText('Disconnected.')
end

function Archipelago.SlotDataHandler(slot_data)
    Lookups.load(slot_data.character, slot_data.scenario)
    
    for t, typewriter_name in pairs(slot_data.unlocked_typewriters) do
        Typewriters.AddUnlockedText(typewriter_name, "", true) -- true for "no_save_warning"
        Typewriters.Unlock(typewriter_name, "")
    end
end

-- sent by server when items are received
function APItemsReceivedHandler(items_received)
    return Archipelago.ItemsReceivedHandler(items_received)
end

function Archipelago.ItemsReceivedHandler(items_received)
    for k, row in pairs(items_received) do
        -- if the index of the incoming item is greater than the index of our last item at save, accept it
        if not Archipelago.lastSavedItemIndex or row["index"] > Archipelago.lastSavedItemIndex then
            local item_data = Archipelago._GetItemFromItemsData({ id = row["item"] })
            local location_data = nil
            local is_randomized = 1

            if row["location"] > 0 then
                location_data = Archipelago._GetLocationFromLocationData({ id = row["location"] })

                if location_data and location_data['raw_data']['randomized'] ~= nil then
                    is_randomized = location_data['raw_data']['randomized']
                end
            end

            if item_data["name"] then
                Archipelago.ReceiveItem(item_data["name"], row["player"], is_randomized)
            end

            -- if the index is also greater than the index of our last received index, update last received
            if not Archipelago.lastReceivedItemIndex or row["index"] > Archipelago.lastReceivedItemIndex then
                Archipelago.lastReceivedItemIndex = row["index"]
            end
        end
    end

    Storage.Update()
end

-- sent by server when locations are checked (collect, etc.?)
function APLocationsCheckedHandler(locations_checked)
    return Archipelago.LocationsCheckedHandler(locations_checked)
end

function Archipelago.LocationsCheckedHandler(locations_checked)
    -- if we received locations that were collected out, mark them sent so we don't get anything from it
    for location_id in locations_checked do
        local location_name = APGetLocationName(tonumber(location_id))

        for k, loc in pairs(Lookups.locations) do
            if loc['name'] == location_name then
                loc['sent'] = true

                break
            end
        end
    end
end

-- called when server is sending JSON data of some sort?
function APPrintJSONHandler(json_rows)
    return Archipelago.PrintJSONHandler(json_rows)
end

function Archipelago.PrintJSONHandler(json_rows)
    local player_sender, item, player_receiver, location = nil

    for k, row in pairs(json_rows) do
        -- if it's a player id and no sender is set, it's the sender
        if row["type"] == "player_id" and not player_sender then
            player_sender = APGetPlayerAlias(tonumber(row["text"]))

        -- if it's a player id and the sender is set, it's the receiver
        elseif row["type"] == "player_id" and player_sender then
            player_receiver = APGetPlayerAlias(tonumber(row["text"]))

        elseif row["type"] == "item_id" then
            item = APGetItemName(tonumber(row["text"]))
        elseif row["type"] == "location_id" then
            location = APGetLocationName(tonumber(row["text"]))
        end
    end

    if player_sender and item and player_receiver and location then
        if not Archipelago.lastSavedItemIndex or row["index"] > Archipelago.lastSavedItemIndex then
            if player_receiver then
                GUI.AddSentItemText(player_sender, item, player_receiver, location)
            else
                GUI.AddSentItemSelfText(player_sender, item, location)
            end
        end
    end
end

-- called when we send a "Bounce" packet for sending to another game, for things like DeathLink
function APBouncedHandler(json_rows)
    return Archipelago.BouncedHandler(json_rows)
end

-- leaving debug here for whenever deathlink gets added
function Archipelago.BouncedHandler(json_rows) 
    log.debug("bounced: ")

    for k, v in pairs(json_rows) do
        log.debug("key " .. tostring(k) .. " is: " .. tostring(v))
    end
end

function Archipelago.IsItemLocation(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data)

    if not location then
        return false
    end

    return true
end

function Archipelago.IsLocationRandomized(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data)

    if not location then
        return false
    end
    
    if location['raw_data']['randomized'] == 0 and not location['raw_data']['force_item'] then
        return false
    end

    return true
end

function Archipelago.CheckForVictoryLocation(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data)

    if location ~= nil and location["raw_data"]["victory"] then
        Archipelago.SendVictory()

        return true
    end
    
    return false
end

function Archipelago.SendLocationCheck(location_data)
    local location = Archipelago._GetLocationFromLocationData(location_data)
    local location_ids = {}

    if not location then
        return false
    end

    location_ids[1] = location["id"]

    local result = APLocationChecks(location_ids)

    for k, loc in pairs(Lookups.locations) do
        if loc['item_object'] == location_data['item_object'] and loc['parent_object'] == location_data['parent_object'] and loc['folder_path'] == location_data['folder_path'] then
            loc['sent'] = true
            
            break
        end
    end

    return true
end

function Archipelago.ReceiveItem(item_name, sender, is_randomized)
    local item_ref = nil
    local item_number = nil
    local item_ammo = nil

    for k, item in pairs(Lookups.items) do
        if item.name == item_name then
            item_ref = item
            item_number = item.decimal
            
            -- if it's a weapon, look up its ammo as well and set to item_ammo
            if item.type == "Weapon" and item.ammo ~= nil then
                for k2, item2 in pairs(Lookups.items) do
                    if item2.name == item.ammo then
                        item_ammo = item2.decimal

                        break
                    end
                end
            end

            break
        end
    end

    if item_ref and item_number then
        local itemId, weaponId, weaponParts, bulletId, count = nil

        if item_ref.type == "Weapon" or item_ref.type == "Subweapon" then
            itemId = -1
            weaponId = item_number

            if item_ref.type == "Weapon" then
                bulletId = item_ammo
            end
        else
            itemId = item_number
            weaponId = -1
        end

        count = item_ref.count

        if count == nil then
            count = 1
        end

        local player_self = Archipelago.GetPlayer()
        local sentToBox = false

        if is_randomized > 0 then
            if item_name == "Hip Pouch" then
                Inventory.IncreaseMaxSlots(2) -- simulate receiving the hip pouch by increasing player inv slots by 2
                GUI.AddReceivedItemText(item_name, tostring(APGetPlayerAlias(sender)), tostring(player_self.alias), sentToBox)

                return
            end

            -- sending weapons to inventory causes them to not work until boxed + retrieved, so send weapons to box always for now
            if item_ref.type ~= "Weapon" and item_ref.type ~= "Subweapon" and Inventory.HasSpaceForItem() then
                local addedToInv = Inventory.AddItem(tonumber(itemId), tonumber(weaponId), weaponParts, bulletId, tonumber(count))

                -- if adding to inventory failed, add it to the box as a backup
                if addedToInv then
                    sentToBox = false
                else
                    ItemBox.AddItem(tonumber(itemId), tonumber(weaponId), weaponParts, bulletId, tonumber(count))
                    sentToBox = true    
                end
            -- if this item is a weapon/subweapon or the player doesn't have room in inventory, send to the box
            else
                ItemBox.AddItem(tonumber(itemId), tonumber(weaponId), weaponParts, bulletId, tonumber(count))
                sentToBox = true
            end
        end

        GUI.AddReceivedItemText(item_name, tostring(APGetPlayerAlias(sender)), tostring(player_self.alias), sentToBox)
    end
end

function Archipelago.SendVictory()
    APGameComplete()
end

function Archipelago._GetItemFromItemsData(item_data)
    local translated_item = {}
    
    translated_item['name'] = APGetItemName(item_data['id'])

    if not translated_item['name'] then
        return nil
    end

    translated_item['id'] = item_data['id']

    -- now that we have name and id, return them
    return translated_item
end

function Archipelago._GetLocationFromLocationData(location_data)
    local translated_location = {}
    local scenario_suffix = " (" .. string.upper(string.sub(Lookups.character, 1, 1) .. Lookups.scenario) .. ")"

    if location_data['id'] and not location_data['name'] then
        location_data['name'] = APGetLocationName(location_data['id'])
    end

    for k, loc in pairs(Lookups.locations) do
        location_name_with_region = loc['region'] .. scenario_suffix .. " - " .. loc['name']

        if location_data['name'] == location_name_with_region then
            translated_location['name'] = location_name_with_region
            translated_location['raw_data'] = loc

            break
        end

        if not loc['sent'] then
            if loc['item_object'] == location_data['item_object'] and loc['parent_object'] == location_data['parent_object'] and loc['folder_path'] == location_data['folder_path'] then
                translated_location['name'] = location_name_with_region
                translated_location['raw_data'] = loc

                break
            end
        end
    end
    
    if not translated_location['name'] then
        return nil
    end

    translated_location['id'] = APGetLocationId(translated_location['name'])

    -- now that we have name and id, return them
    return translated_location
end

return Archipelago
