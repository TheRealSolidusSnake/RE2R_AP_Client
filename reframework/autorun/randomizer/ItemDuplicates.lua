local ItemDuplicates = {}
ItemDuplicates.isInit = false
ItemDuplicates.duplicates_to_look_for = {}
ItemDuplicates.duplicates_to_look_for["Lion Medallion"] = true
ItemDuplicates.duplicates_to_look_for["Unicorn Medallion"] = true
ItemDuplicates.duplicates_to_look_for["Maiden Medallion"] = true

function ItemDuplicates.Init()
    if not ItemDuplicates.isInit then
        ItemDuplicates.isInit = true

        ItemDuplicates.DedupeAll()
    end
end

function ItemDuplicates.Check(item_name)
    if ItemDuplicates.duplicates_to_look_for[item_name] == nil then
        return false
    end

    local names_in_inventory = Inventory.GetItemNames()
    local names_in_itembox = ItemBox.GetItemNames()

    for k, v in pairs(names_in_inventory) do
        if v == item_name then 
            return true 
        end
    end

    for k, v in pairs(names_in_itembox) do
        if v == item_name then 
            return true 
        end
    end

    return false
end

function ItemDuplicates.DedupeAll()
    for k, v in pairs(ItemDuplicates.duplicates_to_look_for) do
        ItemDuplicates.Dedupe(k)
    end
end

function ItemDuplicates.Dedupe(item_name)
    if ItemDuplicates.duplicates_to_look_for[item_name] == nil then
        return false
    end

    -- prefer the copy of the item that's in the inventory, if present
    local found = Inventory.DedupeItem(item_name, false)
    ItemBox.DedupeItem(item_name, found)
end

return ItemDuplicates
