local ItemDuplicates = {}

ItemDuplicates.duplicates_to_look_for = {}
ItemDuplicates.duplicates_to_look_for["Lion Medallion"] = true
ItemDuplicates.duplicates_to_look_for["Unicorn Medallion"] = true
ItemDuplicates.duplicates_to_look_for["Maiden Medallion"] = true

function ItemDuplicates.Check(item_name)
    if ItemDuplicates.duplicates_to_look_for[item_name] == nil then
        log.debug("name is not in dupes to look for, return")
        return false
    end

    local names_in_inventory = Inventory.GetItemNames()
    local names_in_itembox = ItemBox.GetItemNames()

    for k, v in pairs(names_in_inventory) do
        if v == item_name then 
            return true 
        else
            log.debug(v .. " does not match " .. item_name)
        end
    end

    for k, v in pairs(names_in_itembox) do
        if v == item_name then 
            return true 
        else
            log.debug(v .. " does not match " .. item_name)
        end
    end

    log.debug("no match, returning false")
    return false
end

return ItemDuplicates
