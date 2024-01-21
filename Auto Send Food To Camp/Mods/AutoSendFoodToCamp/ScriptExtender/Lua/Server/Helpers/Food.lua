Food = {}

function IsFood(object)
  if IsItem(object) then
    return Osi.ItemGetSupplyValue(object) > 0
  end
end

function IsBeverage(object)
  return IsFood(object) and Osi.IsConsumable(object) == 1
end

function GetFoodInInventory(character)
  local inventory = GetInventory(character, false, true)
  local matchedItems = {}

  for _, item in ipairs(inventory) do
    local itemObject = item.TemplateName .. item.Guid
    if IsFood(itemObject) then
      Utils.DebugPrint(2, "Found food in inventory: " .. item.Name)
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
