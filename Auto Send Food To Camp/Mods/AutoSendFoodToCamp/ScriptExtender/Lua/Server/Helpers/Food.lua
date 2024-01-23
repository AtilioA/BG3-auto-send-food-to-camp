Food = {}

function IsFood(object)
  if IsItem(object) then
    return Osi.ItemGetSupplyValue(object) > 0
  end
end

function IsBeverage(object)
  return IsFood(object) and Osi.IsConsumable(object) == 1
end

--- Gets all food items in a character's inventory.
---@param character any character to check.
---@param shallow boolean If true, recursively checks inside bags and containers.
---@return table | nil - table of food items in the character's inventory, or nil if none found.
function GetFoodInInventory(character, shallow)
  local inventory = GetInventory(character, false, shallow)
  local matchedItems = {}

  for _, item in ipairs(inventory) do
    local itemObject = item.TemplateName .. item.Guid
    if IsFood(itemObject) then
      table.insert(matchedItems, itemObject)
    end
  end

  if #matchedItems > 0 then
    return matchedItems
  else
    return nil
  end
end

return Food
