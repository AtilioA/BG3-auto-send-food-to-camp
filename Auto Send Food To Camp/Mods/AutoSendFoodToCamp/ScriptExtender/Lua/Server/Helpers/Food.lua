Food = {}

function IsFood(item)
  return Osi.ItemGetSupplyValue(item) > 0
end

function IsBeverage(item)
  return IsFood(item) and Osi.IsConsumable(item) == 1
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
